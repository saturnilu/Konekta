import { Router } from 'express';
import { socialController } from '../controllers/social.controller';
import { profileController } from '../controllers/profile.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/mine', socialController.listMine);
r.delete('/mine/:id', socialController.remove);
r.post('/mine', profileController.addSocial);
export default r;
