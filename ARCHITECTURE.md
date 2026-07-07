# Konekta — Architecture Document

## 1. Overview

Konekta is a two-sided mobile platform that connects **influencers** and **brands** for endorsement campaigns. It consists of:

| Layer        | Technology                       |
| ------------ | -------------------------------- |
| **Mobile**   | Flutter (Dart)                   |
| **Backend**  | Express.js (TypeScript)          |
| **Database** | MySQL 8.0+                       |

---

## 2. Architecture Decision: Monolith vs Micro-service

**Chosen: Modular Monolith**

The PRD originally listed "micro-service," but a **modular monolith** is a better fit for this project. Here's why:

### 2.1 Why Not Micro-service?

| Factor             | Micro-service Problem                     |
| ------------------ | ----------------------------------------- |
| **Module coupling**| All 7 modules interact tightly (auth -> every module, notifications -> everything) |
| **Overhead**       | Needs API Gateway, Service Discovery, Message Queue, Distributed Tracing |
| **Team size**      | Student project / small team, not 10+ engineers |
| **Time pressure**  | 40-60% extra time spent on infrastructure, not features |
| **Database**       | All modules share 1 MySQL schema; no need for distributed transactions |

### 2.2 Why Monolith?

| Factor             | Benefit                                   |
| ------------------ | ----------------------------------------- |
| **Speed**          | Single deploy, single database, simple debugging |
| **Data consistency** | ACID transactions via MySQL foreign keys |
| **Modular**        | Each feature is a separate folder — can be split into a micro-service later |
| **Debugging**      | `console.log` works; no distributed tracing needed |
| **Migration path** | When traffic grows, cut 1 module into a service without rewriting everything |

---

## 3. Backend Architecture

### 3.1 Layered Architecture (Clean Architecture)

```
src/
├── server.ts              # Entry point, middleware setup
├── config/                # Environment variables, DB config
├── core/                  # Shared utilities (logging, error formatting)
├── controllers/           # HTTP layer — parse request, call service, return response
├── services/              # Business logic — validation, calculations, workflows
├── routes/                # Route definitions — maps URL to controller
├── middlewares/           # Auth check, validation, error handling
├── utils/                 # Helpers (token generation, date formatting)
│
├── auth/                  # Auth feature
├── profile/               # Profile feature
├── discovery/             # Search & filter feature
├── offers/                # Offer & campaign management
├── chat/                  # Messaging feature
├── dashboard/             # Dashboard & analytics
└── notification/          # Push & in-app notifications
```

### 3.2 Request Flow

```
Client (Flutter)
    │
    ▼
HTTP Request (Express Route)
    │
    ▼
Middleware (Auth JWT, Validation with Zod)
    │
    ▼
Controller (parse request, call service)
    │
    ▼
Service (business logic, database queries)
    │
    ▼
MySQL Database
    │
    ▼
Response (JSON) → Client
```

### 3.3 Backend Modules

| Module        | Controller              | Service                | Routes                | Responsibilities                     |
| ------------- | ----------------------- | ---------------------- | --------------------- | ------------------------------------ |
| **Auth**      | `auth.controller.ts`    | `auth.service.ts`      | `auth.routes.ts`      | Register, login, logout, JWT token   |
| **Profile**   | `profile.controller.ts` | `profile.service.ts`   | `profile.routes.ts`   | Influencer & brand profile CRUD      |
| **Discovery** | `discovery.controller.ts` | `discovery.service.ts` | `discovery.routes.ts` | Search & filter influencers/brands   |
| **Offers**    | `offer.controller.ts`   | `offer.service.ts`     | `offer.routes.ts`     | Create, manage, track offers         |
| **Chat**      | `chat.controller.ts`    | `chat.service.ts`      | `chat.routes.ts`      | Conversations & messages             |
| **Dashboard** | `dashboard.controller.ts` | `dashboard.service.ts` | `dashboard.routes.ts` | Stats, analytics, summary            |
| **Notification** | `notification.controller.ts` | `notification.service.ts` | `notification.routes.ts` | In-app notifications |

