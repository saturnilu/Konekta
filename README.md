# Konekta 🔗

A mobile platform connecting brands with micro-influencers — from campaign discovery, application, progress tracking, to payment, all in one app.

---

## Project Structure

```
konekta-main/
├── backend/          # Node.js + Express + TypeScript API
├── konekta/          # Flutter mobile app
├── database/         # SQL schema & seed
└── README.md
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) + Provider + Dio |
| Backend | Node.js + Express.js + TypeScript |
| Database | MySQL 8.x |
| Auth | JWT + bcryptjs + Google OAuth 2.0 |
| Validation | Zod |
| External | RapidAPI (TikTok stats) |

---

## Prerequisites

- Node.js >= 18.x
- Flutter SDK >= 3.10.x
- MySQL >= 8.x

---

## Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file inside the `backend/` folder:

```env
PORT=4000
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=konekta
JWT_SECRET=your_jwt_secret
TOKEN_EXPIRY_HOURS=24

# Google OAuth (optional)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost:4000/auth/google/callback

# RapidAPI for TikTok stats (optional)
RAPIDAPI_KEY=
RAPIDAPI_TIKTOK_HOST=tiktok-api23.p.rapidapi.com
```

Run the backend:

```bash
npm run dev      # development (auto-reload)
npm run build    # compile TypeScript
npm start        # production
```

Server runs at `http://localhost:4000`. Verify:

```bash
curl http://localhost:4000/health
```

---

## Database Setup

```bash
mysql -u root -p < database/schema.sql
```

---

## Flutter Setup

```bash
cd konekta
flutter pub get
```

Set the base URL in `lib/core/api_client.dart`:

```dart
// Android Emulator
'http://10.0.2.2:4000'

// Physical device (replace with your machine's local IP)
'http://192.168.x.x:4000'

// Flutter Web / localhost
'http://localhost:4000'
```

Run the app:

```bash
flutter run
```

---

## API Endpoints

Base URL: `http://localhost:4000`

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/health` | | Server status |
| POST | `/auth/register` | | Register |
| POST | `/auth/login` | | Login |
| POST | `/auth/logout` | ✅ | Logout |
| GET | `/auth/google` | | Google OAuth |
| POST | `/auth/google/mobile` | | Google Sign-In (mobile) |
| GET | `/profile/me` | ✅ | Get profile |
| PUT | `/profile/me` | ✅ | Update profile |
| GET | `/offers` | | List public campaigns |
| POST | `/offers` | ✅ | Create campaign (brand) |
| GET | `/offers/:id` | | Campaign detail |
| POST | `/offers/:id/apply` | ✅ | Apply to campaign (influencer) |
| GET | `/offers/:id/applicants` | ✅ | List applicants (brand) |
| PATCH | `/offers/:id/applicants/:appId/status` | ✅ | Approve/reject applicant |
| GET | `/dashboard/influencer` | ✅ | Influencer dashboard |
| GET | `/dashboard/brand` | ✅ | Brand dashboard |
| GET | `/analytics/influencer` | ✅ | Influencer analytics |
| GET | `/analytics/brand` | ✅ | Brand analytics |
| GET | `/influencers` | | Influencer discovery |
| GET | `/notifications` | ✅ | List notifications |
| POST | `/notifications/read-all` | ✅ | Mark all as read |
| GET | `/conversations` | ✅ | List chats |
| POST | `/conversations/:id/messages` | ✅ | Send message |
| GET | `/social/mine` | ✅ | List social accounts |
| POST | `/social/mine` | ✅ | Add social account |
| DELETE | `/social/mine/:id` | ✅ | Remove social account |
| GET | `/subscriptions/plans` | | List plans |
| POST | `/subscriptions/subscribe` | ✅ | Subscribe to a plan |

> Auth header: `Authorization: Bearer <token>`
