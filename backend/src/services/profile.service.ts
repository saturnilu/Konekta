import { pool, DbRow } from '../config/db';
import { ApiError } from '../utils/apiError';

export const profileService = {
  async getMe(userId: number, role: 'influencer' | 'brand') {
    const [users] = await pool.query<DbRow[]>(
      'SELECT id, name, email, role, avatar_url, is_verified, created_at FROM users WHERE id = ?',
      [userId]
    );
    if (!users.length) throw new ApiError(404, 'User not found');
    const user = users[0];

    if (role === 'influencer') {
      const [prof] = await pool.query<DbRow[]>(
        'SELECT * FROM influencer_profiles WHERE user_id = ?',
        [userId]
      );
      const [soc] = await pool.query<DbRow[]>(
        'SELECT * FROM social_media_accounts WHERE influencer_user_id = ?',
        [userId]
      );
      return { user, profile: prof[0] ?? null, social_media: soc };
    }
    const [prof] = await pool.query<DbRow[]>(
      'SELECT * FROM brand_profiles WHERE user_id = ?',
      [userId]
    );
    return { user, profile: prof[0] ?? null };
  },

  async updateMe(userId: number, role: 'influencer' | 'brand', body: Record<string, unknown>) {
    if (role === 'influencer') {
      const allowed = [
        'username','bio','niche','industry','location','tiktok_account',
        'instagram_handle','youtube_handle','followers_count','engagement_rate',
        'rate_card','media_kit_url','payout_bank','payout_account',
      ] as const;
      const cols: string[] = [];
      const vals: unknown[] = [];
      for (const k of allowed) {
        if (body[k] !== undefined) { cols.push(`${k} = ?`); vals.push(body[k]); }
      }
      if (cols.length) {
        vals.push(userId);
        await pool.query(
          `UPDATE influencer_profiles SET ${cols.join(', ')} WHERE user_id = ?`,
          vals
        );
      }
    } else {
      const allowed = ['brand_name','description','industry','website','location','logo_url'] as const;
      const cols: string[] = [];
      const vals: unknown[] = [];
      for (const k of allowed) {
        if (body[k] !== undefined) { cols.push(`${k} = ?`); vals.push(body[k]); }
      }
      if (cols.length) {
        vals.push(userId);
        await pool.query(
          `UPDATE brand_profiles SET ${cols.join(', ')} WHERE user_id = ?`,
          vals
        );
      }
    }
    if (body.name !== undefined || body.avatar_url !== undefined) {
      const cols: string[] = [];
      const vals: unknown[] = [];
      if (body.name !== undefined) { cols.push('name = ?'); vals.push(body.name); }
      if (body.avatar_url !== undefined) { cols.push('avatar_url = ?'); vals.push(body.avatar_url); }
      if (cols.length) {
        vals.push(userId);
        await pool.query(`UPDATE users SET ${cols.join(', ')} WHERE id = ?`, vals);
      }
    }
    return this.getMe(userId, role);
  },

  async addSocialMedia(
    userId: number,
    data: { platform: string; handle: string; followers_count?: number; engagement_rate?: number }
  ) {
    const [r] = await pool.query(
      `INSERT INTO social_media_accounts (influencer_user_id, platform, handle, followers_count, engagement_rate)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, data.platform, data.handle, data.followers_count ?? 0, data.engagement_rate ?? 0]
    );
    return { id: (r as { insertId: number }).insertId, ...data };
  },
};
