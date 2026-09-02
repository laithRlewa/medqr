const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function query(text, params) {
  return pool.query(text, params);
}

async function waitForDb(retries = 40) {
  for (let i = 0; i < retries; i += 1) {
    try {
      await pool.query('SELECT 1');
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 1500));
    }
  }
  throw new Error('تعذر الاتصال بقاعدة PostgreSQL');
}

async function migrate() {
  const sql = fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8');
  await pool.query(sql);
  const extras = [
    `ALTER TABLE posts ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}'`,
    `ALTER TABLE posts ADD COLUMN IF NOT EXISTS doctor_specialty TEXT DEFAULT ''`,
    `ALTER TABLE posts ADD COLUMN IF NOT EXISTS doctor_photo TEXT DEFAULT ''`,
    `ALTER TABLE appointments ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT ''`,
    `ALTER TABLE medical_files ADD COLUMN IF NOT EXISTS visit_id TEXT DEFAULT ''`,
    `ALTER TABLE medical_files ADD COLUMN IF NOT EXISTS doctor_specialty TEXT DEFAULT ''`,
    `ALTER TABLE visits ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'`,
    `ALTER TABLE visits ADD COLUMN IF NOT EXISTS patient_user_id TEXT`,
    `ALTER TABLE post_comments ADD COLUMN IF NOT EXISTS doctor_id TEXT`,
    `ALTER TABLE post_comments ADD COLUMN IF NOT EXISTS doctor_photo TEXT DEFAULT ''`,
    `ALTER TABLE doctors ADD COLUMN IF NOT EXISTS region_id TEXT`,
    `ALTER TABLE doctors ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION`,
    `ALTER TABLE doctors ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION`,
    `ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_push BOOLEAN DEFAULT TRUE`,
    `CREATE TABLE IF NOT EXISTS device_tokens (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT NOT NULL UNIQUE,
      platform TEXT DEFAULT 'android',
      device_info TEXT DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
    `CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id)`,
    `CREATE TABLE IF NOT EXISTS map_regions (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      city TEXT NOT NULL DEFAULT 'بغداد',
      center_lat DOUBLE PRECISION NOT NULL,
      center_lng DOUBLE PRECISION NOT NULL,
      zoom DOUBLE PRECISION DEFAULT 13,
      sort_order INT DEFAULT 0,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )`,
  ];
  for (const statement of extras) {
    await pool.query(statement);
  }
}

module.exports = { pool, query, waitForDb, migrate };
