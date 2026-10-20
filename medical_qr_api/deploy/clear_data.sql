-- تفريغ بيانات المنصة التجريبية — يُبقي حسابات الإدارة (admin/owner) والإعدادات والمناطق فقط.
-- حذف نهائي لا يمكن التراجع عنه. يُنفَّذ على الخادم:
--   sudo -u postgres psql -d medical_qr -f /tmp/clear_data.sql

BEGIN;

TRUNCATE TABLE
  post_likes,
  post_comments,
  follows,
  achievements,
  doctor_reviews,
  messages,
  device_tokens,
  otp_codes,
  notifications,
  access_sessions,
  medical_files,
  appointments,
  availability,
  visits,
  posts,
  audit_logs,
  activations,
  payment_cards,
  doctors,
  patients;

DELETE FROM users WHERE role NOT IN ('admin','owner');

COMMIT;
