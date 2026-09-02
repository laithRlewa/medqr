CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL,
  phone TEXT DEFAULT '',
  profile_photo TEXT DEFAULT '',
  language_preference TEXT DEFAULT 'ar',
  notify_email BOOLEAN DEFAULT TRUE,
  notify_sms BOOLEAN DEFAULT TRUE,
  notify_push BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctors (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  gender TEXT DEFAULT 'Male',
  date_of_birth TEXT DEFAULT '',
  specialty TEXT NOT NULL,
  clinic_name TEXT NOT NULL,
  city TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  license_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  subscription_status TEXT NOT NULL DEFAULT 'inactive',
  subscription_start TIMESTAMPTZ,
  subscription_end TIMESTAMPTZ,
  subscription_duration TEXT,
  payment_amount NUMERIC DEFAULT 0,
  years_of_experience INT DEFAULT 0,
  qualifications TEXT DEFAULT '',
  biography TEXT DEFAULT '',
  working_hours TEXT DEFAULT '',
  profile_photo TEXT DEFAULT '',
  certificates TEXT[] DEFAULT '{}',
  featured BOOLEAN DEFAULT FALSE,
  rating NUMERIC DEFAULT 4.5,
  reviews INT DEFAULT 0,
  last_modified_by TEXT,
  last_modified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS patients (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  patient_id TEXT UNIQUE NOT NULL,
  qr_code_data TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  city TEXT NOT NULL,
  gender TEXT NOT NULL,
  blood_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  national_id TEXT DEFAULT '',
  date_of_birth TEXT DEFAULT '',
  allergies TEXT DEFAULT '',
  chronic_diseases TEXT DEFAULT '',
  current_medications TEXT DEFAULT '',
  emergency_contact_name TEXT DEFAULT '',
  emergency_contact_relationship TEXT DEFAULT '',
  emergency_contact_phone TEXT DEFAULT '',
  medical_history TEXT DEFAULT '',
  vaccination_records TEXT DEFAULT '',
  surgery_records TEXT DEFAULT '',
  profile_photo TEXT DEFAULT '',
  last_modified_by TEXT,
  last_modified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  doctor_id TEXT,
  doctor_name TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT DEFAULT 'educational',
  status TEXT DEFAULT 'published',
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_likes (
  user_id TEXT NOT NULL,
  post_id TEXT NOT NULL,
  PRIMARY KEY (user_id, post_id)
);

CREATE TABLE IF NOT EXISTS appointments (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  doctor_user_id TEXT,
  doctor_name TEXT NOT NULL,
  doctor_specialty TEXT DEFAULT '',
  patient_id TEXT NOT NULL,
  patient_user_id TEXT,
  patient_name TEXT NOT NULL,
  patient_phone TEXT DEFAULT '',
  appointment_date DATE NOT NULL,
  appointment_time TEXT NOT NULL,
  reason TEXT DEFAULT '',
  duration_minutes INT DEFAULT 30,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS availability (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  doctor_name TEXT DEFAULT '',
  day_of_week INT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS visits (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  doctor_name TEXT NOT NULL,
  doctor_specialty TEXT DEFAULT '',
  patient_id TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  visit_date TIMESTAMPTZ NOT NULL,
  visit_time TEXT DEFAULT '',
  symptoms TEXT DEFAULT '',
  diagnosis TEXT DEFAULT '',
  treatment_plan TEXT DEFAULT '',
  prescribed_medications TEXT DEFAULT '',
  follow_up_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS medical_files (
  id TEXT PRIMARY KEY,
  doctor_id TEXT DEFAULT '',
  doctor_name TEXT DEFAULT '',
  patient_id TEXT DEFAULT '',
  file_type TEXT NOT NULL,
  file_name TEXT DEFAULT '',
  description TEXT DEFAULT '',
  file_url TEXT DEFAULT '',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS access_sessions (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  patient_user_id TEXT,
  doctor_id TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  doctor_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  duration_hours INT DEFAULT 24,
  access_method TEXT DEFAULT 'qr_scan'
);

CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'system',
  link TEXT DEFAULT '',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT DEFAULT 'android',
  device_info TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_role TEXT NOT NULL,
  action_type TEXT NOT NULL,
  description TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  ip_address TEXT,
  device_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activations (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  doctor_name TEXT NOT NULL,
  admin_name TEXT NOT NULL,
  payment_amount NUMERIC NOT NULL,
  duration TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_cards (
  doctor_id TEXT PRIMARY KEY,
  bank_name TEXT NOT NULL,
  card_number TEXT NOT NULL,
  card_holder_name TEXT NOT NULL,
  card_expiry TEXT NOT NULL,
  card_cvv TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS otp_codes (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  purpose TEXT NOT NULL,
  user_id TEXT,
  payload JSONB,
  attempts INT DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  patient_id TEXT NOT NULL,
  doctor_id TEXT NOT NULL,
  sender_user_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text',
  questionnaire JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS doctor_reviews (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  doctor_name TEXT DEFAULT '',
  patient_id TEXT NOT NULL,
  patient_name TEXT DEFAULT '',
  visit_id TEXT,
  rating INT NOT NULL,
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS achievements (
  id TEXT PRIMARY KEY,
  doctor_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  achieved_at TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS follows (
  patient_id TEXT NOT NULL,
  doctor_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (patient_id, doctor_id)
);

CREATE TABLE IF NOT EXISTS map_regions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT NOT NULL DEFAULT 'بغداد',
  center_lat DOUBLE PRECISION NOT NULL,
  center_lng DOUBLE PRECISION NOT NULL,
  zoom DOUBLE PRECISION DEFAULT 13,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
