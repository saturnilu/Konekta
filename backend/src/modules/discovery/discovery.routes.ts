import { Router } from 'express';
import { discoveryController } from './discovery.controller';

const r = Router();
r.get('/influencers', discoveryController.listInfluencers);
r.get('/brands', discoveryController.listBrands);
r.get('/influencers/:id', discoveryController.getInfluencer);
r.get('/brands/:id', discoveryController.getBrand);
export default r;
