// Stub service — subscription tables (subscription_plans, subscriptions) are not yet in the database.
// Returns empty/null data gracefully so the UI can render instead of throwing 500.

export const subscriptionService = {
  async getActivePlans() {
    // TODO: implement when subscription_plans table exists
    return [] as unknown[];
  },
  async getUserPlan(_userId: number) {
    // TODO: implement when subscriptions table exists
    return null;
  },
  async createInvoice(_userId: number, _planId: number) {
    throw new Error('Subscription checkout not yet implemented');
  },
  async verifyInvoicePayment(_invoiceId: number) {
    throw new Error('Payment verification not yet implemented');
  },
  async cancelSubscription(_invoiceId: number) {
    throw new Error('Subscription cancellation not yet implemented');
  },
};
