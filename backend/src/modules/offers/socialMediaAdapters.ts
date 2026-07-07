// ============================================================
// DESIGN PATTERN: ADAPTER (Structural)
// Tujuan: Menyamakan API berbagai platform sosial media (TikTok,
// Instagram, YouTube) yang punya endpoint, auth, dan response format
// berbeda-beda menjadi satu interface seragam (ISocialMediaAdapter).
// Lokasi pemakai:
//   - modules/social/socialMediaFacade.ts (FACADE Pattern wrapper)
//   - modules/analytics/dashboard.service.ts (laporan analitik)
// ============================================================

import { pool, DbRow } from '../../config/db';
import { ApiError } from '../../core/utils/apiError';

export interface SocialMediaMetrics {
  followers: number;
  likes: number;
  shares: number;
  views: number;
}

export interface PostContent {
  platformPostId?: string;
  url?: string;
  scheduledAt?: string;
}

// [ADAPTER PATTERN] — Target interface: kontrak seragam untuk semua adapter
export interface ISocialMediaAdapter {
  /** Get latest analytics metrics for a given post */
  getMetrics(postId: string): Promise<SocialMediaMetrics>;

  /** Publish a post to the platform, returning post metadata */
  publish(content: PostContent): Promise<PostContent>;

  /** Fetch raw platform data for a campaign report */
  fetchCampaignReport(offerId: number): Promise<PlatformReport>;
}

export interface PlatformReport {
  platform: string;
  totalViews: number;
  totalLikes: number;
  totalShares: number;
  posts: Array<{ postId: string; url: string; views: number; likes: number; shares: number }>;
}

// [ADAPTER PATTERN] — Concrete Adapter: TikTok Marketing API
// Adapt API TikTok (`open.tiktokapis.com/v2/post/`) ke ISocialMediaAdapter
export class TikTokAdapter implements ISocialMediaAdapter {
  private baseUrl = 'https://open.tiktokapis.com/v2/oauth/';
  private apiBase = 'https://open.tiktokapis.com/v2/post/';

  async getMetrics(postId: string): Promise<SocialMediaMetrics> {
    const res = await fetch(`${this.apiBase}post/public/list/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.TIKTOK_ACCESS_TOKEN}`,
      },
      body: JSON.stringify({
        query: {
          filter_by: ['POST_ID'],
          values: [postId],
        },
      }),
    });

    if (!res.ok) throw new ApiError(502, 'TikTok API error');

    const json = await res.json();
    const post = json?.data?.posts?.[0]?.properties;

    if (!post) return { followers: 0, likes: 0, shares: 0, views: 0 };

    return {
      followers: 0,
      likes: Number(post.like_count ?? 0),
      shares: Number(post.share_count ?? 0),
      views: Number(post.play_count ?? 0),
    };
  }

  async publish(content: PostContent): Promise<PostContent> {
    const res = await fetch(`${this.apiBase}first/post/video/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.TIKTOK_ACCESS_TOKEN}`,
      },
      body: JSON.stringify({
        post_info: {
          title: content.platformPostId ?? '',
          privacy_level: 'PUBLIC_TO_ALL',
        },
        source_info: {
          source: 'UPLOAD',
          video_url: content.url,
        },
      }),
    });

    if (!res.ok) throw new ApiError(502, 'TikTok publish failed');
    const json = await res.json();
    return { ...content, platformPostId: json?.data?.post_id };
  }

  async fetchCampaignReport(offerId: number): Promise<PlatformReport> {
    const [accounts] = await pool.query<DbRow[]>(
      `SELECT handle, followers_count FROM social_media_accounts
       WHERE influencer_user_id = (
         SELECT influencer_user_id FROM offers WHERE id = ?
       ) AND platform = 'tiktok'`,
      [offerId]
    );

    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, views, likes, shares
       FROM campaign_applicants
       WHERE offer_id = ?`,
      [offerId]
    );
    const posts = rows as Array<{ id: number; views: number; likes: number; shares: number }>;

    const platform = accounts[0] as { handle: string } | undefined;

    return {
      platform: platform?.handle ?? 'tiktok',
      totalViews: posts.reduce((s, p) => s + (p.views ?? 0), 0),
      totalLikes: posts.reduce((s, p) => s + (p.likes ?? 0), 0),
      totalShares: posts.reduce((s, p) => s + (p.shares ?? 0), 0),
      posts: posts.map((p) => ({
        postId: String(p.id),
        url: '',
        views: p.views ?? 0,
        likes: p.likes ?? 0,
        shares: p.shares ?? 0,
      })),
    };
  }
}

// [ADAPTER PATTERN] — Concrete Adapter: Instagram Graph API
// Adapt API Instagram (`graph.facebook.com/v18.0/`) ke ISocialMediaAdapter
export class InstagramAdapter implements ISocialMediaAdapter {
  private apiBase = 'https://graph.facebook.com/v18.0/';

  async getMetrics(postId: string): Promise<SocialMediaMetrics> {
    const res = await fetch(`${this.apiBase}${postId}`, {
      headers: {
        'Authorization': `Bearer ${process.env.INSTAGRAM_ACCESS_TOKEN}`,
      },
    });

    if (!res.ok) return { followers: 0, likes: 0, shares: 0, views: 0 };
    const json = await res.json();

    return {
      followers: 0,
      likes: Number(json?.insights?.data?.[0]?.values?.[0]?.engagement ?? 0),
      shares: Number(json?.shares?.count ?? 0),
      views: Number(json?.media_views ?? 0),
    };
  }

  async publish(content: PostContent): Promise<PostContent> {
    // Simplified IG publish
    return {
      platformPostId: content.platformPostId ?? `ig_${Date.now()}`,
      url: content.url,
    };
  }

  async fetchCampaignReport(offerId: number): Promise<PlatformReport> {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, views, likes, shares FROM campaign_applicants WHERE offer_id = ?`,
      [offerId]
    );
    const posts = rows as Array<{ id: number; views: number; likes: number; shares: number }>;

    return {
      platform: 'instagram',
      totalViews: posts.reduce((s, p) => s + (p.views ?? 0), 0),
      totalLikes: posts.reduce((s, p) => s + (p.likes ?? 0), 0),
      totalShares: posts.reduce((s, p) => s + (p.shares ?? 0), 0),
      posts: posts.map((p) => ({
        postId: String(p.id),
        url: '',
        views: p.views ?? 0,
        likes: p.likes ?? 0,
        shares: p.shares ?? 0,
      })),
    };
  }
}

