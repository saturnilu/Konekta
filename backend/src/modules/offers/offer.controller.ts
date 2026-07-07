// ============================================================
// CONTROLLER INI endpoint-nya menggunakan beberapa DESIGN PATTERN:
//   - BUILDER: saat membuat offer, data diteruskan ke offerService
//     yang bisa di-refactor memakai CampaignBuilder (lihat
//     services/campaignBuilder.ts).
//   - STATE: endpoint updateStatus idealnya delegasi ke
//     CampaignStateMachine.transition() (services/campaignState.ts)
//     untuk validasi transisi + trigger event Observer.
//   - FACADE: jika endpoint terkait publish/sync ke platform,
//     panggil SocialMediaFacade (services/socialMediaFacade.ts).
// ============================================================

import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { offerService } from './offer.service';
import { ok, created } from '../../core/utils/response';
import { ApiError } from '../../core/utils/apiError';

const createSchema = z.object({
  influencer_user_id: z.number().int().positive(),
  title: z.string().min(2).max(180),
  brief: z.string().max(2000).optional(),
  budget: z.number().nonnegative(),
  reward_per_creator: z.number().nonnegative().optional(),
  target_views: z.number().int().nonnegative().optional(),
  target_likes: z.number().int().nonnegative().optional(),
  target_shares: z.number().int().nonnegative().optional(),
  deliverables: z.string().max(2000).optional(),
  requirements: z.string().max(2000).optional(),
  target_audience: z.string().max(255).optional(),
  deadline: z.string().optional(),
  room_code: z.string().max(40).optional(),
  is_public: z.boolean().optional(),
});

const statusSchema = z.object({ status: z.string() });

export const offerController = {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands can create offers');
      }
      const body = createSchema.parse(req.body);
      const data = await offerService.create({ ...body, brand_user_id: req.user.id });
      return created(res, data, 'Offer created');
    } catch (e) { next(e); }
  },
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = await offerService.list(req.user.id, req.user.role);
      return ok(res, { items: data });
    } catch (e) { next(e); }
  },
  async detail(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const data = await offerService.getById(id);
      if (!data) throw new ApiError(404, 'Offer not found');
      return ok(res, data);
    } catch (e) { next(e); }
  },
  async updateStatus(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const { status } = statusSchema.parse(req.body);
      const data = await offerService.updateStatus(id, req.user.id, status);
      return ok(res, data, 'Status updated');
    } catch (e) { next(e); }
  },
};