### 3.4 Technology Stack

| Purpose          | Library/Package        |
| ---------------- | ---------------------- |
| **Framework**    | Express.js             |
| **Language**     | TypeScript             |
| **Database**     | MySQL 8.0+ (`mysql2`)  |
| **Validation**   | Zod                    |
| **Auth**         | JWT (`jsonwebtoken`)   |
| **Password**     | Bcrypt (`bcryptjs`)    |
| **CORS**         | `cors`                 |
| **Env**          | `dotenv`               |

---

## 4. Frontend Architecture (Flutter)

### 4.1 Clean Architecture Layers

```
lib/
├── main.dart                 # App entry point, dependency injection setup
├── main_screen.dart          # Main shell (bottom navigation, drawer)
│
├── core/                     # Shared infrastructure
│   ├── constants/            # API endpoints, app themes, colors
│   ├── network/              # Dio client, interceptors, error handlers
│   ├── utils/                # Date formatting, validators, helpers
│   └── theme/                # App theme, fonts, dark mode
│
├── features/                 # Feature-based modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/    # API calls (network/remote)
│   │   │   └── models/         # User, Token models
│   │   ├── domain/
│   │   │   ├── repositories/   # Repository interface
│   │   │   └── usecases/       # Business logic (LoginUser, RegisterUser)
│   │   ├── presentation/
│   │   │   ├── pages/          # Login page, Register page
│   │   │   ├── widgets/        # Auth-specific widgets
│   │   │   └── bloc/           # State management (login_bloc, auth_bloc)
���   │   └── router/           # Route definitions
│   │
│   ├── profile/              # Profile CRUD for influencer & brand
│   ├── discovery/            # Search, filter, influencer detail
│   ├── offers/               # Offer list, offer detail, apply
│   ├── chat/                 # Conversation list, message view
│   ├── dashboard/            # Stats, analytics charts
│   └── notification/         # Notification list, read status
│
└── shared/                   # Shared across features
    ├── widgets/              # Reusable buttons, cards, inputs
    ├── models/               # Shared data models
    └── bloc/                 # Global blocs (session, theme)
```

### 4.2 State Management & Data Flow

```
User Action (UI Page)
    │
    ▼
Bloc / Cubit (handles state: loading, success, error)
    │
    ▼
UseCase (business logic)
    │
    ▼
Repository Interface
    │
    ▼
Repository Implementation
    │
    ▼
DataSource (API call via Dio)
    │
    ▼
HTTP Request → Backend API
    │
    ▼
Response → Model → Repository → UseCase → Bloc → UI rebuild
```

### 4.3 Technology Stack

| Purpose          | Package                 |
| ---------------- | ----------------------- |
| **UI Framework** | Flutter                 |
| **HTTP Client**  | `http` ^1.2.2           |
| **Storage**      | `shared_preferences`    |
| **Charts**       | `fl_chart` ^0.69.0      |
| **Fonts**        | `google_fonts` ^6.2.1   |
| **Date**         | `intl` ^0.20.2          |
| **State Mgmt**   | BLoC / Cubit pattern    |

---

## 5. Database Architecture

### 5.1 Schema Overview

```
users
├── influencer_profiles (1:1)
├── brand_profiles      (1:1)
├── social_media_accounts (1:N)
├── offers              (1:N, as brand)
├── offers              (1:N, as influencer)
├── conversations       (1:N, as participant)
├── messages            (1:N, as sender)
├── notifications       (1:N)
└── earnings            (1:N)
```

### 5.2 Design Principles

| Principle         | Implementation                                  |
| ----------------- | ----------------------------------------------- |
| **Single DB**     | One `konekta` database, all tables in one schema |
| **Foreign Keys**  | InnoDB constraints enforce data integrity        |
| **Indexes**       | `users.email`, `offers.brand_user_id`, etc.     |
| **Soft Delete**   | Consider `deleted_at` for critical data          |
| **Timestamps**    | `created_at`, `updated_at` on every table        |
| **UTF-8**         | `utf8mb4_unicode_ci` collation                   |

