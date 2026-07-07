import { pool, DbRow } from '../config/db';

function rangeClause(table: string, days: number) {
  return `${table}.created_at >= (NOW() - INTERVAL ${Math.max(1, Math.min(days, 365))} DAY)`;
}

export const analyticsService = {
  async brandOverview(brandUserId: number, days = 30) {
    const where = rangeClause('o', days);

    const [summaryRows] = await pool.query<DbRow[]>(
      `SELECT
         COUNT(*) AS total_campaigns,
         SUM(CASE WHEN o.status = 'in_progress' THEN 1 ELSE 0 END) AS active_campaigns,
         SUM(CASE WHEN o.status = 'completed'   THEN 1 ELSE 0 END) AS completed_campaigns,
         COALESCE(SUM(o.budget), 0)              AS total_spend,
         COALESCE(SUM(ip.followers_count), 0)    AS total_reach,
         COALESCE(AVG(ip.engagement_rate), 0)    AS avg_engagement
       FROM offers o
       LEFT JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
       WHERE o.brand_user_id = ? AND ${where}`,
      [brandUserId]
    );

    const [trendRows] = await pool.query<DbRow[]>(
      `SELECT DATE(o.created_at) AS d,
              COUNT(*)           AS campaigns,
              COALESCE(SUM(o.budget), 0) AS spend
         FROM offers o
        WHERE o.brand_user_id = ? AND ${where}
        GROUP BY DATE(o.created_at)
        ORDER BY d ASC`,
      [brandUserId]
    );

    const [topInfluencers] = await pool.query<DbRow[]>(
      `SELECT ca.influencer_user_id, u.name, ip.username,
              ip.followers_count, ip.engagement_rate,
              COUNT(o.id) AS collabs,
              COALESCE(SUM(ca.proposed_rate), 0) AS total_value
         FROM campaign_applicants ca
         JOIN offers o ON o.id = ca.offer_id
         JOIN users u ON u.id = ca.influencer_user_id
         JOIN influencer_profiles ip ON ip.user_id = ca.influencer_user_id
        WHERE o.brand_user_id = ? AND ca.status = 'approved'
        GROUP BY ca.influencer_user_id, u.name, ip.username,
                 ip.followers_count, ip.engagement_rate
        ORDER BY collabs DESC
        LIMIT 5`,
      [brandUserId]
    );

    return {
      summary: summaryRows[0],
      trend: trendRows,
      top_influencers: topInfluencers,
      days,
    };
  },

  async influencerOverview(influencerUserId: number, days = 30) {
    const where = rangeClause('ca', days);

    const [summaryRows] = await pool.query<DbRow[]>(
      `SELECT
         COUNT(*) AS applications,
         SUM(CASE WHEN ca.status = 'approved'   THEN 1 ELSE 0 END) AS accepted,
         SUM(CASE WHEN ca.status = 'pending'    THEN 1 ELSE 0 END) AS pending,
         COALESCE(SUM(ca.proposed_rate), 0) AS total_earnings
       FROM campaign_applicants ca
       WHERE ca.influencer_user_id = ? AND ${where}`,
      [influencerUserId]
    );

    const [socialRows] = await pool.query<DbRow[]>(
      `SELECT platform, handle, followers_count, engagement_rate
         FROM social_media_accounts
        WHERE influencer_user_id = ?`,
      [influencerUserId]
    );

    const [campaigns] = await pool.query<DbRow[]>(
      `SELECT o.id, o.title, o.budget, o.status, ca.proposed_rate, ca.status AS application_status
         FROM campaign_applicants ca
         JOIN offers o ON o.id = ca.offer_id
        WHERE ca.influencer_user_id = ? AND ca.status = 'approved'
        ORDER BY o.created_at DESC
        LIMIT 10`,
      [influencerUserId]
    );

    return {
      summary: summaryRows[0],
      social_media: socialRows,
      recent_campaigns: campaigns,
      days,
    };
  },
};
