-- =============================================================
-- Konekta seed data
-- Run AFTER schema.sql to populate demo accounts + sample data.
-- Demo password for all accounts: "konekta123"
-- Bcrypt hash below was generated for "konekta123" with cost 10.
-- =============================================================

SET @pwd := '$2a$10$tMxn8HCdHIHk8fauhf/yge6L7WSMbSJApIe6FgfEjtcRNT/l7DQjS';

-- ----- Demo users -----
INSERT INTO users (name, email, password_hash, role, avatar_url, is_verified) VALUES
('Ava Creative',      'ava@konekta.test',       @pwd, 'influencer', NULL, 1),
('Rio Pratama',       'rio@konekta.test',        @pwd, 'influencer', NULL, 0),
('Nadia Putri',       'nadia@konekta.test',      @pwd, 'influencer', NULL, 1),
('Brand Kopi Harum',  'kopi@konekta.test',       @pwd, 'brand',      NULL, 1),
('Brand Skincare Co', 'skincare@konekta.test',   @pwd, 'brand',      NULL, 0);

-- ----- Influencer profiles -----
INSERT INTO influencer_profiles
  (user_id, username, bio, niche, industry, location,
   tiktok_account, instagram_handle, youtube_handle,
   followers_count, engagement_rate, rate_card, media_kit_url)
VALUES
(1, 'ava.creative',  'Lifestyle & fashion creator based in Jakarta.', 'Fashion', 'Lifestyle', 'Jakarta',
   '@avacreative', '@avacreative', NULL,
   12500, 5.5, 1500000, NULL),
(2, 'rio.pratama',   'Food vlogger exploring street eats.',           'Food',    'Food',      'Bandung',
   '@riopratama',  NULL,           '@riopratama',
   42000, 4.2, 800000,  NULL),
(3, 'nadia.putri',   'Beauty & skincare reviewer.',                   'Beauty',  'Beauty',    'Surabaya',
   '@nadiaputri',  '@nadiaputri',  NULL,
   87000, 6.1, 2500000, NULL);

-- ----- Brand profiles -----
INSERT INTO brand_profiles
  (user_id, brand_name, description, industry, website, location, logo_url)
VALUES
(4, 'Kopi Harum',  'Specialty coffee roaster from Bandung.', 'F&B',    'https://kopiharum.test',   'Bandung', NULL),
(5, 'Skincare Co', 'Local skincare startup.',                'Beauty', 'https://skincareco.test',  'Jakarta', NULL);

-- ----- Social media accounts -----
INSERT INTO social_media_accounts
  (influencer_user_id, platform, handle, followers_count, engagement_rate)
VALUES
(1, 'instagram', '@avacreative',  8000,  5.6),
(1, 'tiktok',    '@avacreative',  4500,  5.4),
(2, 'tiktok',    '@riopratama',  25000,  4.0),
(2, 'youtube',   '@riopratama',  17000,  4.4),
(3, 'instagram', '@nadiaputri',  52000,  6.3),
(3, 'tiktok',    '@nadiaputri',  35000,  5.9);

-- ----- Demo offers -----
INSERT INTO offers
  (brand_user_id, influencer_user_id, title, brief, budget, reward_per_creator,
   target_views, target_likes, target_shares, deliverables, requirements,
   target_audience, deadline, room_code, is_public, status)
VALUES
(4, 1, 'Spring Coffee Lookbook',
   'Promote our spring coffee lookbook across TikTok and Instagram.',
   5000000, 1500000, 100000, 5000, 500,
   '1 TikTok reel + 1 IG story', 'Female 18-30, lifestyle audience',
   'Lifestyle', '2026-07-31', 'ROOM-SPRING-COFFEE', 1, 'open'),
(4, 2, 'Coffee Street Vlog Series',
   'Short street-style vlogs featuring our cold brew.',
   4000000, 800000, 80000, 4000, 400,
   '2 short vlogs', 'Local foodies',
   'Food', '2026-08-15', 'ROOM-COFFEE-VLOG', 1, 'open'),
(5, 3, 'Skincare Routine Reel',
   'Reel showing a 5-step morning routine using our products.',
   3500000, 2500000, 60000, 3500, 300,
   '1 Reel + 1 carousel', 'Skincare enthusiasts, female 20-35',
   'Beauty', '2026-08-01', 'ROOM-SKINCARE-ROUTINE', 1, 'open');

-- ----- Demo conversations -----
INSERT INTO conversations (user_a_id, user_b_id, offer_id) VALUES
(4, 1, 1),
(4, 2, 2),
(5, 3, 3);

-- ----- Demo messages -----
INSERT INTO messages (conversation_id, sender_user_id, message_text) VALUES
(1, 4, 'Hi Ava! We love your content and would love to collaborate.'),
(1, 1, 'Hi Kopi Harum! Thanks for reaching out. Sure, I am interested.'),
(2, 4, 'Hi Rio, are you available for a vlog collaboration?'),
(3, 5, 'Hi Nadia, would love to send you our new skincare line.');

-- Update last_message on conversations
UPDATE conversations SET
  last_message = 'Hi Kopi Harum! Thanks for reaching out. Sure, I am interested.',
  last_message_at = NOW()
WHERE id = 1;
UPDATE conversations SET
  last_message = 'Hi Rio, are you available for a vlog collaboration?',
  last_message_at = NOW()
WHERE id = 2;
UPDATE conversations SET
  last_message = 'Hi Nadia, would love to send you our new skincare line.',
  last_message_at = NOW()
WHERE id = 3;

-- ----- Demo notifications -----
INSERT INTO notifications (user_id, type, title, body, data, is_read) VALUES
(1, 'offer', 'New offer from Kopi Harum',  'You have a new offer: Spring Coffee Lookbook',  JSON_OBJECT('offer_id', 1), 0),
(2, 'offer', 'New offer from Kopi Harum',  'You have a new offer: Coffee Street Vlog Series', JSON_OBJECT('offer_id', 2), 0),
(3, 'offer', 'New offer from Skincare Co', 'You have a new offer: Skincare Routine Reel',    JSON_OBJECT('offer_id', 3), 0);
