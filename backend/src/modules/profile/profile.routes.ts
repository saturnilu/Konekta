import { Router } from 'express';
import { profileController } from './profile.controller';
import { requireAuth } from '../../core/middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/me', profileController.me);
r.put('/me', profileController.update);
r.put('/brand', profileController.updateBrand);
r.post('/influencer/social-media', profileController.addSocial);
export default r;
