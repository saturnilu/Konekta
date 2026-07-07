import { pool, DbRow, DbResult } from '../config/db';
import { ApiError } from '../utils/apiError';

export interface CreateOfferInput {
  title: string;
  brief?: string;
  budget: number;
  reward_per_creator?: number;
  max_creators?: number;
  target_views?: number;
  target_likes?: number;
  target_shares?: number;
  deliverables?: string;
  requirements?: string;
  target_audience?: string;
  deadline?: string;
  is_public?: boolean;
}

export const offerService = {
  async listForBrand(brandUserId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name,
              (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id) AS applicants_count,
              (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id AND ca.status IN ('approved','completed')) AS active_count,
              (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id AND ca.status = 'completed') AS completed_count
         FROM offers o
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
        WHERE o.brand_user_id = ?
        ORDER BY o.created_at DESC`,
      [brandUserId]
    );
    return rows;
  },

  async listForInfluencer(influencerUserId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name,
              ca.id AS application_id, ca.status AS application_status,
              ca.proposed_rate, ca.progress,
              DATEDIFF(o.deadline, CURDATE()) AS days_left
         FROM offers o
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
         JOIN campaign_applicants ca
           ON ca.offer_id = o.id AND ca.influencer_user_id = ?
        ORDER BY o.created_at DESC`,
      [influencerUserId]
    );
    return rows;
  },

  async getById(id: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name, u.name AS brand_contact_name, u.avatar_url AS brand_avatar,
              (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id) AS applicants_count
         FROM offers o
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
         JOIN users u ON u.id = o.brand_user_id
        WHERE o.id = ?`,
      [id]
    );
    if (!rows.length) throw new ApiError(404, 'Offer not found');
    return rows[0];
  },

  async create(brandUserId: number, data: CreateOfferInput) {
    const isPublic = data.is_public !== false ? 1 : 0;
    const rewardPerCreator = data.reward_per_creator ?? data.budget;
    const maxCreators = data.max_creators ?? 0;
    const [r] = await pool.query<DbResult>(
      `INSERT INTO offers
        (brand_user_id, title, brief, budget, reward_per_creator, max_creators,
         target_views, target_likes, target_shares,
         deliverables, requirements, target_audience, deadline, status, is_public)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)`,
      [
        brandUserId,
        data.title,
        data.brief ?? null,
        data.budget,
        rewardPerCreator,
        maxCreators,
        data.target_views ?? 0,
        data.target_likes ?? 0,
        data.target_shares ?? 0,
        data.deliverables ?? null,
        data.requirements ?? null,
        data.target_audience ?? null,
        data.deadline ?? null,
        isPublic,
      ]
    );
    return this.getById(r.insertId);
  },

  async update(id: number, brandUserId: number, body: Record<string, unknown>) {
    const [own] = await pool.query<DbRow[]>(
      'SELECT brand_user_id FROM offers WHERE id = ?', [id]
    );
    if (!own.length) throw new ApiError(404, 'Offer not found');
    if ((own[0] as { brand_user_id: number }).brand_user_id !== brandUserId) {
      throw new ApiError(403, 'Not your offer');
    }
    const allowed = ['title','brief','budget','deliverables','requirements','target_audience','deadline','status'] as const;
    const cols: string[] = []; const vals: unknown[] = [];
    for (const k of allowed) {
      if (body[k] !== undefined) {
        cols.push(`${k} = ?`);
        vals.push(body[k]);
      }
    }
    if (cols.length) {
      vals.push(id);
      await pool.query(`UPDATE offers SET ${cols.join(', ')} WHERE id = ?`, vals);
    }
    return this.getById(id);
  },

  async listApplicants(offerId: number, brandUserId: number) {
    const [own] = await pool.query<DbRow[]>(
      'SELECT brand_user_id FROM offers WHERE id = ?', [offerId]
    );
    if (!own.length) throw new ApiError(404, 'Offer not found');
    if ((own[0] as { brand_user_id: number }).brand_user_id !== brandUserId) {
      throw new ApiError(403, 'Not your offer');
    }
    const [rows] = await pool.query<DbRow[]>(
      `SELECT ca.id, ca.status, ca.proposed_rate, ca.message, ca.created_at,
              u.id AS influencer_id, u.name, u.avatar_url, u.is_verified,
              ip.username, ip.niche, ip.bio, ip.followers_count, ip.engagement_rate,
              ip.rate_card
         FROM campaign_applicants ca
         JOIN users u ON u.id = ca.influencer_user_id
         JOIN influencer_profiles ip ON ip.user_id = ca.influencer_user_id
        WHERE ca.offer_id = ?
        ORDER BY ca.created_at DESC`,
      [offerId]
    );
    return rows;
  },

  async getApplicant(offerId: number, applicationId: number, brandUserId: number) {
    const [own] = await pool.query<DbRow[]>(
      'SELECT brand_user_id FROM offers WHERE id = ?', [offerId]
    );
    if (!own.length) throw new ApiError(404, 'Offer not found');
    if ((own[0] as { brand_user_id: number }).brand_user_id !== brandUserId) {
      throw new ApiError(403, 'Not your offer');
    }
    const [rows] = await pool.query<DbRow[]>(
      `SELECT ca.*, u.name, u.avatar_url, u.is_verified,
              ip.username, ip.niche, ip.bio, ip.location, ip.industry,
              ip.followers_count, ip.engagement_rate, ip.rate_card, ip.media_kit_url
         FROM campaign_applicants ca
         JOIN users u ON u.id = ca.influencer_user_id
         JOIN influencer_profiles ip ON ip.user_id = ca.influencer_user_id
        WHERE ca.id = ? AND ca.offer_id = ?`,
      [applicationId, offerId]
    );
    if (!rows.length) throw new ApiError(404, 'Application not found');
    const [socials] = await pool.query<DbRow[]>(
      'SELECT * FROM social_media_accounts WHERE influencer_user_id = ?',
      [(rows[0] as { influencer_user_id: number }).influencer_user_id]
    );
    return { ...rows[0], social_media: socials };
  },

  async setApplicationStatus(
    offerId: number, applicationId: number, brandUserId: number,
    status: 'approved' | 'rejected' | 'shortlisted'
  ) {
    const [own] = await pool.query<DbRow[]>(
      'SELECT brand_user_id FROM offers WHERE id = ?', [offerId]
    );
    if (!own.length) throw new ApiError(404, 'Offer not found');
    if ((own[0] as { brand_user_id: number }).brand_user_id !== brandUserId) {
      throw new ApiError(403, 'Not your offer');
    }
    await pool.query(
      'UPDATE campaign_applicants SET status = ? WHERE id = ? AND offer_id = ?',
      [status, applicationId, offerId]
    );
    // Do NOT auto-close the offer — brand campaigns support multiple influencers.
    // The offer stays 'open' so other influencers can still apply and be approved.
    // Brand manually closes/completes the offer when ready.
    return { ok: true, status };
  },

  async apply(offerId: number, influencerUserId: number, payload: { message?: string; proposed_rate?: number }) {
    const [o] = await pool.query<DbRow[]>('SELECT brand_user_id, status, max_creators FROM offers WHERE id = ?', [offerId]);
    if (!o.length) throw new ApiError(404, 'Offer not found');
    const offer = o[0] as { status: string; max_creators: number };
    if (!['open', 'in_progress'].includes(offer.status)) {
      throw new ApiError(400, 'Offer is not accepting applications');
    }

    // Check if campaign is full (max_creators = 0 means unlimited)
    if (offer.max_creators > 0) {
      const [countRows] = await pool.query<DbRow[]>(
        `SELECT COUNT(*) AS cnt FROM campaign_applicants
          WHERE offer_id = ? AND status IN ('approved', 'completed')`,
        [offerId]
      );
      const approved = (countRows[0] as { cnt: number }).cnt;
      if (approved >= offer.max_creators) {
        throw new ApiError(400, 'This campaign has reached its maximum number of creators');
      }
    }

    const [dup] = await pool.query<DbRow[]>(
      'SELECT id FROM campaign_applicants WHERE offer_id = ? AND influencer_user_id = ?',
      [offerId, influencerUserId]
    );
    if (dup.length) throw new ApiError(409, 'You already applied to this offer');
    const [r] = await pool.query<DbResult>(
      `INSERT INTO campaign_applicants (offer_id, influencer_user_id, status, message, proposed_rate)
       VALUES (?, ?, 'pending', ?, ?)`,
      [offerId, influencerUserId, payload.message ?? null, payload.proposed_rate ?? null]
    );
    return { id: r.insertId, offer_id: offerId, status: 'pending' };
  },

  async myApplications(influencerUserId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT ca.id, ca.status, ca.proposed_rate, ca.message, ca.created_at,
              o.id AS offer_id, o.title, o.budget, o.status AS offer_status,
              bp.brand_name
         FROM campaign_applicants ca
         JOIN offers o ON o.id = ca.offer_id
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
        WHERE ca.influencer_user_id = ?
        ORDER BY ca.created_at DESC`,
      [influencerUserId]
    );
    return rows;
  },

  async addProgress(
    offerId: number, influencerUserId: number,
    payload: { milestone: string; status: string; notes?: string }
  ) {
    const [own] = await pool.query<DbRow[]>(
      `SELECT ca.id FROM campaign_applicants ca
        WHERE ca.offer_id = ? AND ca.influencer_user_id = ? AND ca.status = 'approved'`,
      [offerId, influencerUserId]
    );
    if (!own.length) throw new ApiError(403, 'No approved application for this offer');
    const [r] = await pool.query<DbResult>(
      `INSERT INTO offer_progress (offer_id, influencer_user_id, milestone, status, notes)
       VALUES (?, ?, ?, ?, ?)`,
      [offerId, influencerUserId, payload.milestone, payload.status, payload.notes ?? null]
    );
    return { id: r.insertId, ...payload };
  },

  async getProgress(offerId: number, userId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT * FROM offer_progress
        WHERE offer_id = ? AND influencer_user_id = ?
        ORDER BY created_at ASC`,
      [offerId, userId]
    );
    return rows;
  },
};
