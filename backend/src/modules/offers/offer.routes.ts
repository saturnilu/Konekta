import { Router } from 'express';
import { offerController } from './offer.controller';
import { requireAuth } from '../../core/middlewares/auth';

const r = Router();
r.use(requireAuth);
r.post('/', offerController.create);
r.get('/', offerController.list);
r.get('/:id', offerController.detail);
r.patch('/:id/status', offerController.updateStatus);
export default r;
