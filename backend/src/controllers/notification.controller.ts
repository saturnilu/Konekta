import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { notificationService } from '../services/notification.service';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';

export const notificationController = {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = await notificationService.list(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async unread(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const n = await notificationService.unreadCount(req.user.id);
      return ok(res, { count: n });
    } catch (e) { next(e); }
  },

  // POST /notifications/read — body: { ids: [] }
  async markRead(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const { ids } = z.object({ ids: z.array(z.number().int()) }).parse(req.body);
      const r = await notificationService.markRead(req.user.id, ids);
      return ok(res, r, 'Marked as read');
    } catch (e) { next(e); }
  },

  // POST /notifications/:id/read — Flutter pattern
  async markOneRead(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const r = await notificationService.markOneRead(req.user.id, id);
      return ok(res, r, 'Marked as read');
    } catch (e) { next(e); }
  },

  async markAllRead(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const r = await notificationService.markAllRead(req.user.id);
      return ok(res, r, 'All marked as read');
    } catch (e) { next(e); }
  },
};
