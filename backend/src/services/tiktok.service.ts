import axios from 'axios';
import { pool, DbRow } from '../config/db';

export interface TikTokStats {
  views: number;
  likes: number;
  shares: number;
  comments: number;
  title: string;
  author: string;
}

const RAPIDAPI_KEY  = process.env.RAPIDAPI_KEY ?? '';
const RAPIDAPI_HOST = process.env.RAPIDAPI_TIKTOK_HOST ?? 'tiktok-api23.p.rapidapi.com';

/**
 * Extract numeric video ID from a TikTok URL.
 * Handles: https://www.tiktok.com/@user/video/7306132438047116586
 */
function extractVideoId(url: string): string {
  const match = url.match(/\/video\/(\d+)/);
  if (!match?.[1]) {
    throw new Error('Cannot extract video ID from URL. Make sure it is a full TikTok video URL (e.g. https://www.tiktok.com/@user/video/123456)');
  }
  return match[1];
}

/**
 * Fetch TikTok video stats via RapidAPI tiktok-api23.
 *
 * Endpoint: GET /api/post/detail?videoId={id}
 * Response: itemInfo.itemStruct.stats
 *   playCount  → views
 *   diggCount  → likes
 *   shareCount → shares
 */
export async function fetchTikTokStats(videoUrl: string): Promise<TikTokStats> {
  const cleanUrl = videoUrl.split('?')[0].trim();
  const videoId  = extractVideoId(cleanUrl);

  const result: TikTokStats = {
    views: 0, likes: 0, shares: 0, comments: 0, title: '', author: '',
  };

  const res = await axios.get(`https://${RAPIDAPI_HOST}/api/post/detail`, {
    params: { videoId },
    headers: {
      'x-rapidapi-key':  RAPIDAPI_KEY,
      'x-rapidapi-host': RAPIDAPI_HOST,
      'Content-Type':    'application/json',
    },
    timeout: 12000,
  });

  const data = res.data;

  const itemStruct =
    data?.itemInfo?.itemStruct ??
    data?.data?.itemInfo?.itemStruct ??
    data?.data ??
    data?.item ??
    null;

  if (!itemStruct) {
    throw new Error('Unexpected response from TikTok API');
  }

  const stats   = itemStruct.stats   ?? itemStruct.statsV2 ?? {};
  const statics = itemStruct.statistics ?? {};

  result.views    = Number(stats.playCount    ?? stats.play_count    ?? statics.play_count    ?? 0);
  result.likes    = Number(stats.diggCount    ?? stats.digg_count    ?? statics.digg_count    ?? 0);
  result.shares   = Number(stats.shareCount   ?? stats.share_count   ?? statics.share_count   ?? 0);
  result.comments = Number(stats.commentCount ?? stats.comment_count ?? statics.comment_count ?? 0);
  result.title    = (itemStruct.desc ?? itemStruct.title ?? itemStruct.contents?.[0]?.desc ?? '').slice(0, 200);
  result.author   = itemStruct.author?.nickname ?? itemStruct.author?.unique_id ?? itemStruct.author?.uniqueId ?? '';

  return result;
}

/**
 * Upsert today's aggregated stats snapshot into video_daily_stats.
 * Called after any video submit or refresh so the daily row always
 * reflects the latest totals for that influencer on that calendar day.
 */
async function upsertDailyStats(influencerUserId: number): Promise<void> {
  // Sum all submitted_videos for this influencer as of today
  const [rows] = await pool.query<DbRow[]>(
    `SELECT
       COALESCE(SUM(views_count),    0) AS v,
       COALESCE(SUM(likes_count),    0) AS l,
       COALESCE(SUM(shares_count),   0) AS s,
       -- comments_count not stored per-video yet, default 0
       0                                AS c
     FROM submitted_videos
    WHERE influencer_user_id = ?`,
    [influencerUserId]
  );
  const { v, l, s, c } = rows[0] as { v: number; l: number; s: number; c: number };

  await pool.query(
    `INSERT INTO video_daily_stats
       (influencer_user_id, stat_date, views_count, likes_count, shares_count, comments_count)
     VALUES (?, CURDATE(), ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       views_count    = VALUES(views_count),
       likes_count    = VALUES(likes_count),
       shares_count   = VALUES(shares_count),
       comments_count = VALUES(comments_count),
       updated_at     = NOW()`,
    [influencerUserId, v, l, s, c]
  );
}

export async function refreshAllVideosForUser(userId: number): Promise<void> {
  // Fetch all submitted videos for this user
  const [videos] = await pool.query<DbRow[]>(
    `SELECT id, offer_id, influencer_user_id, video_url
       FROM submitted_videos
      WHERE influencer_user_id = ?`,
    [userId]
  );

  if (!videos.length) return;

  for (const row of videos) {
    const v = row as { id: number; offer_id: number; influencer_user_id: number; video_url: string };
    try {
      const stats = await fetchTikTokStats(v.video_url);

      // Update this video's stats
      await pool.query(
        `UPDATE submitted_videos
            SET views_count = ?, likes_count = ?, shares_count = ?, fetched_at = NOW()
          WHERE id = ?`,
        [stats.views, stats.likes, stats.shares, v.id]
      );

      // Recalculate aggregated totals for this offer + user combo
      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0)  AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [v.offer_id, v.influencer_user_id]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      // Recalculate progress using same formula as video.controller.ts
      const [offerRows] = await pool.query<DbRow[]>(
        'SELECT target_views, target_likes FROM offers WHERE id = ?',
        [v.offer_id]
      );
      if (!offerRows.length) continue;
      const offer = offerRows[0] as { target_views: number; target_likes: number };

      const vPct = offer.target_views > 0 ? Math.min(agg.total_views / offer.target_views, 1) : 1;
      const lPct = offer.target_likes > 0 ? Math.min(agg.total_likes / offer.target_likes, 1) : 1;
      const noTarget = offer.target_views === 0 && offer.target_likes === 0;
      const progress = noTarget ? 100 : Math.round((vPct * 0.6 + lPct * 0.4) * 100);

      await pool.query(
        `UPDATE campaign_applicants
            SET views = ?, likes = ?, shares = ?, progress = ?
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [agg.total_views, agg.total_likes, agg.total_shares, progress, v.offer_id, v.influencer_user_id]
      );
    } catch {
      // Skip this video silently — don't let one failure block others
      continue;
    }
  }

  // After refreshing all videos, upsert today's daily snapshot
  try {
    await upsertDailyStats(userId);
  } catch {
    // Silent — daily stats are best-effort
  }
}

/**
 * Exported so video.controller.ts can call it after a submit/refresh
 * without going through the full refreshAllVideosForUser loop.
 */
export { upsertDailyStats };