// ============================================================
// MODULE offer.service — dipakai oleh modules/offers/offer.controller.ts
// Main offer.service.ts di src/services/ dipakai oleh controllers lain.
// ============================================================

import { pool, DbRow, DbResult } from '../../config/db';
import { ApiError } from '../../core/utils/apiError';

export interface OfferInput {
  brand_user_id: number;
  influencer_user_id?: number | null;
  title: string;
  brief?: string;
  budget: number;
  reward_per_creator?: number;
  target_views?: number;
  target_likes?: number;
  target_shares?: number;
  deliverables?: string;
  requirements?: string;
  target_audience?: string;
  deadline?: string;
  room_code?: string;
  is_public?: boolean;
}

export const offerService = {
  async create(input: OfferInput) {
    const [r] = await pool.query<DbResult>(
      `INSERT INTO offers
       (brand_user_id, influencer_user_id, title, brief, budget, reward_per_creator,
        target_views, target_likes, target_shares, deliverables, requirements,
        target_audience, deadline, room_code, status, is_public)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'open', ?)`,
      [
        input.brand_user_id,
        input.influencer_user_id ?? null,
        input.title,
        input.brief ?? null,
        input.budget,
        input.reward_per_creator ?? input.budget,
        input.target_views ?? 0,
        input.target_likes ?? 0,
        input.target_shares ?? 0,
        input.deliverables ?? null,
        input.requirements ?? null,
        input.target_audience ?? null,
        input.deadline ?? null,
        input.room_code ?? null,
        input.is_public === false ? 0 : 1,
      ]
    );
    // Notify influencer if specifically targeted
    if (input.influencer_user_id) {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, icon)
         VALUES (?, 'offer', 'New Offer', ?, 'mail')`,
        [input.influencer_user_id, `You received an offer: ${input.title}`]
      );
    }
    return this.getById((r as DbResult).insertId);
  },

  async list(userId: number, role: 'influencer' | 'brand') {
    if (role === 'brand') {
      const [rows] = await pool.query<DbRow[]>(
        `SELECT o.*, bp.brand_name, bp.logo_url,
                (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id) AS applicants_count
         FROM offers o
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
         WHERE o.brand_user_id = ?
         ORDER BY o.created_at DESC`,
        [userId]
      );
      return rows;
    }
    // influencer: offers they applied to
    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name, bp.logo_url,
              ca.id AS application_id, ca.status AS application_status, ca.proposed_rate
       FROM campaign_applicants ca
       JOIN offers o ON o.id = ca.offer_id
       JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
       WHERE ca.influencer_user_id = ?
       ORDER BY ca.created_at DESC`,
      [userId]
    );
    return rows;
  },

  async getById(id: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name, bp.logo_url, bp.industry, bp.location AS brand_location,
              ip.username AS influencer_username, u2.name AS influencer_name,
              (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id) AS applicants_count
       FROM offers o
       JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
       LEFT JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
       LEFT JOIN users u2 ON u2.id = o.influencer_user_id
       WHERE o.id = ?`,
      [id]
    );
    return rows[0] ?? null;
  },

  async updateStatus(id: number, userId: number, status: string) {
    const allowed = [
      'draft', 'open', 'offered', 'negotiation', 'accepted',
      'in_progress', 'submitted', 'completed', 'rejected', 'cancelled',
    ];
    if (!allowed.includes(status)) throw new ApiError(400, 'Invalid status');

    const [rows] = await pool.query<DbRow[]>(
      'SELECT brand_user_id, influencer_user_id, title FROM offers WHERE id = ?',
      [id]
    );
    if (!rows.length) throw new ApiError(404, 'Offer not found');
    const offer = rows[0] as { brand_user_id: number; influencer_user_id: number | null; title: string };

    if (userId !== offer.brand_user_id && userId !== offer.influencer_user_id) {
      throw new ApiError(403, 'Not allowed to change this offer');
    }

    await pool.query('UPDATE offers SET status = ? WHERE id = ?', [status, id]);

    // Notify the other party
    const notifyUser = userId === offer.brand_user_id
      ? offer.influencer_user_id
      : offer.brand_user_id;
    if (notifyUser) {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, icon)
         VALUES (?, 'status', 'Status Updated', ?, 'sync')`,
        [notifyUser, `${offer.title} is now ${status}`]
      );
    }
    return this.getById(id);
  },
};
