# Product Requirements Document (PRD)

## Konekta

**Platform:** Mobile App
**Frontend:** Flutter (Dart)
**Backend:** Express.js (TypeScript)
**Database:** MySQL

---

## 1. Product Summary

**Konekta** is a mobile application that connects **influencers** and **brands** on a single platform. The application serves two types of users:

- **Influencer side:** search for endorsement opportunities, manage social media profiles, receive collaboration offers, and track endorsement status.
- **Brand side:** find relevant influencers, view influencer performance data, send collaboration offers, and monitor campaign progress.

The primary goal of the application is to streamline the matching, negotiation, tracking, and communication process between influencers and brands.

---

## 2. Product Goals

1. Connect brands and influencers efficiently.
2. Provide a relevant search and filter system for both sides.
3. Help influencers monitor all their endorsements in one place.
4. Help brands find influencers that fit their campaign needs.
5. Improve collaboration transparency through clear status tracking.

---

## 3. Problems Being Solved

### For Influencers

- Difficulty finding brands that are a good fit.
- Endorsement workflows are scattered across chat, email, and spreadsheets.
- Difficulty tracking the status of ongoing collaborations.

### For Brands

- Difficulty finding the right influencer based on niche, audience, and budget.
- The influencer search process is time-consuming.
- Lack of structured data for comparing influencer candidates.

---

## 4. Target Users

### 4.1 Influencers

- Micro influencers
- Mid-tier influencers
- Content creators
- KOL / Key Opinion Leaders

### 4.2 Brands

- Small and medium businesses (SMEs)
- Local brands
- Startups
- Marketing / talent management agencies
- Enterprise brands running influencer marketing campaigns

---

## 5. Value Proposition

### For Influencers

- Get endorsement opportunities faster.
- All collaborations recorded in an organized way.
- Ability to monitor offer status and deadlines.

### For Brands

- Find relevant influencers more quickly.
- Influencer data is easier to compare.
- Campaign process is more structured.

---

## 6. Product Scope

### 6.1 MVP Scope

Core features required in the first version:

- Registration and login
- Role selection: Influencer / Brand
- Complete profile based on role
- Search and filter for influencer / brand
- Influencer / brand profile detail
- Send collaboration offers
- Accept / reject offers
- Track endorsement / campaign status
- Basic notifications
- Basic chat or messaging
- Simple dashboard for each role

### 6.2 Out of Scope for MVP

- AI recommendation engine
- Payment escrow / payment gateway
- Advanced digital contract signing
- Full KYC
- In-depth campaign analytics
- Multi-team management for brands
- Complex web admin panel

---

## 7. User Roles

### 7.1 Influencer

Core functions:

- Create personal and social media profiles
- Display niche, rate card, audience, and media kit
- Receive offers from brands
- Track endorsement status
- Manage work schedule

### 7.2 Brand

Core functions:

- Create brand / company profile
- Search for influencers based on campaign needs
- Send brief / offer
- Monitor campaign progress
- Manage saved influencer lists

### 7.3 Admin (optional for next phase)

- User and content moderation
- Account verification
- Handle reports / abuse
- Platform monitoring

---

## 8. User Journey

### 8.1 Influencer Journey

1. Register an account.
2. Select influencer role.
3. Complete social media profile, niche, and rate.
4. Enter the dashboard.
5. Search for brands or wait for incoming offers.
6. Accept an offer.
7. Discuss via chat.
8. Track work status until completion.

### 8.2 Brand Journey

1. Register an account.
2. Select brand role.
3. Complete brand profile and campaign requirements.
4. Search for influencers using filters.
5. Save candidates or send an offer.
6. Discuss with the influencer.
7. Monitor campaign status.
8. Evaluate the collaboration results.

---

## 9. Key Features

### 9.1 Authentication

- Register
- Login
- Logout
- Forgot password
- Role selection during onboarding

### 9.2 Profile Management

#### Influencer Profile

- Name
- Profile photo
- Bio
- Niche / content category
- Social media platforms (Instagram, TikTok, YouTube, etc.)
- Follower count
- Engagement rate
- Rate card
- Location
- Portfolio / media kit

#### Brand Profile

- Brand name
- Logo
- Brand description
- Industry
- Location
- Website / social media
- Campaign category

### 9.3 Discovery / Search

#### Brand searches for influencers by:

- Niche
- Location
- Social media platform
- Follower range
- Engagement rate
- Budget
- Category
- Audience demographic (if available)

#### Influencer searches for brands by:

- Brand category
- Location
- Campaign type
- Budget range
- Active campaign status

### 9.4 Offer / Campaign Management

- Brand sends a collaboration offer
- Influencer accepts / rejects / negotiates
- Campaign status:
  - Draft
  - Offered
  - Negotiation
  - Accepted
  - In Progress
  - Submitted
  - Completed
  - Rejected
  - Cancelled

### 9.5 Messaging

- 1-on-1 chat between brand and influencer
- Basic file attachments
- Conversation history

### 9.6 Tracking Dashboard

#### Influencer Dashboard

- Total incoming offers
- Active campaigns
- Completed campaigns
- Nearest deadline
- Payment status (to be added later)

#### Brand Dashboard

- Total influencers found
- Offers sent
- Active campaigns
- Completed campaigns
- Response rate

### 9.7 Notifications

