import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { profileService } from './profile.service';
import { ok, created } from '../../core/utils/response';
import { ApiError } from '../../core/utils/apiError';

const socialSchema = z.object({
  platform: z.enum(['instagram','tiktok','youtube','twitter','facebook','other']),
  handle: z.string().min(1).max(120),
  followers_count: z.number().int().nonnegative().optional(),
  engagement_rate: z.number().nonnegative().optional(),
});

export const profileController = {
  async me(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = await profileService.getMe(req.user.id, req.user.role);
      return ok(res, data);
    } catch (e) { next(e); }
  },
  async update(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = await profileService.updateMe(req.user.id, req.user.role, req.body);
      return ok(res, data, 'Profile updated');
    } catch (e) { next(e); }
  },
  async addSocial(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Only influencers can add social media');
      }
      const body = socialSchema.parse(req.body);
      const data = await profileService.addSocialMedia(req.user.id, body);
      return created(res, data, 'Social media added');
    } catch (e) { next(e); }
  },
  async updateBrand(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'brand') {
        throw new ApiError(403, 'Only brands can update brand details');
      }
      const data = await profileService.updateMe(req.user.id, 'brand', req.body);
      return ok(res, data, 'Brand profile updated');
    } catch (e) { next(e); }
  },
};
