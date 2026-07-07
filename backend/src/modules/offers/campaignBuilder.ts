// ============================================================
// DESIGN PATTERN: BUILDER (Creational)
// Tujuan: Memudahkan construction objek Campaign (Offer) yang punya
// 15+ field tanpa constructor panjang. Chainable setXxx() lalu build().
// Lokasi pemakai: services/offer.service.ts, controllers/offer.controller.ts
// ============================================================

import { pool, DbRow, DbResult } from '../../config/db';
import { ApiError } from '../../core/utils/apiError';

export interface CampaignInput {
  brand_user_id: number;
  influencer_user_id: number;
  title: string;
  brief?: string;
  budget: number;
  deliverables?: string;
  requirements?: string;
  deadline?: string;
}

/**
 * [BUILDER PATTERN] — CampaignBuilder
 *
 * Membangun objek Campaign (Offer) yang kompleks secara iteratif.
 * Setiap method setXXX mengembalikan this, sehingga bisa di-chain.
 * build() mengeksekusi INSERT ke DB dan menyimpan hasil ke database.
 */
export class CampaignBuilder {
  private brand_user_id!: number;
  private influencer_user_id!: number;
  private title!: string;
  private brief: string = '';
  private budget!: number;
  private reward_per_creator: number = 0;
  private target_views: number = 0;
  private target_likes: number = 0;
  private target_shares: number = 0;
  private deliverables: string = '';
  private requirements: string = '';
  private target_audience: string = '';
  private deadline: string = '';
  private room_code: string = '';
  private is_public: boolean = true;

  setBrand(userId: number): this {
    this.brand_user_id = userId;
    return this;
  }

  setInfluencer(userId: number): this {
    this.influencer_user_id = userId;
    return this;
  }

  setTitle(t: string): this {
    this.title = t;
    return this;
  }

  setBrief(b: string): this {
    this.brief = b;
    return this;
  }

  setBudget(b: number): this {
    this.budget = b;
    this.reward_per_creator = b;
    return this;
  }

  setRewardPerCreator(r: number): this {
    this.reward_per_creator = r;
    return this;
  }

  setTargets(views?: number, likes?: number, shares?: number): this {
    if (views !== undefined) this.target_views = views;
    if (likes !== undefined) this.target_likes = likes;
    if (shares !== undefined) this.target_shares = shares;
    return this;
  }

  setDeliverables(d: string): this {
    this.deliverables = d;
    return this;
  }

  setRequirements(r: string): this {
    this.requirements = r;
    return this;
  }

  setTargetAudience(t: string): this {
    this.target_audience = t;
    return this;
  }

  setDeadline(d: string): this {
    this.deadline = d;
    return this;
  }

  setRoomCode(c: string): this {
    this.room_code = c;
    return this;
  }

  setPublic(p: boolean): this {
    this.is_public = p;
    return this;
  }

  /**
   * [BUILDER PATTERN] — build()
   * Validates required fields were set, executes INSERT,
   * creates a notification for the influencer, and returns the persisted offer.
   */
  async build() {
    if (!this.brand_user_id) throw new ApiError(400, 'Brand user not set');
    if (!this.title) throw new ApiError(400, 'Title is required');
    if (!this.budget || this.budget <= 0) throw new ApiError(400, 'Valid budget required');

    const [r] = await pool.query<DbResult>(
      `INSERT INTO offers
        (brand_user_id, influencer_user_id, title, brief, budget, reward_per_creator,
         target_views, target_likes, target_shares, deliverables, requirements,
         target_audience, deadline, room_code, status, is_public)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'open', ?)`,
      [
        this.brand_user_id,
        this.influencer_user_id ?? null,
        this.title,
        this.brief || null,
        this.budget,
        this.reward_per_creator,
        this.target_views,
        this.target_likes,
        this.target_shares,
        this.deliverables || null,
        this.requirements || null,
        this.target_audience || null,
        this.deadline || null,
        this.room_code || null,
        this.is_public ? 1 : 0,
      ]
    );

    const offerId = (r as DbResult).insertId;

    if (this.influencer_user_id) {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, body, icon)
         VALUES (?, 'offer', ?, ?, 'mail')`,
        [this.influencer_user_id, 'New offer', this.title]
      );
    }

    const [rows] = await pool.query<DbRow[]>(
      `SELECT o.*, bp.brand_name, bp.logo_url, bp.industry, bp.location AS brand_location,
              ip.username AS influencer_username, u2.name AS influencer_name
       FROM offers o
       JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
       LEFT JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
       LEFT JOIN users u2 ON u2.id = o.influencer_user_id
       WHERE o.id = ?`,
      [offerId]
    );
    return rows[0] ?? null;
  }
}
