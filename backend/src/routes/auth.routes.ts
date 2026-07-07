import { Router } from 'express';
import { authController } from '../controllers/auth.controller';

const r = Router();
r.post('/register', authController.register);
r.post('/login', authController.login);
r.post('/logout', authController.logout);
r.post('/forgot-password', authController.forgot);
export default r;
