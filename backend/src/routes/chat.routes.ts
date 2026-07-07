import { Router } from 'express';
import { chatController } from '../controllers/chat.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/', chatController.list);
r.post('/', chatController.create);         // Flutter: POST /conversations { other_user_id }
r.post('/ensure', chatController.ensure);   // Legacy: { brand_user_id, influencer_user_id }
r.get('/:id/messages', chatController.messages);
r.post('/:id/messages', chatController.send);
export default r;
