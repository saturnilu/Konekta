import { pool, DbRow } from '../config/db';

export const dashboardService = {
  async influencerOverview(userId: number) {
    const [[profile]] = await pool.query<DbRow[]>(
      'SELECT followers_count, engagement_rate FROM influencer_profiles WHERE user_id = ?',
      [userId]
    );

    // Count active/completed from campaign_applicants
    const [[counts]] = await pool.query<DbRow[]>(
      `SELECT
         SUM(CASE WHEN o.status IN ('open','in_progress') AND ca.status = 'approved' THEN 1 ELSE 0 END) AS active,
         SUM(CASE WHEN ca.status = 'completed' THEN 1 ELSE 0 END) AS completed,
         SUM(CASE WHEN ca.status = 'pending'   THEN 1 ELSE 0 END) AS pending_proposals
       FROM campaign_applicants ca
       JOIN offers o ON o.id = ca.offer_id
       WHERE ca.influencer_user_id = ?`,
      [userId]
    );

    // This month's earnings (from paid campaigns recorded in earnings table)
    const [[monthEarnings]] = await pool.query<DbRow[]>(
      `SELECT COALESCE(SUM(amount), 0) AS total
         FROM earnings
        WHERE influencer_user_id = ?
          AND MONTH(created_at) = MONTH(CURDATE())
          AND YEAR(created_at)  = YEAR(CURDATE())`,
      [userId]
    );

    // Pending earnings = sum of reward_per_creator for approved-but-unpaid campaigns
    const [[pendingEarnings]] = await pool.query<DbRow[]>(
      `SELECT COALESCE(SUM(o.reward_per_creator), 0) AS total
         FROM campaign_applicants ca
         JOIN offers o ON o.id = ca.offer_id
        WHERE ca.influencer_user_id = ?
          AND ca.status = 'approved'`,
      [userId]
    );

    // Total views & likes from submitted videos on completed (paid) campaigns
    const [[videoStats]] = await pool.query<DbRow[]>(
      `SELECT
         COALESCE(SUM(sv.views_count), 0) AS total_views,
         COALESCE(SUM(sv.likes_count), 0) AS total_likes
       FROM submitted_videos sv
       JOIN campaign_applicants ca
         ON ca.offer_id = sv.offer_id AND ca.influencer_user_id = sv.influencer_user_id
       WHERE sv.influencer_user_id = ?
         AND ca.status = 'completed'`,
      [userId]
    );

    const [campaigns] = await pool.query<DbRow[]>(
      `SELECT o.id, o.title, o.brief, o.status, o.budget, o.deadline, o.created_at,
              o.target_views, o.target_likes, o.reward_per_creator,
              ca.status AS application_status, ca.progress,
              bp.brand_name,
              DATEDIFF(o.deadline, CURDATE()) AS days_left
       FROM campaign_applicants ca
       JOIN offers o ON o.id = ca.offer_id
       LEFT JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
       WHERE ca.influencer_user_id = ? AND ca.status IN ('approved', 'pending')
       ORDER BY o.created_at DESC
       LIMIT 5`,
      [userId]
    );

    const p   = profile        as { followers_count?: number; engagement_rate?: number } | undefined;
    const c   = counts         as { active?: number; completed?: number; pending_proposals?: number } | undefined;
    const me  = monthEarnings  as { total?: number } | undefined;
    const pe  = pendingEarnings as { total?: number } | undefined;
    const vs  = videoStats     as { total_views?: number; total_likes?: number } | undefined;

    return {
      summary: {
        audience_reached:     p?.followers_count ?? 0,
        engagement_rate:      p?.engagement_rate ?? 0,
        total_interactions:   0,
        completed_campaigns:  c?.completed ?? 0,
        active_campaigns:     c?.active ?? 0,
        pending_proposals:    c?.pending_proposals ?? 0,
        this_month_earnings:  Number(me?.total ?? 0),
        pending_earnings:     Number(pe?.total ?? 0),
        total_views:          Number(vs?.total_views ?? 0),
        total_likes:          Number(vs?.total_likes ?? 0),
      },
      active_campaigns: campaigns,
    };
  },

  async brandOverview(userId: number) {
    const [[counts]] = await pool.query<DbRow[]>(
      `SELECT
         COUNT(DISTINCT o.influencer_user_id) AS creators_hired,
         COALESCE(SUM(o.budget), 0)           AS total_budget,
         COUNT(o.id)                          AS campaigns_created,
         SUM(CASE WHEN o.status = 'in_progress' THEN 1 ELSE 0 END) AS active_campaigns,
         SUM(CASE WHEN o.status = 'completed'   THEN 1 ELSE 0 END) AS completed_campaigns
       FROM offers o WHERE o.brand_user_id = ?`,
      [userId]
    );

    const [[perf]] = await pool.query<DbRow[]>(
      `SELECT
         AVG(ip.engagement_rate)              AS avg_engagement,
         COALESCE(SUM(ip.followers_count), 0) AS total_followers
       FROM offers o
       JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
       WHERE o.brand_user_id = ?`,
      [userId]
    );

    const [[approvals]] = await pool.query<DbRow[]>(
      `SELECT COUNT(*) AS cnt FROM campaign_applicants ca
       JOIN offers o ON o.id = ca.offer_id
       WHERE o.brand_user_id = ? AND ca.status = 'pending'`,
      [userId]
    );

    // This week's total views from paid influencer videos
    const [[thisWeek]] = await pool.query<DbRow[]>(
      `SELECT COALESCE(SUM(sv.views_count), 0) AS views
         FROM submitted_videos sv
         JOIN campaign_applicants ca
           ON ca.offer_id = sv.offer_id AND ca.influencer_user_id = sv.influencer_user_id
         JOIN offers o ON o.id = sv.offer_id
        WHERE o.brand_user_id = ?
          AND ca.status = 'completed'
          AND sv.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)`,
      [userId]
    );

    // Last week's total views (for growth % comparison)
    const [[lastWeek]] = await pool.query<DbRow[]>(
      `SELECT COALESCE(SUM(sv.views_count), 0) AS views
         FROM submitted_videos sv
         JOIN campaign_applicants ca
           ON ca.offer_id = sv.offer_id AND ca.influencer_user_id = sv.influencer_user_id
         JOIN offers o ON o.id = sv.offer_id
        WHERE o.brand_user_id = ?
          AND ca.status = 'completed'
          AND sv.created_at >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
          AND sv.created_at <  DATE_SUB(CURDATE(), INTERVAL 7 DAY)`,
      [userId]
    );

    // Avg engagement rate & total interactions from ALL paid videos (all time)
    const [[engStats]] = await pool.query<DbRow[]>(
      `SELECT
         COALESCE(SUM(sv.views_count), 0) AS total_views,
         COALESCE(SUM(sv.likes_count), 0) AS total_likes,
         COALESCE(SUM(sv.shares_count), 0) AS total_shares
       FROM submitted_videos sv
       JOIN campaign_applicants ca
         ON ca.offer_id = sv.offer_id AND ca.influencer_user_id = sv.influencer_user_id
       JOIN offers o ON o.id = sv.offer_id
      WHERE o.brand_user_id = ?
        AND ca.status = 'completed'`,
      [userId]
    );

    const [recent_campaigns] = await pool.query<DbRow[]>(
      `SELECT o.id, o.title, o.deadline, o.status, o.budget, o.room_code,
              o.is_public,
              (SELECT COUNT(*) FROM campaign_applicants ca2 WHERE ca2.offer_id = o.id) AS applicants_count,
              ip.username AS influencer_username, u2.name AS influencer_name
       FROM offers o
       LEFT JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
       LEFT JOIN users u2 ON u2.id = o.influencer_user_id
       WHERE o.brand_user_id = ?
       ORDER BY o.created_at DESC
       LIMIT 5`,
      [userId]
    );

    const ap  = approvals as { cnt?: number } | undefined;
    const cf  = perf      as { avg_engagement?: number; total_followers?: number } | undefined;
    const co  = counts    as {
      creators_hired?: number; total_budget?: number; campaigns_created?: number;
      active_campaigns?: number; completed_campaigns?: number;
    } | undefined;
    const tw  = thisWeek  as { views?: number } | undefined;
    const lw  = lastWeek  as { views?: number } | undefined;
    const es  = engStats  as { total_views?: number; total_likes?: number; total_shares?: number } | undefined;

    const thisWeekViews = Number(tw?.views ?? 0);
    const lastWeekViews = Number(lw?.views ?? 0);
    const weekGrowthPct = lastWeekViews > 0
      ? Math.round(((thisWeekViews - lastWeekViews) / lastWeekViews) * 1000) / 10
      : (thisWeekViews > 0 ? 100 : 0);

    const allTimeViews  = Number(es?.total_views  ?? 0);
    const allTimeLikes  = Number(es?.total_likes  ?? 0);
    const allTimeShares = Number(es?.total_shares ?? 0);
    // Avg engagement = likes / views * 100 (%)
    const avgEngagement = allTimeViews > 0
      ? Math.round((allTimeLikes / allTimeViews) * 10000) / 100
      : 0;
    const totalInteractions = allTimeLikes + allTimeShares;

    return {
      summary: {
        audience_reached:      Number(cf?.total_followers ?? 0),
        engagement_rate:       avgEngagement,
        total_interactions:    totalInteractions,
        completed_campaigns:   co?.completed_campaigns ?? 0,
        active_campaigns:      co?.active_campaigns    ?? 0,
        pending_approvals:     ap?.cnt ?? 0,
        creators_hired:        co?.creators_hired  ?? 0,
        total_budget:          co?.total_budget    ?? 0,
        campaigns_created:     co?.campaigns_created ?? 0,
        this_week_views:       thisWeekViews,
        week_growth_pct:       weekGrowthPct,
      },
      stats: {
        total_campaigns:     co?.campaigns_created ?? 0,
        active_campaigns:    co?.active_campaigns  ?? 0,
        completed_campaigns: co?.completed_campaigns ?? 0,
        total_budget:        co?.total_budget ?? 0,
      },
      recent_campaigns,
    };
  },
};
