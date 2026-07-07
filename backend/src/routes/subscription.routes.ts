import { Router } from 'express';
import { subscriptionController } from '../controllers/subscription.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.get('/plans', subscriptionController.plans);
r.get('/me', requireAuth, subscriptionController.me);       // Flutter calls /me
r.get('/mine', requireAuth, subscriptionController.mine);   // legacy alias
r.post('/subscribe', requireAuth, subscriptionController.subscribe);
r.post('/cancel', requireAuth, subscriptionController.cancel);
export default r;
