import { Request, Response, NextFunction } from 'express';
import { subscriptionService } from './subscription.service';
import { ApiError } from '../../utils/apiError';
import { ok } from '../../core/utils/response';

export const subscriptionController = {
  async getPlans(req: Request, res: Response, next: NextFunction) {
    try {
      const plans = await subscriptionService.getActivePlans();
      return ok(res, plans);
    } catch (error) {
      next(new ApiError(500, 'Subscription plans require database setup'));
    }
  },

  async getUserPlan(req: Request, res: Response, next: NextFunction) {
    try {
      if (!(req as any).user) throw new ApiError(401, 'Unauthenticated');
      const userId = (req as any).user.id;
      const plan = await subscriptionService.getUserPlan(userId);
      return ok(res, plan ?? null);
    } catch (error) {
      if (error instanceof ApiError) return next(error);
      next(new ApiError(500, 'Subscription plan requires database setup'));
    }
  },

  async createInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      if (!(req as any).user) throw new ApiError(401, 'Unauthenticated');
      const { planId } = req.body;
      if (!planId) throw new ApiError(400, 'planId is required');
      const invoice = await subscriptionService.createInvoice((req as any).user.id, Number(planId));
      return ok(res, invoice, 'Invoice created');
    } catch (error) {
      if (error instanceof ApiError) return next(error);
      next(new ApiError(500, 'Invoice creation requires database setup'));
    }
  },

  async verifyPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const invoiceId = Number(req.query.invoiceId);
      if (!invoiceId || isNaN(invoiceId)) throw new ApiError(400, 'invoiceId is required');
      const result = await subscriptionService.verifyInvoicePayment(invoiceId);
      return ok(res, result);
    } catch (error) {
      if (error instanceof ApiError) return next(error);
      next(new ApiError(500, 'Payment verification requires database setup'));
    }
  },

  async cancelSubscription(req: Request, res: Response, next: NextFunction) {
    try {
      if (!(req as any).user) throw new ApiError(401, 'Unauthenticated');
      const invoiceId = Number(req.query.invoiceId);
      if (!invoiceId || isNaN(invoiceId)) throw new ApiError(400, 'invoiceId is required');
      await subscriptionService.cancelSubscription(invoiceId);
      return ok(res, null, 'Subscription cancelled');
    } catch (error) {
      if (error instanceof ApiError) return next(error);
      next(new ApiError(500, 'Cancellation requires database setup'));
    }
  },
};
