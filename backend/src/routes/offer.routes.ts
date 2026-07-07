import { Router } from 'express';
import { offerController } from '../controllers/offer.controller';
import { requireAuth } from '../middlewares/auth';
import videoRoutes from './video.routes';

const r = Router();

// Public listing of open offers (for Explore screens)
r.get('/', offerController.listPublic);

// List current user's offers (brand-owned or influencer-applied)
r.get('/mine', requireAuth, offerController.listMine);
r.get('/applications/mine', requireAuth, offerController.myApplications);

// Brand side
r.post('/', requireAuth, offerController.create);
r.get('/:id', offerController.detail); // public
r.put('/:id', requireAuth, offerController.update);
r.get('/:id/applicants', requireAuth, offerController.listApplicants);
r.get('/:id/applicants/:appId', requireAuth, offerController.getApplicant);
r.patch('/:id/applicants/:appId/status', requireAuth, offerController.setApplicationStatus);

// Influencer side — both /apply and /applicants (Flutter sends POST /offers/:id/applicants)
r.post('/:id/apply', requireAuth, offerController.apply);
r.post('/:id/applicants', requireAuth, offerController.apply);

// Progress
r.post('/:id/progress', requireAuth, offerController.addProgress);
r.get('/:id/progress', requireAuth, offerController.getProgress);

// Video submissions — nested under /:id so mergeParams works correctly
r.use('/:id/videos', videoRoutes);

export default r;