// [ADAPTER PATTERN] — Concrete Adapter: YouTube Data API
// Adapt API YouTube (`youtube.googleapis.com/youtube/v3/`) ke ISocialMediaAdapter
export class YouTubeAdapter implements ISocialMediaAdapter {
  async getMetrics(postId: string): Promise<SocialMediaMetrics> {
    const res = await fetch(
      `https://www.googleapis.com/youtube/v3/videos?part=statistics&id=${postId}`,
      {
        headers: {
          'Authorization': `Bearer ${process.env.YOUTUBE_API_KEY}`,
        },
      }
    );

    if (!res.ok) return { followers: 0, likes: 0, shares: 0, views: 0 };
    const json = await res.json();
    const stats = json?.items?.[0]?.statistics;

    if (!stats) return { followers: 0, likes: 0, shares: 0, views: 0 };

    return {
      followers: 0,
      likes: Number(stats?.favoriteCount ?? stats?.likeCount ?? 0),
      shares: 0, // YouTube doesn't expose share count publicly
      views: Number(stats?.viewCount ?? 0),
    };
  }

  async publish(content: PostContent): Promise<PostContent> {
    // Simplified YT publish
    return {
      platformPostId: content.platformPostId ?? `yt_${Date.now()}`,
      url: content.url,
    };
  }

  async fetchCampaignReport(offerId: number): Promise<PlatformReport> {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, views, likes, shares FROM campaign_applicants WHERE offer_id = ?`,
      [offerId]
    );
    const posts = rows as Array<{ id: number; views: number; likes: number; shares: number }>;

    return {
      platform: 'youtube',
      totalViews: posts.reduce((s, p) => s + (p.views ?? 0), 0),
      totalLikes: posts.reduce((s, p) => s + (p.likes ?? 0), 0),
      totalShares: posts.reduce((s, p) => s + (p.shares ?? 0), 0),
      posts: posts.map((p) => ({
        postId: String(p.id),
        url: '',
        views: p.views ?? 0,
        likes: p.likes ?? 0,
        shares: p.shares ?? 0,
      })),
    };
  }
}
