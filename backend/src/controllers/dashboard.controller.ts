import { Request, Response, NextFunction } from 'express';
import { dashboardService } from '../services/dashboard.service';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';
import { pool } from '../config/db';
import { refreshAllVideosForUser } from '../services/tiktok.service';

export const dashboardController = {
  async overview(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');

      // Refresh TikTok stats before returning overview
      if (req.user.role === 'influencer') {
        try { await refreshAllVideosForUser(req.user.id); } catch { /* silent */ }
      } else {
        try {
          const [influencerRows] = await pool.query<import('../config/db').DbRow[]>(
            `SELECT DISTINCT ca.influencer_user_id
               FROM campaign_applicants ca
               JOIN offers o ON o.id = ca.offer_id
              WHERE o.brand_user_id = ? AND ca.status IN ('approved','completed')`,
            [req.user.id]
          );
          await Promise.allSettled(
            influencerRows.map((r) =>
              refreshAllVideosForUser((r as { influencer_user_id: number }).influencer_user_id)
            )
          );
        } catch { /* silent */ }
      }

      const data = req.user.role === 'brand'
        ? await dashboardService.brandOverview(req.user.id)
        : await dashboardService.influencerOverview(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async influencer(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      if (req.user.role !== 'influencer') throw new ApiError(403, 'Influencers only');

      // Refresh TikTok stats for this influencer's videos
      try { await refreshAllVideosForUser(req.user.id); } catch { /* silent */ }

      const data = await dashboardService.influencerOverview(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async brand(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      if (req.user.role !== 'brand') throw new ApiError(403, 'Brands only');

      // Refresh TikTok stats for all influencers under this brand's offers
      try {
        const [influencerRows] = await pool.query<import('../config/db').DbRow[]>(
          `SELECT DISTINCT ca.influencer_user_id
             FROM campaign_applicants ca
             JOIN offers o ON o.id = ca.offer_id
            WHERE o.brand_user_id = ? AND ca.status IN ('approved','completed')`,
          [req.user.id]
        );
        await Promise.allSettled(
          influencerRows.map((r) =>
            refreshAllVideosForUser((r as { influencer_user_id: number }).influencer_user_id)
          )
        );
      } catch { /* silent */ }

      const data = await dashboardService.brandOverview(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },
};