### 5.3 Key Tables

| Table                 | Purpose                                  |
| --------------------- | ---------------------------------------- |
| `users`               | Core user account (role: influencer/brand) |
| `influencer_profiles` | Influencer-specific data (niche, followers, rate card) |
| `brand_profiles`      | Brand-specific data (name, industry, plan) |
| `social_media_accounts` | Linked social accounts (platform, handle, followers) |
| `offers`              | Campaign/offer listings                  |
| `campaign_applicants` | Influencer applications to offers        |
| `conversations`       | 1:1 chat sessions between users          |
| `messages`            | Chat messages within conversations       |
| `notifications`       | In-app notification log                  |
| `earnings`            | Payment history for influencers          |

---

## 6. Communication Patterns

### 6.1 HTTP REST API

All Flutter <-> Backend communication uses REST over HTTPS:

| Method | Endpoint                     | Purpose               |
| ------ | ---------------------------- | --------------------- |
| POST   | `/api/auth/register`         | User registration     |
| POST   | `/api/auth/login`            | Login & get JWT       |
| GET    | `/api/auth/me`               | Get current user info |
| GET    | `/api/influencers`           | Search influencers    |
| GET    | `/api/brands`                | Search brands         |
| GET    | `/api/offers`                | List offers           |
| POST   | `/api/offers`                | Create offer          |
| GET    | `/api/conversations`         | Chat list             |
| POST   | `/api/conversations/:id/messages` | Send message  |

### 6.2 Authentication Flow

```
Client                       Backend                      Database
  │                             │                            │
  │── POST /register ──────────>│                            │
  │                             │── INSERT INTO users ──────>│
  │                             │<── INSERT result ──────────│
  │<── JWT token ───────────────│                            │
  │                             │                            │
  │── GET /me (Bearer JWT) ────>│                            │
  │                             │── Verify JWT ──────────────│
  │                             │── SELECT user ─────────────│
  │<── user data ───────────────│                            │
```

---

## 7. Module Dependency Graph

```
              ┌──────────┐
              │   Auth   │ ← Foundation (required by all)
              └────┬─────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    ▼              ▼              ▼
Profile        Discovery      Offers
    │              │              │
    │         ┌────┴────┐        │
    │         │         │        │
    ▼         ▼         ▼        ▼
  Chat    Dashboard  Notification
```

- **Auth** is the foundation — everything depends on it
- **Profile** data feeds Discovery search results
- **Offers** drives both Chat and Notification
- **Dashboard** pulls stats from multiple sources

---

## 8. Migration Path: Monolith → Micro-service

If the project grows beyond MVP scope:

| Current Module      | Can Become         | Trigger to Split           |
| ------------------- | ------------------ | -------------------------- |
| `chat/`             | Real-time service  | WebSocket needed, high traffic |
| `notification/`     | Notification service | Push notifications scale |
| `dashboard/`        | Analytics service  | Heavy data processing      |

The modular folder structure means splitting a module is mostly about:
1. Extract the `controller + service + routes` into a separate Express app
2. Point it to the same database (or copy relevant tables)
3. Wrap it in Docker
4. Add it to a message queue for async events

---

## 9. Project Structure Summary

```
konekta-project/
├── prd.md                     # Product Requirements Document
├── ARCHITECTURE.md            # This file
├── backend/                   # Express.js + TypeScript backend
│   ├── src/
│   │   ├── server.ts
│   │   ├── config/
│   │   ├── controllers/       # 7 controllers
│   │   ├── services/          # 7 services
│   │   ├── routes/            # 7 route files
│   │   ├── middlewares/
│   │   └── utils/
│   └── package.json
│
├── auth/                      # Separate auth module (JavaScript)
│   ├── src/
│   │   ├── server.js
│   │   ├── controllers/
│   │   ├── models/
│   │   └── routes/
│   └── package.json
│
├── konekta/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   ├── features/          # 7 feature modules
│   │   └── shared/
│   └── pubspec.yaml
│
└── database/
    └── schema.sql             # MySQL schema + seed data
```
