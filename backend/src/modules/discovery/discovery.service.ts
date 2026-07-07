import { pool, DbRow } from '../../config/db';

export interface DiscoveryQuery {
  q?: string;
  niche?: string;
  industry?: string;
  location?: string;
  platform?: string;
  min_followers?: number;
  max_followers?: number;
  min_engagement?: number;
  category?: string;
  is_public?: boolean;
  page?: number;
  limit?: number;
}

export const discoveryService = {
  async listInfluencers(q: DiscoveryQuery) {
    const page = q.page ?? 1;
    const limit = Math.min(q.limit ?? 20, 50);
    const offset = (page - 1) * limit;

    const where: string[] = ["u.role = 'influencer'"];
    const params: unknown[] = [];

    if (q.q) {
      where.push('(ip.username LIKE ? OR ip.niche LIKE ? OR ip.bio LIKE ?)');
      const w = `%${q.q}%`;
      params.push(w, w, w);
    }
    if (q.niche)     { where.push('ip.niche = ?');          params.push(q.niche); }
    if (q.location)  { where.push('ip.location = ?');       params.push(q.location); }
    if (q.min_followers)   { where.push('ip.followers_count >= ?'); params.push(q.min_followers); }
    if (q.max_followers)   { where.push('ip.followers_count <= ?'); params.push(q.max_followers); }
    if (q.min_engagement)  { where.push('ip.engagement_rate >= ?'); params.push(q.min_engagement); }

    const sql = `
      SELECT u.id, u.name, u.avatar_url, u.is_verified,
             ip.username, ip.bio, ip.niche, ip.industry, ip.location,
             ip.followers_count, ip.engagement_rate, ip.rate_card
      FROM users u
      JOIN influencer_profiles ip ON ip.user_id = u.id
      WHERE ${where.join(' AND ')}
      ORDER BY ip.followers_count DESC
      LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const [rows] = await pool.query<DbRow[]>(sql, params);
    return { page, limit, items: rows };
  },

  async listBrands(q: DiscoveryQuery) {
    const page = q.page ?? 1;
    const limit = Math.min(q.limit ?? 20, 50);
    const offset = (page - 1) * limit;

    const where: string[] = ["u.role = 'brand'"];
    const params: unknown[] = [];

    if (q.q) {
      where.push('(bp.brand_name LIKE ? OR bp.description LIKE ? OR bp.industry LIKE ?)');
      const w = `%${q.q}%`;
      params.push(w, w, w);
    }
    if (q.industry)   { where.push('bp.industry = ?');  params.push(q.industry); }
    if (q.location)   { where.push('bp.location = ?');  params.push(q.location); }
    if (q.category)   { where.push('bp.industry = ?');  params.push(q.category); }

    const sql = `
      SELECT u.id, u.name, u.avatar_url,
             bp.brand_name, bp.description, bp.industry, bp.website, bp.location, bp.logo_url
      FROM users u
      JOIN brand_profiles bp ON bp.user_id = u.id
      WHERE ${where.join(' AND ')}
      ORDER BY u.created_at DESC
      LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const [rows] = await pool.query<DbRow[]>(sql, params);
    return { page, limit, items: rows };
  },

  async getInfluencer(id: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT u.id, u.name, u.avatar_url, u.is_verified,
              ip.username, ip.bio, ip.niche, ip.industry, ip.location,
              ip.tiktok_account, ip.instagram_handle, ip.youtube_handle,
              ip.followers_count, ip.engagement_rate, ip.rate_card, ip.media_kit_url
       FROM users u
       JOIN influencer_profiles ip ON ip.user_id = u.id
       WHERE u.id = ? AND u.role = 'influencer'`,
      [id]
    );
    if (!rows.length) return null;
    const [socials] = await pool.query<DbRow[]>(
      'SELECT * FROM social_media_accounts WHERE influencer_user_id = ?',
      [id]
    );
    return { ...rows[0], social_media: socials };
  },

  async getBrand(id: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT u.id, u.name, u.avatar_url,
              bp.brand_name, bp.description, bp.industry, bp.website, bp.location, bp.logo_url
       FROM users u
       JOIN brand_profiles bp ON bp.user_id = u.id
       WHERE u.id = ? AND u.role = 'brand'`,
      [id]
    );
    return rows[0] ?? null;
  },
};
