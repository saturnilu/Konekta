import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { chatService } from '../services/chat.service';
import { ok, created } from '../utils/response';
import { ApiError } from '../utils/apiError';

const ensureSchema = z.object({
  brand_user_id: z.number().int(),
  influencer_user_id: z.number().int(),
});

// Flutter sends { other_user_id }
const createSchema = z.object({
  other_user_id: z.number().int(),
});

const sendSchema = z.object({ body: z.string().min(1).max(2000) });

export const chatController = {
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = await chatService.listConversations(req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  // POST /conversations — Flutter sends { other_user_id }
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const { other_user_id } = createSchema.parse(req.body);
      const r = await chatService.ensureConversationByOtherUser(req.user.id, other_user_id);
      return ok(res, r);
    } catch (e) { next(e); }
  },

  // POST /conversations/ensure — legacy: { brand_user_id, influencer_user_id }
  async ensure(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const data = ensureSchema.parse(req.body);
      if (data.brand_user_id !== req.user.id && data.influencer_user_id !== req.user.id) {
        throw new ApiError(403, 'You can only start chats you are part of');
      }
      const r = await chatService.ensureConversation(data.brand_user_id, data.influencer_user_id);
      return ok(res, r);
    } catch (e) { next(e); }
  },

  async messages(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const id = Number(req.params.id);
      const data = await chatService.listMessages(id, req.user.id);
      return ok(res, data);
    } catch (e) { next(e); }
  },

  async send(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new ApiError(401, 'Unauthenticated');
      const id = Number(req.params.id);
      const { body } = sendSchema.parse(req.body);
      const m = await chatService.sendMessage(id, req.user.id, body);
      return created(res, m, 'Message sent');
    } catch (e) { next(e); }
  },
};
