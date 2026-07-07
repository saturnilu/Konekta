import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { ApiError } from '../utils/apiError';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
) {
  if (err instanceof ZodError) {
    const firstError = err.issues[0];
    const detail = firstError
      ? `${firstError.path.join('.') || 'field'}: ${firstError.message}`
      : 'Validation error';
    return res.status(400).json({
      success: false,
      message: detail,
      errors: err.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    });
  }

  if (err instanceof ApiError) {
    return res.status(err.status).json({ success: false, message: err.message });
  }

  // Only log & expose details in non-production
  const isProd = process.env.NODE_ENV === 'production';
  if (!isProd) {
    console.error('[unhandled]', err);
  }

  return res.status(500).json({
    success: false,
    message: 'Internal server error',
    ...(isProd ? {} : { detail: err instanceof Error ? err.message : String(err) }),
  });
}
