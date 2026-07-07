import { Response } from 'express';

export const ok = (res: Response, data: unknown, message = 'OK') =>
  res.json({ success: true, message, data });

export const created = (res: Response, data: unknown, message = 'Created') =>
  res.status(201).json({ success: true, message, data });
