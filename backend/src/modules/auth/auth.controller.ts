import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { authService } from './auth.service';
import { ok, created } from '../../core/utils/response';

const registerSchema = z.object({
  name: z.string().min(2).max(120),
  email: z.string().email(),
  password: z.string().min(6).max(120),
  role: z.enum(['influencer', 'brand']),
  username: z.string().min(2).max(80).optional(),
  brand_name: z.string().min(2).max(120).optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const authController = {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const data = registerSchema.parse(req.body);
      const result = await authService.register(data);
      return created(res, result, 'Account created');
    } catch (e) {
      next(e);
    }
  },
  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const data = loginSchema.parse(req.body);
      const result = await authService.login(data.email, data.password);
      return ok(res, result, 'Logged in');
    } catch (e) {
      next(e);
    }
  },
  async logout(_req: Request, res: Response) {
    // JWT is stateless — client just drops the token
    return ok(res, null, 'Logged out');
  },
  async forgot(req: Request, res: Response, next: NextFunction) {
    try {
      const { email } = z.object({ email: z.string().email() }).parse(req.body);
      const result = await authService.forgotPassword(email);
      return ok(res, result, 'If the email exists, a reset link has been sent');
    } catch (e) {
      next(e);
    }
  },
};
