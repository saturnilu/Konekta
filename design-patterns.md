# Design Patterns — Konekta Backend

This document explains every design pattern applied in the backend — **which file** uses it, **why** it was chosen, and **how** it works.

---

## Backend File Structure

```
backend/src/
├── app.ts
├── server.ts
├── config/
│   └── db.ts
├── controllers/
│   ├── auth.controller.ts
│   ├── chat.controller.ts
│   ├── dashboard.controller.ts
│   ├── discovery.controller.ts
│   ├── notification.controller.ts
│   ├── offer.controller.ts        ← uses Builder + Observer
│   └── profile.controller.ts
├── routes/
│   └── ...
├── middlewares/
│   └── ...
├── utils/
│   └── ...
└── services/
    ├── campaignBuilder.ts         ← BUILDER PATTERN
    ├── campaignState.ts           ← STATE PATTERN
    ├── socialMediaAdapters.ts     ← ADAPTER PATTERN
    ├── socialMediaFacade.ts       ← FACADE PATTERN
    ├── eventBus.ts                ← OBSERVER PATTERN
    ├── offer.service.ts           ← uses Builder + Observer
    ├── notification.service.ts    ← uses Observer
    └── ...
```

---

## 1. Creational — Builder Pattern

**File:** `backend/src/services/campaignBuilder.ts`

**Used in:** `offer.controller.ts` (create endpoint)

### Purpose
Build a Campaign (Offer) object that has 15+ properties in a structured and chainable way, without a long and error-prone constructor.

### How It Works
```typescript
const campaign = await new CampaignBuilder()
  .setBrand(brandUserId)
  .setInfluencer(influencerUserId)
  .setTitle('Summer Launch')
  .setBudget(50000)
  .setTargets(50000, 5000, 200)
  .setDeliverables('1 TikTok + 1 IG Story')
  .setDeadline('2025-07-01')
  .build();
```

- Each `setXxx()` method returns `this` (the builder instance), enabling method chaining.
- `build()` performs final validation, executes the INSERT, and sends a notification to the influencer.
- Optional properties have default values; required properties must be set before calling `build()`.

### Why Builder?
- An Offer has 15+ fields. A constructor with 15 parameters is unreadable.
- Builder allows partial configuration — developers only set the fields they need.
- Validation is handled in one place (`build()`), not scattered across the service layer.

---

## 2. Structural — Adapter Pattern

**File:** `backend/src/services/socialMediaAdapters.ts`

**Used in:** `socialMediaFacade.ts`, `dashboard.service.ts` (analytics)

### Purpose
Normalize the APIs of various social media platforms (TikTok, Instagram, YouTube), which each have different endpoints, authentication, and response formats, into a single unified interface (`ISocialMediaAdapter`).

### Unified Interface
```typescript
export interface ISocialMediaAdapter {
  getMetrics(postId: string): Promise<SocialMediaMetrics>;
  publish(content: PostContent): Promise<PostContent>;
  fetchCampaignReport(offerId: number): Promise<PlatformReport>;
}
```

### Adapter per Platform

| Adapter | File | API Adapted |
|---------|------|-------------|
| `TikTokAdapter` | socialMediaAdapters.ts | TikTok Marketing API (`open.tiktokapis.com`) |
| `InstagramAdapter` | socialMediaAdapters.ts | Instagram Graph API (`graph.facebook.com`) |
| `YouTubeAdapter` | socialMediaAdapters.ts | YouTube Data API (`youtube.googleapis.com`) |

### Why Adapter?
- TikTok API uses OAuth2 bearer token + `/v2/post/public/list/`
- Instagram Graph API uses Page Access Token + `/v18.0/{media-id}`
- YouTube Data API uses API Key + `/v3/videos?part=statistics`
- Each has a different response format. The Adapter hides all these differences behind one interface.
- Adding a new platform (Twitter, Facebook) only requires creating a new class that implements `ISocialMediaAdapter`, without modifying existing code.

---

## 3. Structural — Facade Pattern

**File:** `backend/src/services/socialMediaFacade.ts`

**Used in:** `offer.controller.ts`, `dashboard.service.ts`

### Purpose
Simplify access to multiple TikTok, Instagram, and YouTube services into a single simple interface. Developers don't need to know which adapter is active, how to instantiate it, or how to combine results from multiple platforms.

### Facade Methods
```typescript
const facade = new SocialMediaFacade();

// Single call → get a combined report from all platforms
const summary = await facade.getCampaignSummary(offerId);
// { platforms: [reportTikTok, reportIG], combined: { totalViews: 100000, ... } }

// Single call → publish to a specific platform
await facade.publishPost('tiktok', userId, { url: 'video.mp4' });

// Single call → sync metrics from all platforms to DB
await facade.syncMetrics(offerId);
```

