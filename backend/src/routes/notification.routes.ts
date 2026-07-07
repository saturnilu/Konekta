import { Router } from 'express';
import { notificationController } from '../controllers/notification.controller';
import { requireAuth } from '../middlewares/auth';

const r = Router();
r.use(requireAuth);
r.get('/', notificationController.list);
r.get('/unread-count', notificationController.unread);
r.post('/read', notificationController.markRead);
r.post('/read-all', notificationController.markAllRead);
r.post('/:id/read', notificationController.markOneRead); // Flutter: POST /notifications/:id/read
export default r;
