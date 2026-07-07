import { pool, DbRow } from '../config/db';
import { ApiError } from '../utils/apiError';

// Hardcoded plans — no external table needed
export const SUBSCRIPTION_PLANS = [
  {
    plan_id: 1,
    plan_code: 'free',
    plan_name: 'Free',
    price: 0,
    currency: 'IDR',
    duration_months: null,
    description: 'For individuals just getting started',
    features: ['1 active campaign', 'Up to 20 influencer views', 'Basic analytics'],
  },
  {
    plan_id: 2,
    plan_code: 'starter',
    plan_name: 'Starter',
    price: 149000,
    currency: 'IDR',
    duration_months: 1,
    description: 'For growing brands',
    features: ['5 active campaigns', 'Unlimited influencer views', 'Standard analytics', 'In-app chat'],
  },
  {
    plan_id: 3,
    plan_code: 'pro',
    plan_name: 'Pro',
    price: 499000,
    currency: 'IDR',
    duration_months: 1,
    description: 'For professional teams',
    features: ['Unlimited campaigns', 'Priority support', 'Advanced analytics', 'Featured placement'],
  },
  {
    plan_id: 4,
    plan_code: 'enterprise',
    plan_name: 'Enterprise',
    price: 1499000,
    currency: 'IDR',
    duration_months: 12,
    description: 'For large organizations',
    features: ['Everything in Pro', 'Dedicated manager', 'Custom contracts', 'SSO & audit log'],
  },
];

function findPlan(planId?: number, planCode?: string) {
  if (planId) return SUBSCRIPTION_PLANS.find((p) => p.plan_id === planId);
  if (planCode) return SUBSCRIPTION_PLANS.find((p) => p.plan_code === planCode);
  return undefined;
}

export const subscriptionService = {
  getPlans() {
    return SUBSCRIPTION_PLANS;
  },

  async getCurrent(brandUserId: number) {
    const [rows] = await pool.query<DbRow[]>(
      `SELECT id, plan_id, plan_code, plan_name, status, started_at, expires_at
         FROM brand_subscriptions
        WHERE brand_user_id = ? AND status = 'active'
        ORDER BY id DESC
        LIMIT 1`,
      [brandUserId]
    );
    const active = rows[0] as Record<string, unknown> | undefined;
    if (!active) {
      return {
        plan_id: 1,
        plan_name: 'Free',
        plan_code: 'free',
        status: 'active',
        expires_at: null,
        started_at: null,
      };
    }
    return {
      plan_id: active.plan_id ?? 1,
      plan_name: active.plan_name ?? 'Free',
      plan_code: active.plan_code ?? 'free',
      status: active.status ?? 'active',
      expires_at: active.expires_at ?? null,
      started_at: active.started_at ?? null,
    };
  },

  async subscribe(brandUserId: number, planId?: number, planCode?: string) {
    const plan = findPlan(planId, planCode);
    if (!plan) throw new ApiError(400, 'Unknown plan');

    // Cancel any existing active subscription first
    await pool.query(
      `UPDATE brand_subscriptions SET status = 'cancelled', cancelled_at = NOW()
        WHERE brand_user_id = ? AND status = 'active'`,
      [brandUserId]
    );

    const durationDays = plan.duration_months ? plan.duration_months * 30 : null;
    const [r] = await pool.query(
      `INSERT INTO brand_subscriptions
         (brand_user_id, plan_id, plan_code, plan_name, status, started_at, expires_at)
       VALUES (?, ?, ?, ?, 'active', NOW(), ${durationDays ? `DATE_ADD(NOW(), INTERVAL ${durationDays} DAY)` : 'NULL'})`,
      [brandUserId, plan.plan_id, plan.plan_code, plan.plan_name]
    );

    // Mirror plan to brand_profiles.plan column
    const planEnumMap: Record<string, string> = {
      free: 'free',
      starter: 'pro_monthly',
      pro: 'pro_monthly',
      enterprise: 'pro_annual',
    };
    const planEnum = planEnumMap[plan.plan_code] ?? 'free';
    await pool.query(
      `UPDATE brand_profiles SET plan = ? WHERE user_id = ?`,
      [planEnum, brandUserId]
    );

    return {
      id: (r as { insertId: number }).insertId,
      plan_id: plan.plan_id,
      plan_name: plan.plan_name,
      plan_code: plan.plan_code,
      status: 'active',
    };
  },

  async cancel(brandUserId: number) {
    const [r] = await pool.query(
      `UPDATE brand_subscriptions SET status = 'cancelled', cancelled_at = NOW()
        WHERE brand_user_id = ? AND status = 'active'`,
      [brandUserId]
    );
    if (!(r as { affectedRows: number }).affectedRows) {
      throw new ApiError(404, 'No active subscription to cancel');
    }
    await pool.query(`UPDATE brand_profiles SET plan = 'free' WHERE user_id = ?`, [brandUserId]);
    return { cancelled: true };
  },
};
