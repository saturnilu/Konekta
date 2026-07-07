import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { pool, DbRow } from '../config/db';
import { offerService } from '../services/offer.service';
import { ok, created } from '../utils/response';
import { ApiError } from '../utils/apiError';

const createSchema = z.object({
  title: z.string().min(2).max(160),
  brief: z.string().max(2000).optional(),
  budget: z.number().positive(),
  reward_per_creator: z.number().nonnegative().optional(),
  max_creators: z.number().int().nonnegative().optional(),
  target_views: z.number().int().nonnegative().optional(),
  target_likes: z.number().int().nonnegative().optional(),
  target_shares: z.number().int().nonnegative().optional(),
  deliverables: z.string().max(2000).optional(),
  requirements: z.string().max(2000).optional(),
  target_audience: z.string().max(255).optional(),
  deadline: z.string().max(40).optional(),
  is_public: z.boolean().optional(),
});

const applySchema = z.object({
  message: z.string().max(1000).optional(),
  proposed_rate: z.number().nonnegative().optional(),
});

const progressSchema = z.object({
  milestone: z.string().min(1).max(120),
  status: z.string().min(1).max(40),
  notes: z.string().max(1000).optional(),
});

const setStatusSchema = z.object({
  status: z.enum(['approved', 'rejected', 'shortlisted']),
});

export const offerController = {
  async listPublic(req: Request, res: Response, next: NextFunction) {
    try {
      const role = req.query.role as string;
      const status = req.query.status as string;
      const page = Math.max(1, Number(req.query.page) || 1);
      const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
      const offset = (page - 1) * limit;

      const whereClauses: string[] = [];
      const params: (string | number)[] = [];

      if (role === 'brand') {
        whereClauses.push('o.brand_user_id = ?');
        params.push(req.user?.id ?? 0);
      } else if (role === 'influencer') {
        // For influencer browsing public open offers
        whereClauses.push('o.is_public = 1');
        if (!status || status.trim() === '') {
          // Show both open and in_progress offers (brands may still accept applicants)
          whereClauses.push("o.status IN ('open', 'in_progress')");
        }
      }

      if (status && status.trim() !== '') {
        whereClauses.push('o.status = ?');
        params.push(status);
      }

      const where = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

      const influencerId = req.user?.role === 'influencer' ? (req.user?.id ?? 0) : 0;

      const [rows] = await pool.query<DbRow[]>(
        `SELECT o.*, bp.brand_name, bp.logo_url,
                ip.username AS influencer_username, u2.name AS influencer_name,
                (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id) AS applicants_count,
                (SELECT COUNT(*) FROM campaign_applicants ca WHERE ca.offer_id = o.id AND ca.status IN ('approved','completed')) AS approved_count,
                DATEDIFF(o.deadline, CURDATE()) AS days_left,
                (SELECT ca2.status FROM campaign_applicants ca2
                  WHERE ca2.offer_id = o.id AND ca2.influencer_user_id = ?) AS application_status
         FROM offers o
         JOIN brand_profiles bp ON bp.user_id = o.brand_user_id
         LEFT JOIN influencer_profiles ip ON ip.user_id = o.influencer_user_id
         LEFT JOIN users u2 ON u2.id = o.influencer_user_id
         ${where}
         ORDER BY o.created_at DESC
         LIMIT ? OFFSET ?`,
        [influencerId, ...params, limit, offset]
      );
      return ok(res, rows);
    } catch (e) { next(e); }
  },

  async listMine(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = req.user.role === 'brand'
        ? await offerService.listForBrand(req.user.id)
        : await offerService.listForInfluencer(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async create(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands can create offers');
      }
      const data = createSchema.parse(req.body);
      const result = await offerService.create(req.user.id, data);
      return created(res, result, 'Offer created');
    } catch (e) { next(e); }
  },

  async detail(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const data = await offerService.getById(id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async update(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') throw new ApiError(403, 'Only brands');
      const id = Number(req.params.id);
      const data = await offerService.update(id, req.user.id, req.body);
      return ok(res, data, 'Offer updated');
    } catch (e) { next(e); }
  },

  async listApplicants(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') throw new ApiError(403, 'Only brands');
      const offerId = Number(req.params.id);
      const items = await offerService.listApplicants(offerId, req.user.id);
      return ok(res, items);
    } catch (e) { next(e); }
  },

  async getApplicant(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') throw new ApiError(403, 'Only brands');
      const offerId = Number(req.params.id);
      const appId = Number(req.params.appId);
      const data = await offerService.getApplicant(offerId, appId, req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async setApplicationStatus(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') throw new ApiError(403, 'Only brands');
      const offerId = Number(req.params.id);
      const appId = Number(req.params.appId);
      const { status } = setStatusSchema.parse(req.body);
      const data = await offerService.setApplicationStatus(offerId, appId, req.user.id, status);
      return ok(res, data, 'Application updated');
    } catch (e) { next(e); }
  },

  // POST /offers/:id/apply  AND  POST /offers/:id/applicants (Flutter path)
  async apply(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers can apply');
      }
      const offerId = Number(req.params.id);
      const data = applySchema.parse(req.body);
      const r = await offerService.apply(offerId, req.user.id, data);
      return created(res, r, 'Application submitted');
    } catch (e) { next(e); }
  },

  async myApplications(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers');
      }
      const items = await offerService.myApplications(req.user.id);
      return ok(res, items);
    } catch (e) { next(e); }
  },

  async addProgress(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const offerId = Number(req.params.id);
      const data = progressSchema.parse(req.body);
      const r = await offerService.addProgress(offerId, req.user.id, data);
      return created(res, r, 'Progress added');
    } catch (e) { next(e); }
  },

  async getProgress(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const offerId = Number(req.params.id);
      const items = await offerService.getProgress(offerId, req.user.id);
      return ok(res, items);
    } catch (e) { next(e); }
  },
};