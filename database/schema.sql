-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 29 Jun 2026 pada 14.56
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `konekta`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `analytics_events`
--

CREATE TABLE `analytics_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `campaign_id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `event_type` enum('view','like','share','comment','reach') NOT NULL,
  `event_count` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `source` varchar(40) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `brand_profiles`
--

CREATE TABLE `brand_profiles` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `brand_name` varchar(120) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `industry` varchar(120) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `location` varchar(120) DEFAULT NULL,
  `logo_url` varchar(500) DEFAULT NULL,
  `plan` enum('free','pro_monthly','pro_annual') NOT NULL DEFAULT 'free',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `brand_profiles`
--

INSERT INTO `brand_profiles` (`user_id`, `brand_name`, `description`, `industry`, `website`, `location`, `logo_url`, `plan`, `created_at`, `updated_at`) VALUES
(4, 'Kopi Susu Co.', 'Premium iced coffee brand looking for lifestyle creators.', 'F&B', 'kopisusu.id', 'Jakarta', NULL, 'free', '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(5, 'Aula Skincare', 'Local skincare focused on natural ingredients.', 'Beauty', 'aulaskincare.id', 'Bandung', NULL, 'free', '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(6, 'NBA Indonesia', 'Official NBA merchandise retailer in Indonesia.', 'Sports/Fashion', 'nba.id', 'Jakarta', NULL, 'free', '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(8, 'TestB\'s Brand', '', '', '', NULL, NULL, 'free', '2026-06-29 12:56:24', '2026-06-29 12:56:26');

-- --------------------------------------------------------

--
-- Struktur dari tabel `brand_subscriptions`
--

CREATE TABLE `brand_subscriptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `brand_user_id` bigint(20) UNSIGNED NOT NULL,
  `plan_id` int(11) NOT NULL DEFAULT 0,
  `plan_code` varchar(40) NOT NULL,
  `plan_name` varchar(120) NOT NULL DEFAULT '',
  `status` enum('active','cancelled','expired') NOT NULL DEFAULT 'active',
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `campaign_applicants`
--

CREATE TABLE `campaign_applicants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `offer_id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('pending','approved','rejected','completed','shortlisted') NOT NULL DEFAULT 'pending',
  `progress` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `views` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `likes` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `shares` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `message` text DEFAULT NULL,
  `proposed_rate` decimal(15,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `campaign_applicants`
--

INSERT INTO `campaign_applicants` (`id`, `offer_id`, `influencer_user_id`, `status`, `progress`, `views`, `likes`, `shares`, `message`, `proposed_rate`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'approved', 78, 39000, 3900, 156, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(2, 1, 2, 'approved', 40, 40000, 4000, 160, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(3, 1, 3, 'completed', 100, 67000, 6000, 150, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `conversations`
--

CREATE TABLE `conversations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_a_id` bigint(20) UNSIGNED NOT NULL,
  `user_b_id` bigint(20) UNSIGNED NOT NULL,
  `offer_id` bigint(20) UNSIGNED DEFAULT NULL,
  `last_message` text DEFAULT NULL,
  `last_message_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `conversations`
--

INSERT INTO `conversations` (`id`, `user_a_id`, `user_b_id`, `offer_id`, `last_message`, `last_message_at`, `created_at`) VALUES
(1, 4, 1, 1, NULL, NULL, '2026-06-29 06:36:36'),
(2, 5, 2, 2, NULL, NULL, '2026-06-29 06:36:36'),
(3, 6, 3, 3, NULL, NULL, '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `earnings`
--

CREATE TABLE `earnings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `offer_id` bigint(20) UNSIGNED DEFAULT NULL,
  `description` varchar(255) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `earnings`
--

INSERT INTO `earnings` (`id`, `influencer_user_id`, `offer_id`, `description`, `amount`, `created_at`) VALUES
(1, 1, NULL, 'Summer Tech Series', 125000.00, '2026-06-29 06:36:36'),
(2, 1, NULL, 'Summer Tech Series', 123000.00, '2026-06-29 06:36:36'),
(3, 1, NULL, 'Summer Tech Series', 99000.00, '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `influencer_metrics_snapshot`
--

CREATE TABLE `influencer_metrics_snapshot` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `metric_date` date NOT NULL,
  `total_views` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `total_likes` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `total_shares` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `total_earnings` decimal(15,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `influencer_profiles`
--

CREATE TABLE `influencer_profiles` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `username` varchar(80) NOT NULL,
  `bio` varchar(500) DEFAULT NULL,
  `niche` varchar(120) DEFAULT NULL,
  `industry` varchar(120) DEFAULT NULL,
  `location` varchar(120) DEFAULT NULL,
  `tiktok_account` varchar(120) DEFAULT NULL,
  `instagram_handle` varchar(120) DEFAULT NULL,
  `youtube_handle` varchar(120) DEFAULT NULL,
  `followers_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `engagement_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `rate_card` decimal(15,2) NOT NULL DEFAULT 0.00,
  `media_kit_url` varchar(500) DEFAULT NULL,
  `payout_bank` varchar(80) DEFAULT NULL,
  `payout_account` varchar(40) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `influencer_profiles`
--

INSERT INTO `influencer_profiles` (`user_id`, `username`, `bio`, `niche`, `industry`, `location`, `tiktok_account`, `instagram_handle`, `youtube_handle`, `followers_count`, `engagement_rate`, `rate_card`, `media_kit_url`, `payout_bank`, `payout_account`, `created_at`, `updated_at`) VALUES
(1, 'avacreator', 'Lifestyle creator. Coffee, travel, & honest reviews.', 'Lifestyle', 'Lifestyle', 'Jakarta', '@avacreator', NULL, NULL, 12500, 4.20, 3500000.00, NULL, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(2, 'leolifestyle', 'Food & lifestyle. Always open for collabs.', 'Lifestyle', 'Food', 'Bandung', '@leolifestyle', NULL, NULL, 25400, 3.20, 5000000.00, NULL, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(3, 'mayabeauty', 'Beauty content, tutorials, and honest reviews.', 'Beauty', 'Beauty', 'Surabaya', '@mayabeauty', NULL, NULL, 47800, 5.10, 7000000.00, NULL, NULL, NULL, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(7, 'TestI', '', NULL, 'Beauty', NULL, '', '', '', 0, 0.00, 0.00, NULL, NULL, NULL, '2026-06-29 07:27:29', '2026-06-29 07:27:35');

-- --------------------------------------------------------

--
-- Struktur dari tabel `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `conversation_id` bigint(20) UNSIGNED NOT NULL,
  `sender_user_id` bigint(20) UNSIGNED NOT NULL,
  `message_text` text NOT NULL,
  `attachment_url` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `messages`
--

INSERT INTO `messages` (`id`, `conversation_id`, `sender_user_id`, `message_text`, `attachment_url`, `created_at`) VALUES
(1, 1, 4, 'Hi! We love your recent post. We would like to discuss a potential collaboration.', NULL, '2026-06-29 06:36:36'),
(2, 1, 1, 'Thanks for the update. Let me know when...', NULL, '2026-06-29 06:36:36'),
(3, 2, 5, 'Sure, let me join your room campaign.', NULL, '2026-06-29 06:36:36'),
(4, 3, 6, 'Hey! Are you available for a campaign?', NULL, '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(60) NOT NULL,
  `title` varchar(180) NOT NULL,
  `body` varchar(500) DEFAULT NULL,
  `icon` varchar(40) DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `read_status` tinyint(1) NOT NULL DEFAULT 0,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `type`, `title`, `body`, `icon`, `data`, `read_status`, `is_read`, `created_at`) VALUES
(1, 1, 'campaign_target', 'Campaign Target Success', 'Congratulations! You accomplished the target for \"Kopi Susu\".', 'trending_up', NULL, 0, 0, '2026-06-29 06:36:36'),
(2, 1, 'message', 'New Message from Malboro', 'Hey! We loved your recent post. We would like to discuss...', 'chat', NULL, 0, 0, '2026-06-29 06:36:36'),
(3, 1, 'payment', 'Payment Processed', 'Your payout of Rp125.000 for the \"Tech Review\" campaign...', 'payments', NULL, 1, 1, '2026-06-29 06:36:36'),
(4, 1, 'verification', 'Profile Verification Complete', 'Your identity has been verified. You now have full access to apply.', 'verified', NULL, 1, 1, '2026-06-29 06:36:36'),
(5, 1, 'application', 'Application Accepted', 'ViewSonic has accepted your contract to join campaign...', 'task_alt', NULL, 1, 1, '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `offers`
--

CREATE TABLE `offers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `brand_user_id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `title` varchar(180) NOT NULL,
  `brief` text DEFAULT NULL,
  `budget` decimal(15,2) NOT NULL DEFAULT 0.00,
  `reward_per_creator` decimal(15,2) NOT NULL DEFAULT 0.00,
  `target_views` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `target_likes` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `target_shares` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `deliverables` text DEFAULT NULL,
  `requirements` text DEFAULT NULL,
  `target_audience` varchar(255) DEFAULT NULL,
  `deadline` date DEFAULT NULL,
  `room_code` varchar(40) DEFAULT NULL,
  `max_creators` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `status` enum('draft','open','offered','negotiation','accepted','in_progress','submitted','completed','rejected','cancelled') NOT NULL DEFAULT 'open',
  `is_public` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `offers`
--

INSERT INTO `offers` (`id`, `brand_user_id`, `influencer_user_id`, `title`, `brief`, `budget`, `reward_per_creator`, `target_views`, `target_likes`, `target_shares`, `deliverables`, `requirements`, `target_audience`, `deadline`, `room_code`, `status`, `is_public`, `created_at`, `updated_at`) VALUES
(1, 4, NULL, 'Summer Iced Latte Launch', 'Promote our new summer iced latte line. 1 TikTok video + 1 Instagram story.', 150000.00, 150000.00, 50000, 5000, 200, NULL, NULL, NULL, '2026-07-13', NULL, 'open', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(2, 5, NULL, 'Aula Skincare Glow Up', 'Create tutorial content using Aula Skincare products.', 100000.00, 100000.00, 100000, 10000, 200, NULL, NULL, NULL, '2026-07-11', NULL, 'open', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(3, 6, NULL, 'NBA Merch Drop', 'Promote the new NBA merchandise drop with a TikTok video.', 200000.00, 67000.00, 67000, 6000, 150, NULL, NULL, NULL, '2026-07-20', NULL, 'open', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(4, 4, NULL, 'Kopi Susu Winter Campaign', 'Winter themed content promoting our new limited edition drinks.', 80000.00, 80000.00, 30000, 3000, 100, NULL, NULL, NULL, '2026-07-29', NULL, 'open', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(5, 5, NULL, 'Skincare Morning Routine', 'Share your morning routine featuring Aula Skincare products.', 60000.00, 60000.00, 20000, 2000, 50, NULL, NULL, NULL, '2026-07-24', NULL, 'open', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(6, 4, 1, 'Summer Iced Latte (Active)', 'Ongoing campaign with Ava.', 50000.00, 150000.00, 50000, 5000, 200, NULL, NULL, NULL, '2026-07-13', '2H19CDhe901', 'in_progress', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(7, 5, 2, 'Aula Skincare (Active)', 'Ongoing campaign with Leo.', 100000.00, 100000.00, 100000, 10000, 200, NULL, NULL, NULL, '2026-07-11', 'AULAGLOW2025', 'in_progress', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(8, 6, 3, 'NBA Merch (Completed)', 'Completed campaign with Maya.', 67000.00, 67000.00, 67000, 6000, 150, NULL, NULL, NULL, '2026-06-30', 'NBAMERCH2025', 'completed', 1, '2026-06-29 06:36:36', '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `offer_progress`
--

CREATE TABLE `offer_progress` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `offer_id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `milestone` varchar(120) NOT NULL,
  `status` varchar(40) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `social_media_accounts`
--

CREATE TABLE `social_media_accounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `platform` enum('instagram','tiktok','youtube','twitter','facebook','other') NOT NULL,
  `handle` varchar(120) NOT NULL,
  `followers_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `engagement_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `social_media_accounts`
--

INSERT INTO `social_media_accounts` (`id`, `influencer_user_id`, `platform`, `handle`, `followers_count`, `engagement_rate`, `created_at`) VALUES
(1, 1, 'tiktok', '@avacreator', 8500, 4.50, '2026-06-29 06:36:36'),
(2, 1, 'instagram', '@avacreator', 4000, 3.80, '2026-06-29 06:36:36'),
(3, 2, 'tiktok', '@leolifestyle', 21000, 3.40, '2026-06-29 06:36:36'),
(4, 2, 'instagram', '@leolifestyle', 4400, 2.80, '2026-06-29 06:36:36'),
(5, 3, 'tiktok', '@mayabeauty', 32000, 5.30, '2026-06-29 06:36:36'),
(6, 3, 'instagram', '@mayabeauty', 15800, 4.90, '2026-06-29 06:36:36');

-- --------------------------------------------------------

--
-- Struktur dari tabel `submitted_videos`
--

CREATE TABLE `submitted_videos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `offer_id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `video_url` varchar(500) NOT NULL,
  `views_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `likes_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `shares_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `fetched_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `subscription_invoices`
--

CREATE TABLE `subscription_invoices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `brand_user_id` bigint(20) UNSIGNED NOT NULL,
  `plan` enum('free','pro_monthly','pro_annual') NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status` enum('pending','paid','cancelled','expired') NOT NULL DEFAULT 'pending',
  `external_ref` varchar(120) DEFAULT NULL,
  `starts_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(120) NOT NULL,
  `email` varchar(180) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('influencer','brand') NOT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `avatar_url`, `is_verified`, `created_at`, `updated_at`) VALUES
(1, 'Ava Creator', 'ava@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'influencer', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(2, 'Leo Lifestyle', 'leo@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'influencer', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(3, 'Maya Beauty', 'maya@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'influencer', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(4, 'Kopi Susu Co.', 'brand1@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'brand', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(5, 'Aula Skincare', 'brand2@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'brand', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(6, 'NBA Indonesia', 'brand3@konekta_mobile_app.test', '$2a$10$81nUzU01BU7PHwuf0BTkH.Dqx5D6Mls89kqu1akwIptzl1OL/z2oW', 'brand', NULL, 0, '2026-06-29 06:36:36', '2026-06-29 06:36:36'),
(7, 'TestI', 'TestI@gmail.com', '$2a$10$AzbS.SqW444CinGKDh3RCexGm4XWL/zORZRjr9jpNEQqEIZwr8I1a', 'influencer', NULL, 0, '2026-06-29 07:27:29', '2026-06-29 07:27:29'),
(8, 'TestB', 'TestB@gmail.com', '$2a$10$/wgWFck1qwVPVqPDHcqgDe9MTmBV1PLHLjwghrNXAapwI0SG1..2O', 'brand', NULL, 0, '2026-06-29 12:56:24', '2026-06-29 12:56:24');

-- --------------------------------------------------------

--
-- Struktur dari tabel `video_daily_stats`
--

CREATE TABLE `video_daily_stats` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `influencer_user_id` bigint(20) UNSIGNED NOT NULL,
  `stat_date` date NOT NULL,
  `views_count` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `likes_count` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `shares_count` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `comments_count` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `analytics_events`
--
ALTER TABLE `analytics_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ev_campaign` (`campaign_id`),
  ADD KEY `idx_ev_influencer` (`influencer_user_id`);

--
-- Indeks untuk tabel `brand_profiles`
--
ALTER TABLE `brand_profiles`
  ADD PRIMARY KEY (`user_id`);

--
-- Indeks untuk tabel `brand_subscriptions`
--
ALTER TABLE `brand_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_bsub_brand` (`brand_user_id`);

--
-- Indeks untuk tabel `campaign_applicants`
--
ALTER TABLE `campaign_applicants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_apply` (`offer_id`,`influencer_user_id`),
  ADD KEY `idx_apply_influencer` (`influencer_user_id`);

--
-- Indeks untuk tabel `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_conv_pair` (`user_a_id`,`user_b_id`,`offer_id`),
  ADD KEY `idx_conv_user_a` (`user_a_id`),
  ADD KEY `idx_conv_user_b` (`user_b_id`),
  ADD KEY `fk_conv_offer` (`offer_id`);

--
-- Indeks untuk tabel `earnings`
--
ALTER TABLE `earnings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_earn_influencer` (`influencer_user_id`);

--
-- Indeks untuk tabel `influencer_metrics_snapshot`
--
ALTER TABLE `influencer_metrics_snapshot`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_snapshot` (`influencer_user_id`,`metric_date`);

--
-- Indeks untuk tabel `influencer_profiles`
--
ALTER TABLE `influencer_profiles`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uk_influencer_username` (`username`);

--
-- Indeks untuk tabel `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_msg_conv` (`conversation_id`),
  ADD KEY `fk_msg_sender` (`sender_user_id`);

--
-- Indeks untuk tabel `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notif_user` (`user_id`);

--
-- Indeks untuk tabel `offers`
--
ALTER TABLE `offers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_offers_brand` (`brand_user_id`),
  ADD KEY `idx_offers_influencer` (`influencer_user_id`),
  ADD KEY `idx_offers_status` (`status`);

--
-- Indeks untuk tabel `offer_progress`
--
ALTER TABLE `offer_progress`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_progress_offer` (`offer_id`);

--
-- Indeks untuk tabel `social_media_accounts`
--
ALTER TABLE `social_media_accounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sm_influencer` (`influencer_user_id`);

--
-- Indeks untuk tabel `submitted_videos`
--
ALTER TABLE `submitted_videos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_sv_url` (`offer_id`,`influencer_user_id`,`video_url`(200)),
  ADD KEY `idx_sv_offer` (`offer_id`),
  ADD KEY `idx_sv_influencer` (`influencer_user_id`);

--
-- Indeks untuk tabel `subscription_invoices`
--
ALTER TABLE `subscription_invoices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_inv_brand` (`brand_user_id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_users_email` (`email`);

--
-- Indeks untuk tabel `video_daily_stats`
--
ALTER TABLE `video_daily_stats`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_vds_user_date` (`influencer_user_id`,`stat_date`),
  ADD KEY `idx_vds_influencer` (`influencer_user_id`),
  ADD KEY `idx_vds_date` (`stat_date`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `analytics_events`
--
ALTER TABLE `analytics_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `brand_subscriptions`
--
ALTER TABLE `brand_subscriptions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `campaign_applicants`
--
ALTER TABLE `campaign_applicants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `earnings`
--
ALTER TABLE `earnings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `influencer_metrics_snapshot`
--
ALTER TABLE `influencer_metrics_snapshot`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT untuk tabel `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `offers`
--
ALTER TABLE `offers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT untuk tabel `offer_progress`
--
ALTER TABLE `offer_progress`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `social_media_accounts`
--
ALTER TABLE `social_media_accounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT untuk tabel `submitted_videos`
--
ALTER TABLE `submitted_videos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `subscription_invoices`
--
ALTER TABLE `subscription_invoices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT untuk tabel `video_daily_stats`
--
ALTER TABLE `video_daily_stats`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `analytics_events`
--
ALTER TABLE `analytics_events`
  ADD CONSTRAINT `fk_ev_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `offers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ev_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `brand_profiles`
--
ALTER TABLE `brand_profiles`
  ADD CONSTRAINT `fk_brand_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `brand_subscriptions`
--
ALTER TABLE `brand_subscriptions`
  ADD CONSTRAINT `fk_bsub_brand` FOREIGN KEY (`brand_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `campaign_applicants`
--
ALTER TABLE `campaign_applicants`
  ADD CONSTRAINT `fk_apply_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_apply_offer` FOREIGN KEY (`offer_id`) REFERENCES `offers` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `fk_conv_a` FOREIGN KEY (`user_a_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_conv_b` FOREIGN KEY (`user_b_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_conv_offer` FOREIGN KEY (`offer_id`) REFERENCES `offers` (`id`) ON DELETE SET NULL;

--
-- Ketidakleluasaan untuk tabel `earnings`
--
ALTER TABLE `earnings`
  ADD CONSTRAINT `fk_earn_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `influencer_metrics_snapshot`
--
ALTER TABLE `influencer_metrics_snapshot`
  ADD CONSTRAINT `fk_snap_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `influencer_profiles`
--
ALTER TABLE `influencer_profiles`
  ADD CONSTRAINT `fk_influencer_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_msg_sender` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `offers`
--
ALTER TABLE `offers`
  ADD CONSTRAINT `fk_offers_brand` FOREIGN KEY (`brand_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_offers_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Ketidakleluasaan untuk tabel `offer_progress`
--
ALTER TABLE `offer_progress`
  ADD CONSTRAINT `fk_progress_offer` FOREIGN KEY (`offer_id`) REFERENCES `offers` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `social_media_accounts`
--
ALTER TABLE `social_media_accounts`
  ADD CONSTRAINT `fk_sm_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `submitted_videos`
--
ALTER TABLE `submitted_videos`
  ADD CONSTRAINT `fk_sv_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sv_offer` FOREIGN KEY (`offer_id`) REFERENCES `offers` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `subscription_invoices`
--
ALTER TABLE `subscription_invoices`
  ADD CONSTRAINT `fk_inv_brand` FOREIGN KEY (`brand_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `video_daily_stats`
--
ALTER TABLE `video_daily_stats`
  ADD CONSTRAINT `fk_vds_influencer` FOREIGN KEY (`influencer_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
