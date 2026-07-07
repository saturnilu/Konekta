import { Router } from 'express';
import { dashboardController } from '../controllers/dashboard.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/overview', dashboardController.overview);
r.get('/influencer', dashboardController.influencer);
r.get('/brand', dashboardController.brand);
export default r;