- New offer
- New message
- Status change
- Deadline reminder

---

## 10. Functional Requirements

### 10.1 Authentication

- Users can register with email and password.
- Users can log in according to their role.
- The system stores user role in the database.

### 10.2 Profile

- Users can fill in and update their profile.
- Influencers can add multiple social media accounts.
- Brands can fill in company details and campaign needs.

### 10.3 Search and Filter

- Brands can search for influencers using specific filters.
- Influencers can search for brands by campaign category.
- Search results can be sorted by relevance.

### 10.4 Offer Management

- Brands can create offers to influencers.
- Influencers can accept / reject / request revisions.
- All status changes are saved in the system.

### 10.5 Chat

- Users can send messages after a connection / offer exists.
- Messages are stored and can be reopened.

### 10.6 Tracking

- Users can view campaign history.
- Users can check the latest status of each offer.

---

## 11. Non-Functional Requirements

- **Performance:** search results must appear quickly and responsively.
- **Scalability:** the system must be able to accommodate many influencers and brands.
- **Security:** passwords are hashed, endpoints protected by JWT.
- **Reliability:** offer and campaign data must not be lost.
- **Usability:** simple UI, easy to understand, suitable for mobile.
- **Maintainability:** code architecture must be modular.

---

## 12. Data Entities (High Level)

### 12.1 User

- id
- name
- email
- password_hash
- role (`influencer` / `brand`)
- created_at
- updated_at

### 12.2 Influencer Profile

- user_id
- username
- bio
- niche
- location
- followers_count
- engagement_rate
- rate_card
- media_kit_url

### 12.3 Brand Profile

- user_id
- brand_name
- description
- industry
- website
- location
- logo_url

### 12.4 Social Media Account

- id
- influencer_user_id
- platform
- handle
- followers_count
- engagement_rate

### 12.5 Offer / Campaign

- id
- brand_user_id
- influencer_user_id
- title
- brief
- budget
- status
- deadline
- created_at
- updated_at

### 12.6 Message

- id
- conversation_id
- sender_user_id
- message_text
- attachment_url
- created_at

### 12.7 Notification

- id
- user_id
- type
- title
- body
- read_status
- created_at

---

## 13. API Requirements (Express.js)

### Authentication

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `POST /auth/forgot-password`

### Profile

- `GET /profile/me`
- `PUT /profile/me`
- `POST /profile/influencer/social-media`
- `PUT /profile/brand`

### Discovery

- `GET /influencers`
- `GET /brands`
- `GET /influencers/:id`
- `GET /brands/:id`

### Offers / Campaigns

- `POST /offers`
- `GET /offers`
- `GET /offers/:id`
- `PATCH /offers/:id/status`

### Chat

- `GET /conversations`
- `POST /conversations`
- `GET /conversations/:id/messages`
- `POST /conversations/:id/messages`

### Notifications

- `GET /notifications`
- `PATCH /notifications/:id/read`

---

## 14. Database Considerations (MySQL)

### Key Relations

- 1 user = 1 primary role
- 1 influencer can have multiple social media accounts
- 1 brand can have multiple offers
- 1 conversation can contain multiple messages
- 1 user can have multiple notifications

### Recommended Indexes

- `users.email`
- `offers.brand_user_id`
- `offers.influencer_user_id`
- `social_media_accounts.influencer_user_id`
- `notifications.user_id`

---

## 15. MVP Success Metrics

- Number of new user registrations
- Percentage of completed profiles
- Number of influencer / brand searches per day
- Number of offers sent
- Offer response rate
- Number of completed campaigns
- 7-day and 30-day retention

---

## 16. Product Risks

1. **Incomplete profile data** → search results become less accurate.
2. **Low chat activity** → offers do not progress into campaigns.
3. **Immature account verification** → risk of fake accounts.
4. **Lack of rate transparency** → negotiations become slow.
5. **Cold start problem** → hard to find many users at the beginning.

---

## 17. Recommended Development Phases

### Phase 1 — MVP

- Auth
- Profile
- Search
- Offer
- Tracking
- Basic chat

### Phase 2

- Account verification
- Media kit upload
- Bookmark / shortlist
- Rating / review
- Real-time notifications

### Phase 3

- Payment tracking
- Campaign analytics
- Recommendation engine
- Admin dashboard
- Social media API integration

---

## 18. Technical Notes

### Flutter Frontend

- Use clean / modular architecture.
- Separate the UI, state management, repository, and data source layers.
- Recommended state management: BLoC, Riverpod, or Provider.

### Express.js Backend

- Use consistent REST API.
- Authentication using JWT.
- Validate requests with middleware.
- Logging and error handling must be clean and organized.

### MySQL Database

- Use foreign keys and indexes.
- Store offer status data in a structured way.
- Consider soft delete for important data.

---

## 19. Definition of Done (MVP)

The MVP product is considered complete when:

- Users can register and log in.
- Influencers and brands can create profiles.
- Brands can search for influencers.
- Influencers can receive offers.
- Campaign status can be tracked.
- Basic chat works.
- Data is stored securely in the backend and MySQL.

---

## 20. Summary

Konekta is a platform connecting influencers and brands focused on **discovery, offer management, chat, and campaign tracking**. For the MVP, the main focus is to build a simple yet complete workflow so that both sides can immediately use the application to find, offer, and monitor collaborations.