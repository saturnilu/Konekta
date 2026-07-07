// ============================================================
// DESIGN PATTERN: OBSERVER (Behavioral) — EventBus
// Tujuan: Memisahkan concern antara "event terjadi" dengan "respons
// terhadap event". Publisher cukup publish(), semua subscriber (Observer)
// yang tertarik akan otomatis dipanggil secara konkuren.
// Lokasi pemakai:
//   - modules/offers/campaignBuilder.ts (publish 'campaign.created')
//   - modules/offers/campaignState.ts (publish 'campaign.status_changed')
//   - modules/messaging/chat.service.ts (publish 'message.sent')
//   - modules/social/socialMediaFacade.ts (publish 'metrics.synced')
//   - modules/notification/notification.service.ts (subscribe)
//   - modules/analytics/analytics.service.ts (subscribe)
// ============================================================

import { pool } from '../../config/db';

export interface DomainEvent {
  type: string;
  payload: Record<string, any>;
  timestamp: Date;
  metadata?: Record<string, any>;
}

// [OBSERVER PATTERN] — Subscriber callback type
type EventHandler = (event: DomainEvent) => Promise<void> | void;

/**
 * [OBSERVER PATTERN] — EventBus (Subject / Publisher)
 *
 * Singleton — central pub/sub bus. Each module can publish() domain
 * events and subscribe() handlers. Handlers run concurrently with
 * Promise.allSettled (a failure in one handler doesn't break others).
 */
class EventBus {
  private subscribers: Map<string, EventHandler[]> = new Map();

  // [OBSERVER PATTERN] — Observer mendaftarkan dirinya ke event tertentu
  subscribe(eventType: string, handler: EventHandler): void {
    if (!this.subscribers.has(eventType)) {
      this.subscribers.set(eventType, []);
    }
    this.subscribers.get(eventType)!.push(handler);
  }

  // [OBSERVER PATTERN] — unsubscribe handler tertentu
  unsubscribe(eventType: string, handler: EventHandler): void {
    const handlers = this.subscribers.get(eventType);
    if (!handlers) return;
    const idx = handlers.indexOf(handler);
    if (idx !== -1) handlers.splice(idx, 1);
  }

  // [OBSERVER PATTERN] — Publish: trigger SEMUA subscriber yang subscribed
  // ke eventType ini, dijalankan secara paralel (Promise.allSettled).
  async publish(eventType: string, payload: Record<string, any>): Promise<void> {
    const event: DomainEvent = {
      type: eventType,
      payload,
      timestamp: new Date(),
    };

    const handlers = this.subscribers.get(eventType) ?? [];
    const allHandlers: EventHandler[] = [...handlers];

    const wildcardHandlers = this.subscribers.get('*') ?? [];
    allHandlers.push(...wildcardHandlers);

    if (allHandlers.length === 0) return;

    const results = await Promise.allSettled(
      allHandlers.map(async (h) => {
        try {
          await h(event);
        } catch (err) {
          console.error(`[EventBus] handler for ${eventType} failed:`, err);
          throw err;
        }
      })
    );

    const failed = results.filter((r) => r.status === 'rejected');
    if (failed.length) {
      console.warn(`[EventBus] ${failed.length}/${results.length} handlers failed for ${eventType}`);
    }
  }

  // [OBSERVER PATTERN] — Daftar semua subscriber (untuk debugging)
  getSubscribers(eventType: string): number {
    return this.subscribers.get(eventType)?.length ?? 0;
  }

  clear(): void {
    this.subscribers.clear();
  }
}

// [OBSERVER PATTERN] — Singleton instance
export const eventBus = new EventBus();

// ============================================================
// [OBSERVER PATTERN] — Default subscribers (Observers)
// Setiap event type punya beberapa observer yang akan auto-fire.
// Subscribers didefinisikan di sini agar terpusat dan mudah di-maintain.
// ============================================================

// [OBSERVER PATTERN] — notificationSubscriber: kirim notifikasi ke user
eventBus.subscribe('campaign.created', async (event) => {
  const { user_id, title } = event.payload;
  if (!user_id) return;
  await pool.query(
    `INSERT INTO notifications (user_id, type, title, body, icon)
     VALUES (?, 'campaign', ?, ?, 'campaign')`,
    [user_id, 'New Campaign', title ?? 'New campaign available']
  );
});

// [OBSERVER PATTERN] — notificationSubscriber untuk status changes
eventBus.subscribe('campaign.status_changed', async (event) => {
  const { user_id, title, from_state, to_state } = event.payload;
  if (!user_id) return;
  await pool.query(
    `INSERT INTO notifications (user_id, type, title, body, icon)
     VALUES (?, 'status', ?, ?, 'sync')`,
    [user_id, `Campaign ${to_state}`, `${title} transitioned from ${from_state} to ${to_state}`]
  );
});

// [OBSERVER PATTERN] — analyticsSubscriber: track event ke analytics_logs
eventBus.subscribe('*', async (event) => {
  await pool.query(
    `INSERT INTO analytics_logs (event_type, payload, created_at)
     VALUES (?, ?, NOW())`,
    [event.type, JSON.stringify(event.payload)]
  ).catch((err) => {
    // If table doesn't exist, fail silently (analytics is non-critical)
    console.warn('[analyticsSubscriber]', err.message);
  });
});

// [OBSERVER PATTERN] — activityLogSubscriber: audit trail ke activity_logs
eventBus.subscribe('campaign.created', async (event) => {
  const { user_id, offer_id } = event.payload;
  await pool.query(
    `INSERT INTO activity_logs (user_id, action, resource_type, resource_id, created_at)
     VALUES (?, 'create', 'offer', ?, NOW())`,
    [user_id, offer_id]
  ).catch((err) => {
    console.warn('[activityLogSubscriber]', err.message);
  });
});

eventBus.subscribe('campaign.status_changed', async (event) => {
  const { user_id, offer_id, from_state, to_state } = event.payload;
  await pool.query(
    `INSERT INTO activity_logs (user_id, action, resource_type, resource_id, metadata, created_at)
     VALUES (?, 'update_status', 'offer', ?, ?, NOW())`,
    [user_id, offer_id, JSON.stringify({ from: from_state, to: to_state })]
  ).catch((err) => {
    console.warn('[activityLogSubscriber]', err.message);
  });
});

export default eventBus;
