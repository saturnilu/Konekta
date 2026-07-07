import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { pool, DbRow, DbResult } from '../config/db';
import { fetchTikTokStats, upsertDailyStats } from '../services/tiktok.service';
import { ok, created } from '../utils/response';
import { ApiError } from '../utils/apiError';

const submitSchema = z.object({
  video_url: z.string().url().max(500),
});

/**
 * Calculate progress percentage (0–100).
 * If both targets are 0 (no target set), progress = 100 (always met).
 * Formula: 60% views weight + 40% likes weight.
 */
function calcProgress(
  totalViews: number, totalLikes: number,
  targetViews: number, targetLikes: number
): number {
  const noTarget = targetViews === 0 && targetLikes === 0;
  if (noTarget) return 100;
  const vPct = targetViews > 0 ? Math.min(totalViews / targetViews, 1) : 1;
  const lPct = targetLikes > 0 ? Math.min(totalLikes / targetLikes, 1) : 1;
  return Math.round((vPct * 0.6 + lPct * 0.4) * 100);
}

export const videoController = {
  /**
   * POST /offers/:id/videos
   * Influencer submits a TikTok video link.
   * We fetch stats, store the video, then recalculate progress on the applicant row.
   */
  async submit(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers can submit videos');
      }

      const offerId = Number(req.params.id);
      if (!Number.isFinite(offerId)) throw new ApiError(400, 'Invalid offer id');

      const { video_url } = submitSchema.parse(req.body);

      // Verify influencer has an approved (or completed) application
      const [appRows] = await pool.query<DbRow[]>(
        `SELECT ca.id, ca.views, ca.likes, ca.shares
           FROM campaign_applicants ca
          WHERE ca.offer_id = ? AND ca.influencer_user_id = ? AND ca.status IN ('approved', 'completed')`,
        [offerId, req.user.id]
      );
      if (!appRows.length) {
        throw new ApiError(403, 'No approved application for this offer');
      }
      const app = appRows[0] as { id: number; views: number; likes: number; shares: number };

      // Fetch TikTok stats via RapidAPI — non-blocking: store video even if fetch fails
      let stats = { views: 0, likes: 0, shares: 0, title: '', author: '' };
      let statsFetched = true;
      try {
        stats = await fetchTikTokStats(video_url);
      } catch (e: any) {
        statsFetched = false;
        // Continue — video saved with 0 stats, can be refreshed later
      }

      // Store submitted video
      const [insertResult] = await pool.query<DbResult>(
        `INSERT INTO submitted_videos
           (offer_id, influencer_user_id, video_url, views_count, likes_count, shares_count, fetched_at)
         VALUES (?, ?, ?, ?, ?, ?, NOW())
         ON DUPLICATE KEY UPDATE
           views_count = VALUES(views_count),
           likes_count = VALUES(likes_count),
           shares_count = VALUES(shares_count),
           fetched_at = NOW()`,
        [offerId, req.user.id, video_url, stats.views, stats.likes, stats.shares]
      );

      // Aggregate all submitted videos for this applicant
      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0) AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, req.user.id]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      // Get offer targets
      const [offerRows] = await pool.query<DbRow[]>(
        'SELECT target_views, target_likes, target_shares FROM offers WHERE id = ?',
        [offerId]
      );
      const offer = offerRows[0] as { target_views: number; target_likes: number; target_shares: number };

      // Calculate progress (weighted: 60% views, 40% likes)
      const progress = calcProgress(
        Number(agg.total_views), Number(agg.total_likes),
        offer.target_views, offer.target_likes
      );

      // Update applicant row
      await pool.query(
        `UPDATE campaign_applicants
            SET views = ?, likes = ?, shares = ?, progress = ?
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [agg.total_views, agg.total_likes, agg.total_shares, progress, offerId, req.user.id]
      );

      // Upsert today's daily stats snapshot
      try { await upsertDailyStats(req.user!.id); } catch { /* silent */ }

      return created(res, {
        video_id: insertResult.insertId,
        video_url,
        stats: {
          views:  stats.views,
          likes:  stats.likes,
          shares: stats.shares,
          title:  stats.title,
          author: stats.author,
        },
        totals: {
          total_views:  Number(agg.total_views),
          total_likes:  Number(agg.total_likes),
          total_shares: Number(agg.total_shares),
        },
        progress,
      }, 'Video submitted');
    } catch (e) { next(e); }
  },

  /**
   * POST /offers/:id/videos/brand/:influencerId/recalculate
   * Brand triggers a re-aggregate of an influencer's stats from submitted_videos.
   */
  async recalculateForBrand(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands');
      }
      const offerId      = Number(req.params.id);
      const influencerId = Number(req.params.influencerId);

      const [own] = await pool.query<DbRow[]>(
        'SELECT brand_user_id, target_views, target_likes, target_shares FROM offers WHERE id = ?',
        [offerId]
      );
      if (!own.length) throw new ApiError(404, 'Offer not found');
      const offerRow = own[0] as { brand_user_id: number; target_views: number; target_likes: number; target_shares: number };
      if (offerRow.brand_user_id !== req.user.id) throw new ApiError(403, 'Not your offer');

      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0)  AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, influencerId]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      const totalViews  = Number(agg.total_views);
      const totalLikes  = Number(agg.total_likes);
      const totalShares = Number(agg.total_shares);

      const progress = calcProgress(totalViews, totalLikes, offerRow.target_views, offerRow.target_likes);

      await pool.query(
        `UPDATE campaign_applicants SET views = ?, likes = ?, shares = ?, progress = ?
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [totalViews, totalLikes, totalShares, progress, offerId, influencerId]
      );

      return ok(res, { totals: { views: totalViews, likes: totalLikes, shares: totalShares, progress } }, 'Recalculated');
    } catch (e) { next(e); }
  },

  /**
   * GET /offers/:id/videos/brand/:influencerId
   * Brand views a specific approved influencer's videos + progress.
   */
  async listForBrand(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands');
      }
      const offerId      = Number(req.params.id);
      const influencerId = Number(req.params.influencerId);

      // Verify brand owns the offer
      const [own] = await pool.query<DbRow[]>(
        'SELECT brand_user_id, target_views, target_likes, target_shares, reward_per_creator FROM offers WHERE id = ?',
        [offerId]
      );
      if (!own.length) throw new ApiError(404, 'Offer not found');
      const offerRow = own[0] as { brand_user_id: number; target_views: number; target_likes: number; target_shares: number; reward_per_creator: number };
      if (offerRow.brand_user_id !== req.user.id) throw new ApiError(403, 'Not your offer');

      // Get submitted videos
      const [videos] = await pool.query<DbRow[]>(
        `SELECT id, video_url, views_count, likes_count, shares_count, fetched_at, created_at
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?
          ORDER BY created_at DESC`,
        [offerId, influencerId]
      );

      // Get applicant info
      const [appRows] = await pool.query<DbRow[]>(
        `SELECT ca.views, ca.likes, ca.shares, ca.progress, ca.status,
                u.name, u.avatar_url, ip.username, ip.niche, ip.followers_count, ip.engagement_rate
           FROM campaign_applicants ca
           JOIN users u ON u.id = ca.influencer_user_id
           JOIN influencer_profiles ip ON ip.user_id = ca.influencer_user_id
          WHERE ca.offer_id = ? AND ca.influencer_user_id = ?`,
        [offerId, influencerId]
      );
      if (!appRows.length) throw new ApiError(404, 'Applicant not found');
      const app = appRows[0] as any;

      // Always re-aggregate from submitted_videos as the source of truth
      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0)  AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, influencerId]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      const totalViews  = Number(agg.total_views);
      const totalLikes  = Number(agg.total_likes);
      const totalShares = Number(agg.total_shares);

      // Recalculate progress from live aggregated data
      const progress = calcProgress(totalViews, totalLikes, offerRow.target_views, offerRow.target_likes);

      // Sync back to campaign_applicants if the stored values are stale
      const storedViews = Number(app.views ?? 0);
      const storedProgress = Number(app.progress ?? 0);
      if (storedViews !== totalViews || storedProgress !== progress) {
        await pool.query(
          `UPDATE campaign_applicants SET views = ?, likes = ?, shares = ?, progress = ?
            WHERE offer_id = ? AND influencer_user_id = ?`,
          [totalViews, totalLikes, totalShares, progress, offerId, influencerId]
        );
      }

      return ok(res, {
        influencer: {
          id: influencerId,
          name: app.name,
          avatar_url: app.avatar_url,
          username: app.username,
          niche: app.niche,
          followers_count: Number(app.followers_count ?? 0),
          engagement_rate: Number(app.engagement_rate ?? 0),
        },
        videos,
        totals: {
          views:    totalViews,
          likes:    totalLikes,
          shares:   totalShares,
          progress: progress,
        },
        targets: {
          views:  Number(offerRow.target_views),
          likes:  Number(offerRow.target_likes),
          shares: Number(offerRow.target_shares),
        },
        reward: Number(offerRow.reward_per_creator),
        applicant_status: app.status,
      });
    } catch (e) { next(e); }
  },

  /**
   * POST /offers/:id/videos/brand/:influencerId/pay
   * Brand marks influencer as paid (completes the collaboration).
   */
  async payInfluencer(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands');
      }
      const offerId      = Number(req.params.id);
      const influencerId = Number(req.params.influencerId);

      const [own] = await pool.query<DbRow[]>(
        'SELECT brand_user_id, reward_per_creator, title FROM offers WHERE id = ?',
        [offerId]
      );
      if (!own.length) throw new ApiError(404, 'Offer not found');
      const offerRow = own[0] as { brand_user_id: number; reward_per_creator: number; title: string };
      if (offerRow.brand_user_id !== req.user.id) throw new ApiError(403, 'Not your offer');

      // Mark applicant as completed
      await pool.query(
        `UPDATE campaign_applicants SET status = 'completed'
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, influencerId]
      );

      // If all approved/completed applicants are now paid, mark the offer as completed
      const [remaining] = await pool.query<DbRow[]>(
        `SELECT COUNT(*) AS cnt FROM campaign_applicants
          WHERE offer_id = ? AND status = 'approved'`,
        [offerId]
      );
      if ((remaining[0] as { cnt: number }).cnt === 0) {
        await pool.query(
          `UPDATE offers SET status = 'completed' WHERE id = ?`,
          [offerId]
        );
      }

      // Record earning for influencer
      await pool.query(
        `INSERT INTO earnings (influencer_user_id, offer_id, description, amount)
         VALUES (?, ?, ?, ?)`,
        [influencerId, offerId, `Payment for campaign: ${offerRow.title}`, offerRow.reward_per_creator]
      );

      // Notify influencer
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, icon)
         VALUES (?, 'payment', 'Payment Received', ?, 'payments')`,
        [influencerId, `You received payment for campaign: ${offerRow.title}`]
      );

      return ok(res, { paid: true }, 'Payment recorded');
    } catch (e) { next(e); }
  },

  /**
   * GET /offers/:id/videos
   * List submitted videos + totals for the current influencer.
   */
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers');
      }
      const offerId = Number(req.params.id);

      const [videos] = await pool.query<DbRow[]>(
        `SELECT id, video_url, views_count, likes_count, shares_count, fetched_at, created_at
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?
          ORDER BY created_at DESC`,
        [offerId, req.user.id]
      );

      // offer targets
      const [offerRows] = await pool.query<DbRow[]>(
        'SELECT target_views, target_likes, target_shares FROM offers WHERE id = ?',
        [offerId]
      );
      const offerTarget = (offerRows[0] ?? { target_views: 0, target_likes: 0, target_shares: 0 }) as {
        target_views: number; target_likes: number; target_shares: number;
      };

      // Always aggregate from submitted_videos as source of truth
      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0)  AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, req.user.id]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      const totalViews  = Number(agg.total_views);
      const totalLikes  = Number(agg.total_likes);
      const totalShares = Number(agg.total_shares);

      // Recalculate progress
      const progress = calcProgress(totalViews, totalLikes, offerTarget.target_views, offerTarget.target_likes);

      // Sync back to campaign_applicants if stale
      await pool.query(
        `UPDATE campaign_applicants SET views = ?, likes = ?, shares = ?, progress = ?
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [totalViews, totalLikes, totalShares, progress, offerId, req.user.id]
      );

      return ok(res, {
        videos,
        totals: {
          views:    totalViews,
          likes:    totalLikes,
          shares:   totalShares,
          progress: progress,
        },
        targets: {
          views:  Number(offerTarget.target_views),
          likes:  Number(offerTarget.target_likes),
          shares: Number(offerTarget.target_shares),
        },
      });
    } catch (e) { next(e); }
  },

  /**
   * POST /offers/:id/videos/:videoId/refresh
   * Re-fetch stats for a specific submitted video.
   */
  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers');
      }
      const offerId  = Number(req.params.id);
      const videoId  = Number(req.params.videoId);

      const [rows] = await pool.query<DbRow[]>(
        'SELECT video_url FROM submitted_videos WHERE id = ? AND offer_id = ? AND influencer_user_id = ?',
        [videoId, offerId, req.user.id]
      );
      if (!rows.length) throw new ApiError(404, 'Video not found');

      const videoUrl = (rows[0] as { video_url: string }).video_url;
      let stats;
      try {
        stats = await fetchTikTokStats(videoUrl);
      } catch (e: any) {
        throw new ApiError(422, e?.message ?? 'Failed to fetch TikTok stats');
      }

      await pool.query(
        `UPDATE submitted_videos
            SET views_count = ?, likes_count = ?, shares_count = ?, fetched_at = NOW()
          WHERE id = ?`,
        [stats.views, stats.likes, stats.shares, videoId]
      );

      // Recalculate totals + progress (reuse submit logic)
      const [aggRows] = await pool.query<DbRow[]>(
        `SELECT COALESCE(SUM(views_count), 0) AS total_views,
                COALESCE(SUM(likes_count), 0) AS total_likes,
                COALESCE(SUM(shares_count), 0) AS total_shares
           FROM submitted_videos
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [offerId, req.user.id]
      );
      const agg = aggRows[0] as { total_views: number; total_likes: number; total_shares: number };

      const [offerRows] = await pool.query<DbRow[]>(
        'SELECT target_views, target_likes FROM offers WHERE id = ?',
        [offerId]
      );
      const offer = offerRows[0] as { target_views: number; target_likes: number };
      const progress = calcProgress(
        Number(agg.total_views), Number(agg.total_likes),
        offer.target_views, offer.target_likes
      );

      await pool.query(
        `UPDATE campaign_applicants SET views = ?, likes = ?, shares = ?, progress = ?
          WHERE offer_id = ? AND influencer_user_id = ?`,
        [agg.total_views, agg.total_likes, agg.total_shares, progress, offerId, req.user.id]
      );

      // Upsert today's daily stats snapshot
      try { await upsertDailyStats(req.user!.id); } catch { /* silent */ }

      return ok(res, { stats, totals: agg, progress }, 'Stats refreshed');
    } catch (e) { next(e); }
  },
};