import { Router } from 'express';
import {
  googleAuth,
  googleAuthMobile,
  googleCallback,
  googleExchange,
} from './googleAuth.controller';

const r = Router();

r.get('/google', googleAuth);
r.get('/google/callback', googleCallback);
r.post('/google/mobile', googleAuthMobile);
r.post('/google/exchange', googleExchange);

export default r;
