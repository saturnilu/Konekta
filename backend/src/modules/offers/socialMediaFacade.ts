// ============================================================
// DESIGN PATTERN: FACADE (Structural)
// Tujuan: Menyederhanakan akses ke berbagai layanan TikTok, Instagram,
// YouTube (semua implement ISocialMediaAdapter) menjadi satu interface
// sederhana. Developer tidak perlu tahu adapter mana yang aktif.
// Lokasi pemakai:
//   - modules/offers/offer.controller.ts (publish post otomatis)
//   - modules/analytics/dashboard.service.ts (laporan analitik)
// Bekerja bersama:
//   - ADAPTER pattern (socialMediaAdapters.ts)
//   - OBSERVER pattern (publish 'metrics.synced' ke eventBus)
// ============================================================

import { pool, DbRow } from '../../config/db';
import {
  ISocialMediaAdapter,
  PlatformReport,
  PostContent,
  SocialMediaMetrics,
  TikTokAdapter,
  InstagramAdapter,
  YouTubeAdapter,
} from './socialMediaAdapters';
import { eventBus } from './eventBus';

interface CampaignSummary {
  offerId: number;
  platforms: PlatformReport[];
  combined: {
    totalViews: number;
    totalLikes: number;
    totalShares: number;
    platformCount: number;
  };
  syncedAt: Date;
}

interface PublishResult {
  platform: string;
  post: PostContent;
}

/**
 * [FACADE PATTERN] — SocialMediaFacade
 *
 * "Front desk" untuk semua operasi multi-platform. Caller tidak perlu
 * tahu adapter mana yang harus dipakai atau bagaimana menggabungkan
 * hasilnya — facade yang menangani semua kompleksitas itu.
 */
export class SocialMediaFacade {
  private adapters: Map<string, ISocialMediaAdapter>;

  constructor() {
    this.adapters = new Map<string, ISocialMediaAdapter>();
    this.adapters.set('tiktok', new TikTokAdapter());
    this.adapters.set('instagram', new InstagramAdapter());
    this.adapters.set('youtube', new YouTubeAdapter());
  }

  // [FACADE PATTERN] — getAdapter: factory sederhana internal
  private getAdapter(platform: string): ISocialMediaAdapter {
    const adapter = this.adapters.get(platform.toLowerCase());
    if (!adapter) {
      throw new Error(`Unsupported platform: ${platform}`);
    }
    return adapter;
  }

  /**
   * [FACADE PATTERN] — getCampaignSummary
   * Menggabungkan laporan dari semua platform yang terhubung ke offer.
   * Caller cukup panggil 1 method, facade yang loop ke semua adapter.
   */
  async getCampaignSummary(offerId: number): Promise<CampaignSummary> {
    const [accountRows] = await pool.query<DbRow[]>(
      `SELECT DISTINCT platform FROM social_media_accounts
       WHERE influencer_user_id = (
         SELECT influencer_user_id FROM offers WHERE id = ?
       )`,
      [offerId]
    );

    const platforms = (accountRows as { platform: string }[]).map((r) => r.platform);
    const platformList = platforms.length ? platforms : ['tiktok', 'instagram', 'youtube'];

    const reports = await Promise.all(
      platformList.map(async (p) => {
        try {
          return await this.getAdapter(p).fetchCampaignReport(offerId);
        } catch (e) {
          console.warn(`[SocialMediaFacade] failed to fetch report from ${p}:`, e);
          return null;
        }
      })
    );

    const validReports = reports.filter((r): r is PlatformReport => r !== null);

    return {
      offerId,
      platforms: validReports,
      combined: {
        totalViews: validReports.reduce((s, r) => s + r.totalViews, 0),
        totalLikes: validReports.reduce((s, r) => s + r.totalLikes, 0),
        totalShares: validReports.reduce((s, r) => s + r.totalShares, 0),
        platformCount: validReports.length,
      },
      syncedAt: new Date(),
    };
  }

  /**
   * [FACADE PATTERN] — syncMetrics
   * Ambil metrics dari setiap platform lalu simpan ke DB.
   * Setelah selesai → publish 'metrics.synced' event (OBSERVER Pattern).
   */
  async syncMetrics(offerId: number): Promise<CampaignSummary> {
    const summary = await this.getCampaignSummary(offerId);

    for (const report of summary.platforms) {
      for (const post of report.posts) {
        await pool.query(
          `UPDATE campaign_applicants
           SET views = ?, likes = ?, shares = ?, updated_at = NOW()
           WHERE id = ?`,
          [post.views, post.likes, post.shares, Number(post.postId)]
        ).catch((err) => {
          console.warn(`[SocialMediaFacade] failed to persist metrics for post ${post.postId}:`, err);
        });
      }
    }

    // [OBSERVER PATTERN] — publish event agar analytics subscriber bisa respond
    await eventBus.publish('metrics.synced', {
      offer_id: offerId,
      total_views: summary.combined.totalViews,
      total_likes: summary.combined.totalLikes,
      total_shares: summary.combined.totalShares,
      platform_count: summary.combined.platformCount,
    });

    return summary;
  }

  /**
   * [FACADE PATTERN] — publishPost
   * Publish ke satu platform tertentu. Caller tidak perlu instantiate
   * adapter sendiri — facade yang menentukan adapter yang sesuai.
   */
  async publishPost(platform: string, _userId: number, content: PostContent): Promise<PublishResult> {
    const adapter = this.getAdapter(platform);
    const post = await adapter.publish(content);
    return { platform, post };
  }

  /**
   * [FACADE PATTERN] — getMetrics
   * Forward ke adapter yang sesuai, menyembunyikan detail API call.
   */
  async getMetrics(platform: string, postId: string): Promise<SocialMediaMetrics> {
    return this.getAdapter(platform).getMetrics(postId);
  }
}

// [FACADE PATTERN] — Singleton instance
export const socialMediaFacade = new SocialMediaFacade();
export default socialMediaFacade;
