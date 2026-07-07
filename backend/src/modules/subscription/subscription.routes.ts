import { Router } from 'express';
import { subscriptionController } from './subscription.controller';
import { requireAuth } from '../../middlewares/auth';

const r = Router();
r.get('/plans', subscriptionController.getPlans);
r.use(requireAuth);
r.get('/me', subscriptionController.getUserPlan);
r.post('/checkout', subscriptionController.createInvoice);
r.post('/cancel', subscriptionController.cancelSubscription);
export default r;
