import { Router } from 'express';
import { videoController } from '../controllers/video.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router({ mergeParams: true }); // mergeParams to get :id from parent

r.use(requireAuth);
r.get('/',                          videoController.list);
r.post('/',                         videoController.submit);
r.post('/:videoId/refresh',         videoController.refresh);
r.get('/brand/:influencerId',               videoController.listForBrand);
r.post('/brand/:influencerId/pay',          videoController.payInfluencer);
r.post('/brand/:influencerId/recalculate',  videoController.recalculateForBrand);

export default r;