### Why Facade?
- Without facade: the controller/service needs to know about `TikTokAdapter` and `InstagramAdapter`, instantiate each manually, loop through them, and merge the results.
- With facade: just call `getCampaignSummary(offerId)` — the facade handles finding all connected platforms, calling the appropriate adapter, and merging the results.
- Facade = a "front desk" that handles all complexity behind the scenes.

---

## 4. Behavioral — Observer Pattern

**File:** `backend/src/services/eventBus.ts`

**Used in:** `offer.service.ts`, `campaignState.ts`, `socialMediaFacade.ts`, `notification.service.ts`

### Purpose
Decouple the concern of "an event occurred" from "the response to that event." No need to hardcode `notify()` calls in every service. The same event can trigger multiple automatic responses (notification + analytics + activity log).

### EventBus (Subject/Publisher)
```typescript
const eventBus = new EventBus();

// Publish an event
await eventBus.publish('campaign.status_changed', {
  offer_id: 1,
  user_id: 5,
  title: 'Campaign Status Changed',
});
```

### 3 Subscribers (Observers)
Each event type has multiple observers that run **concurrently**:

| Subscriber | File | Purpose |
|------------|------|---------|
| `notificationSubscriber` | eventBus.ts | Creates an entry in the `notifications` table |
| `analyticsSubscriber` | eventBus.ts | Tracks performance in `analytics_logs` |
| `activityLogSubscriber` | eventBus.ts | Audit trail in `activity_logs` |

### Supported Event Types

| Event | Triggered In | Subscribers |
|-------|--------------|-------------|
| `campaign.created` | `campaignBuilder.ts` → `build()` | notify, analytics, log |
| `campaign.status_changed` | `campaignState.ts` → `transition()` | notify, log |
| `campaign.completed` | `campaignState.ts` → `transition()` | notify, analytics, log |
| `campaign.cancelled` | `campaignState.ts` → `transition()` | notify, log |
| `campaign.rejected` | `campaignState.ts` → `transition()` | notify, log |
| `application.approved` | `campaignState.ts` → `transition()` | notify, log |
| `application.rejected` | `campaignState.ts` → `transition()` | notify, log |
| `metrics.synced` | `socialMediaFacade.ts` → `syncMetrics()` | analytics |
| `message.sent` | `chat.service.ts` (upcoming) | log |

### Why Observer?
- **Without Observer:** Every service must directly call `notificationService.create()`, `analyticsService.track()`, `activityLog.create()` — hardcoded, duplicated code, hard to maintain.
- **With Observer:** The service only calls `await eventBus.publish('event.name', payload)`. All subscribers are automatically triggered. Adding a new subscriber only requires subscribing — no changes to existing code.
- `Promise.allSettled` ensures that an error in one subscriber doesn't affect the others.

### Before vs After in offer.service.ts

**Before (hardcoded):**
```typescript
// In offerService.updateStatus():
await pool.query('UPDATE offers SET status = ? WHERE id = ?', [status, id]);
// Hardcoded notification → must be copy-pasted in every service that updates status
await pool.query(`INSERT INTO notifications ...`, [notifyUser, 'Status updated', ...]);
```

**After (Observer):**
```typescript
// In campaignState.ts transition():
await pool.query('UPDATE offers SET status = ? WHERE id = ?', [toState, offerId]);

// Publish event → all subscribers are automatically triggered
await eventBus.publish('campaign.status_changed', {
  offer_id,
  user_id: userId,
  title: offer.title,
  from_state: fromState,
  to_state: toState,
});
```

---

## 5. Behavioral — State Pattern

**File:** `backend/src/services/campaignState.ts`

**Used in:** `offer.controller.ts` (updateStatus endpoint), `offer.service.ts`

### Purpose
Encapsulate all Campaign (Offer) and Application status transition rules into state objects, rather than scattered if-else or switch-case statements. Each state knows which transitions are valid from it.

### Campaign (Offer) State Machine

```
draft → open → offered → negotiation → accepted → in_progress → submitted → completed
  │       │       │          │            │
  └───────┼───────┼──────────┼────────────┼── rejected
          │       │          │            │
          └───────┴──────────┴────────────┼── cancelled
                                         │
                                         └── (all states can transition to → cancelled)
```

