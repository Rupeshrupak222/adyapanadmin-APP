-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: Add FCM token to teachers + admin_fcm_tokens table
-- Run this once against your TiDB/MySQL database.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Add fcm_token column to teachers table (safe – only runs if column absent)
ALTER TABLE teachers
  ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(512) NULL DEFAULT NULL;

-- 2. Create admin_fcm_tokens table (stores one FCM token per admin email)
CREATE TABLE IF NOT EXISTS admin_fcm_tokens (
  id         VARCHAR(64)  NOT NULL PRIMARY KEY,
  email      VARCHAR(190) NOT NULL,
  fcm_token  VARCHAR(512) NOT NULL,
  updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_admin_fcm_email (email)
);

-- 3. Add index on teachers.fcm_token for fast "find all with token" queries
CREATE INDEX IF NOT EXISTS idx_teachers_fcm_token
  ON teachers (fcm_token);
