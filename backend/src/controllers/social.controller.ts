import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { profileService } from '../services/profile.service';
import { pool } from '../config/db';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';

const removeSchema = z.object({ id: z.coerce.number().int().positive() });

export const socialController = {
  async listMine(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Influencers only');
      }
      const [rows] = await pool.query(
        `SELECT id, platform, handle, followers_count, engagement_rate
           FROM social_media_accounts
          WHERE influencer_user_id = ?
          ORDER BY id ASC`,
        [req.user.id]
      );
      return ok(res, rows);
    } catch (e) { next(e); }
  },
  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') {
        throw new ApiError(403, 'Influencers only');
      }
      const { id } = removeSchema.parse(req.params);
      await pool.query(
        `DELETE FROM social_media_accounts WHERE id = ? AND influencer_user_id = ?`,
        [id, req.user.id]
      );
      return ok(res, { id, deleted: true });
    } catch (e) { next(e); }
  },
};

// keep the addSocial flow on profileController — re-export helper
export { profileService };