| State | Valid Transitions | Notes |
|-------|-------------------|-------|
| `draft` | open, rejected, cancelled | Not yet published |
| `open` | offered, rejected, cancelled | Active, can be accepted by influencer |
| `offered` | negotiation, accepted, rejected, cancelled | Influencer accepts/rejects |
| `negotiation` | accepted, rejected, cancelled | Negotiating budget/deliverables |
| `accepted` | in_progress, rejected, cancelled | Contract agreed |
| `in_progress` | submitted, cancelled | Influencer is creating content |
| `submitted` | completed, rejected | Content submitted, brand reviewing |
| `completed` | *(none)* | Terminal — campaign finished |
| `rejected` | *(none)* | Terminal — rejected |
| `cancelled` | *(none)* | Terminal |

### Application State Machine

```
pending → approved → completed
     │         │
     │         └── (can → rejected)
     └───────────── (can → rejected directly from pending)
```

| State | Valid Transitions |
|-------|-------------------|
| `pending` | approved, rejected |
| `approved` | completed, rejected |
| `rejected` | *(none)* |
| `completed` | *(none)* |

### How It Works
```typescript
const campaignState = new CampaignStateMachine();

// Validate → the state machine decides
const isValid = campaignState.isValidTransition('in_progress', 'completed');
// false → cannot skip submitted → completed

// Execute transition
const result = await campaignState.transition(offerId, userId, 'in_progress', 'submitted');
// result.success === true
// DB automatically updates status
// Notification automatically sent to influencer/brand
```

### Why State Pattern?
- **Without State Pattern:** Every service has hardcoded `if (!allowed.includes(status))`, validation spread across controllers, services, and migrations — hard to add new states.
- **With State Pattern:** All transition rules are encapsulated in `CampaignStates`. Adding a new state = adding an entry to `CampaignStates`, no changes to existing code (Open/Closed Principle).
- The `onEnter` hook enables automatic logic execution when a state changes (e.g., when `in_progress` activates, trigger analytics tracking).
- `ApplicationStateMachine` follows the same pattern for `campaign_applicants`.

---

## Pattern Summary & Locations

| Pattern | Category | File | Used By |
|---------|----------|------|---------|
| **Builder** | Creational | `services/campaignBuilder.ts` | `offer.controller.ts` (create) |
| **Adapter** | Structural | `services/socialMediaAdapters.ts` | `socialMediaFacade.ts`, `dashboard.service.ts` |
| **Facade** | Structural | `services/socialMediaFacade.ts` | `offer.controller.ts`, `dashboard.service.ts` |
| **Observer** | Behavioral | `services/eventBus.ts` | `offer.service.ts`, `campaignState.ts`, `socialMediaFacade.ts` |
| **State** | Behavioral | `services/campaignState.ts` | `offer.controller.ts`, `offer.service.ts` |

---

## Dependency Graph

```
               ┌──────────────┐
               │  eventBus.ts │  ← Observer (all events pass through here)
               └──────┬───────┘
                      │ publish
        ┌─────────────┼──────────────┐
        ▼             ▼              ▼
  notification    analytics      activity
  subscriber     subscriber      subscriber
        │             │              │
        └──────┬──────┴──────┬───────┘
               ▼             ▼
          notifications   analytics_    activity_
          (table)         logs (table)  logs (table)


          ┌─────────────────────┐
          │   campaignState.ts  │  ← State Pattern
          │  (CampaignStateMachine)
          │  (ApplicationStateMachine)
          └──────────┬──────────┘
                     │ transition()
                     │ publish('campaign.status_changed')
                     ▼
                ┌────────────┐
                │ eventBus.ts│  ← Observer (triggered by state)
                └────────────┘


          ┌─────────────────────────┐
          │ socialMediaAdapters.ts  │  ← Adapter Pattern
          │  TikTokAdapter          │
          │  InstagramAdapter       │
          │  YouTubeAdapter         │
          └──────────┬──────────────┘
                     │ all implement ISocialMediaAdapter
                     ▼
          ┌─────────────────────────┐
          │  socialMediaFacade.ts   │  ← Facade Pattern
          │  (SocialMediaFacade)    │
          │  getCampaignSummary()   │
          │  syncMetrics()          │
          │  publishPost()          │
          └──────────┬──────────────┘
                     │ calls the appropriate adapter
                     ▼
          socialMediaAdapters.ts


          ┌─────────────────────────┐
          │   campaignBuilder.ts    │  ← Builder Pattern
          │   CampaignBuilder       │
          │                         │
          │   new CampaignBuilder() │
          │     .setBrand(x)        │
          │     .setTitle(y)        │
          │     .setBudget(z)       │
          │     .build()            │
          └─────────────────────────┘
```