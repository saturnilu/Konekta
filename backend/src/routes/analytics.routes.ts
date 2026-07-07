import { Router } from 'express';
import { analyticsController } from '../controllers/analytics.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/brand', analyticsController.brand);
r.get('/influencer', analyticsController.influencer);
export default r;
