import { Request, Response, NextFunction } from 'express';
import { discoveryService, DiscoveryQuery } from '../services/discovery.service';
import { ok } from '../utils/response';
import { ApiError } from '../utils/apiError';

function asNumber(v: unknown): number | undefined {
  if (v === undefined || v === null || v === '') return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

function asBool(v: unknown): boolean | undefined {
  if (v === undefined) return undefined;
  return v === 'true' || v === '1' || v === true;
}

function parseQuery(q: Record<string, unknown>): DiscoveryQuery {
  return {
    q: q.q as string | undefined,
    niche: q.niche as string | undefined,
    industry: q.industry as string | undefined,
    location: q.location as string | undefined,
    platform: q.platform as string | undefined,
    category: q.category as string | undefined,
    min_followers: asNumber(q.min_followers),
    max_followers: asNumber(q.max_followers),
    min_engagement: asNumber(q.min_engagement),
    is_public: asBool(q.is_public),
    page: asNumber(q.page) ?? 1,
    limit: asNumber(q.limit) ?? 20,
  };
}

export const discoveryController = {
  async listInfluencers(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await discoveryService.listInfluencers(parseQuery(req.query));
      return ok(res, data);
    } catch (e) { next(e); }
  },
  async listBrands(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await discoveryService.listBrands(parseQuery(req.query));
      return ok(res, data);
    } catch (e) { next(e); }
  },
  async getInfluencer(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const data = await discoveryService.getInfluencer(id);
      if (!data) throw new ApiError(404, 'Influencer not found');
      return ok(res, data);
    } catch (e) { next(e); }
  },
  async getBrand(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      if (!Number.isFinite(id)) throw new ApiError(400, 'Invalid id');
      const data = await discoveryService.getBrand(id);
      if (!data) throw new ApiError(404, 'Brand not found');
      return ok(res, data);
    } catch (e) { next(e); }
  },
};
