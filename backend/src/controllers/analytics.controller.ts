import { Request, Response, NextFunction } from 'express';
import { pool } from '../config/db';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';
import { refreshAllVideosForUser } from '../services/tiktok.service';

export const analyticsController = {
  async brand(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') throw new ApiError(403, 'Brands only');
      const uid = req.user.id;

      // Refresh TikTok stats for all influencers' videos under this brand's offers
      try {
        const [influencerRows] = await pool.query<import('../config/db').DbRow[]>(
          `SELECT DISTINCT ca.influencer_user_id
             FROM campaign_applicants ca
             JOIN offers o ON o.id = ca.offer_id
            WHERE o.brand_user_id = ? AND ca.status IN ('approved','completed')`,
          [uid]
        );
        await Promise.allSettled(
          influencerRows.map((r) =>
            refreshAllVideosForUser((r as { influencer_user_id: number }).influencer_user_id)
          )
        );
      } catch { /* silent — don't block analytics if refresh fails */ }

      const days = Math.min(Math.max(Number(req.query.days) || 30, 1), 365);

      const [openOffers] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM offers WHERE brand_user_id = ? AND status = 'open'`, [uid]
      );
      const [activeOffers] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM offers WHERE brand_user_id = ? AND status = 'in_progress'`, [uid]
      );
      const [completedOffers] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM offers WHERE brand_user_id = ? AND status = 'completed'`, [uid]
      );
      const [applications] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM campaign_applicants ca
           JOIN offers o ON o.id = ca.offer_id
          WHERE o.brand_user_id = ?`, [uid]
      );
      const [totalBudget] = await pool.query<{ s: number }[] & import('../config/db').DbRow[]>(
        `SELECT COALESCE(SUM(budget),0) AS s FROM offers WHERE brand_user_id = ?`, [uid]
      );
      const [spend] = await pool.query<{ s: number }[] & import('../config/db').DbRow[]>(
        `SELECT COALESCE(SUM(o.budget),0) AS s
           FROM offers o
           JOIN campaign_applicants ca ON ca.offer_id = o.id
          WHERE o.brand_user_id = ? AND ca.status = 'approved'`, [uid]
      );
      const [series] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT DATE(created_at) AS day, COUNT(*) AS n
           FROM offers
          WHERE brand_user_id = ? AND created_at >= (NOW() - INTERVAL ? DAY)
          GROUP BY DATE(created_at)
          ORDER BY day ASC`, [uid, days]
      );
      const [applicantSeries] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT DATE(ca.created_at) AS day, COUNT(*) AS n
           FROM campaign_applicants ca
           JOIN offers o ON o.id = ca.offer_id
          WHERE o.brand_user_id = ? AND ca.created_at >= (NOW() - INTERVAL ? DAY)
          GROUP BY DATE(ca.created_at)
          ORDER BY day ASC`, [uid, days]
      );
      const [topNiches] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT ip.niche, COUNT(*) AS n
           FROM campaign_applicants ca
           JOIN offers o ON o.id = ca.offer_id
           JOIN influencer_profiles ip ON ip.user_id = ca.influencer_user_id
          WHERE o.brand_user_id = ? AND ip.niche IS NOT NULL
          GROUP BY ip.niche
          ORDER BY n DESC
          LIMIT 5`, [uid]
      );

      // Daily views & likes from video_daily_stats, aggregated across all influencers under this brand
      const [brandDailyStats] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT vds.stat_date AS day,
                COALESCE(SUM(vds.views_count), 0)  AS views,
                COALESCE(SUM(vds.likes_count),  0)  AS engagement
           FROM video_daily_stats vds
           JOIN campaign_applicants ca ON ca.influencer_user_id = vds.influencer_user_id
           JOIN offers o ON o.id = ca.offer_id
          WHERE o.brand_user_id = ?
            AND ca.status IN ('approved', 'completed')
            AND vds.stat_date >= (CURDATE() - INTERVAL ? DAY)
          GROUP BY vds.stat_date
          ORDER BY vds.stat_date ASC`,
        [uid, days]
      );

      return ok(res, {
        kpis: {
          open_offers:        Number((openOffers[0] as { n: number }).n) || 0,
          active_offers:      Number((activeOffers[0] as { n: number }).n) || 0,
          completed_offers:   Number((completedOffers[0] as { n: number }).n) || 0,
          total_applications: Number((applications[0] as { n: number }).n) || 0,
          total_budget:       Number((totalBudget[0] as { s: number }).s) || 0,
          committed_spend:    Number((spend[0] as { s: number }).s) || 0,
        },
        series: {
          offers_created: series,
          applications:   applicantSeries,
        },
        top_niches: topNiches,
        daily_stats: brandDailyStats,
        days,
      });
    } catch (e) { next(e); }
  },

  async influencer(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') throw new ApiError(403, 'Influencers only');
      const uid = req.user.id;

      // Refresh TikTok stats — also upserts today's video_daily_stats row
      try { await refreshAllVideosForUser(uid); } catch { /* silent */ }

      const days = Math.min(Math.max(Number(req.query.days) || 7, 1), 365);

      const [applied] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM campaign_applicants WHERE influencer_user_id = ?`, [uid]
      );
      const [approved] = await pool.query<{ n: number }[] & import('../config/db').DbRow[]>(
        `SELECT COUNT(*) AS n FROM campaign_applicants WHERE influencer_user_id = ? AND status = 'approved'`, [uid]
      );
      const [earnings] = await pool.query<{ s: number }[] & import('../config/db').DbRow[]>(
        `SELECT COALESCE(SUM(o.budget),0) AS s
           FROM campaign_applicants ca
           JOIN offers o ON o.id = ca.offer_id
          WHERE ca.influencer_user_id = ? AND ca.status = 'approved'`, [uid]
      );
      const [socials] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT platform, followers_count, engagement_rate
           FROM social_media_accounts
          WHERE influencer_user_id = ?`, [uid]
      );
      const totalFollowers = socials.reduce(
        (acc, r) => acc + Number((r as { followers_count: number }).followers_count || 0), 0
      );
      const avgEngagement = socials.length
        ? socials.reduce((acc, r) => acc + Number((r as { engagement_rate: number }).engagement_rate || 0), 0) / socials.length
        : 0;

      // Daily views & likes/engagement from video_daily_stats
      const [dailyStats] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT stat_date AS day,
                views_count    AS views,
                likes_count    AS engagement
           FROM video_daily_stats
          WHERE influencer_user_id = ?
            AND stat_date >= (CURDATE() - INTERVAL ? DAY)
          ORDER BY stat_date ASC`,
        [uid, days]
      );

      // Applications series (kept for reference, no longer used for bar chart)
      const [applicationsSeries] = await pool.query<import('../config/db').DbRow[]>(
        `SELECT DATE(created_at) AS day, COUNT(*) AS n
           FROM campaign_applicants
          WHERE influencer_user_id = ? AND created_at >= (NOW() - INTERVAL ? DAY)
          GROUP BY DATE(created_at)
          ORDER BY day ASC`, [uid, days]
      );

      return ok(res, {
        kpis: {
          total_applications: Number((applied[0] as { n: number }).n) || 0,
          approved_offers:    Number((approved[0] as { n: number }).n) || 0,
          estimated_earnings: Number((earnings[0] as { s: number }).s) || 0,
          total_followers:    totalFollowers,
          avg_engagement_rate: Number(avgEngagement.toFixed(2)),
        },
        socials,
        daily_stats:         dailyStats,        // ← views & engagement per day
        applications_series: applicationsSeries,
        days,
      });
    } catch (e) { next(e); }
  },
};