import { Request, Response, NextFunction } from 'express';
import { subscriptionService } from '../services/subscription.service';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';

export const subscriptionController = {
  async plans(_req: Request, res: Response, next: NextFunction) {
    try {
      return ok(res, subscriptionService.getPlans());
    } catch (e) { next(e); }
  },

  // GET /subscriptions/me  — Flutter calls this path
  async me(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthorized');
      const data = await subscriptionService.getCurrent(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  // GET /subscriptions/mine  — legacy alias
  async mine(req: Request, res: Response, next: NextFunction) {
    return subscriptionController.me(req, res, next);
  },

  // POST /subscriptions/subscribe — Flutter sends { plan_id: int }
  async subscribe(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthorized');
      const planId = req.body?.plan_id ? Number(req.body.plan_id) : undefined;
      const planCode = req.body?.plan_code ? String(req.body.plan_code) : undefined;
      if (!planId && !planCode) throw new ApiError(400, 'plan_id or plan_code is required');
      const data = await subscriptionService.subscribe(req.user.id, planId, planCode);
      return ok(res, data, 'Subscribed');
    } catch (e) { next(e); }
  },

  // POST /subscriptions/cancel
  async cancel(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthorized');
      const data = await subscriptionService.cancel(req.user.id);
      return ok(res, data, 'Cancelled');
    } catch (e) { next(e); }
  },
};

export const influencerSubscriptionController = {
  async me(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') throw new ApiError(403, 'Influencers only');
      const data = await subscriptionService.getCurrent(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async subscribe(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') throw new ApiError(403, 'Influencers only');
      const planId = req.body?.plan_id ? Number(req.body.plan_id) : undefined;
      const planCode = req.body?.plan_code ? String(req.body.plan_code) : undefined;
      if (!planId && !planCode) throw new ApiError(400, 'plan_id or plan_code is required');
      const data = await subscriptionService.subscribe(req.user.id, planId, planCode);
      return ok(res, data, 'Subscribed');
    } catch (e) { next(e); }
  },

  async cancel(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user || req.user.role !== 'influencer') throw new ApiError(403, 'Influencers only');
      const data = await subscriptionService.cancel(req.user.id);
      return ok(res, data, 'Cancelled');
    } catch (e) { next(e); }
  },
};