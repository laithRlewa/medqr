const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query, waitForDb, migrate } = require('./db');
const { seedIfEmpty, seedRegionsIfEmpty, id } = require('./seed');
const { toIqIntl, toIqLocal, isIqMobile, phoneLookupValues, sendWhatsappOtp, sendSmsOtp } = require('./otpiq');
const { registerFeatures, extraBootstrap } = require('./features');
const { initFirebaseAdmin, sendPushToUser } = require('./push');
const { registerLegal } = require('./legal');

const app = express();
const PORT = Number(process.env.PORT || 8080);
const JWT_SECRET = process.env.JWT_SECRET || 'medical-qr-dev-secret';

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json({ limit: '12mb' }));

function nid(prefix) {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
}

function sign(user) {
  return jwt.sign({ id: user.id, email: user.email, role: user.role, fullName: user.full_name }, JWT_SECRET);
}

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'يجب تسجيل الدخول' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    return next();
  } catch {
    return res.status(401).json({ error: 'انتهت الجلسة' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) return res.status(403).json({ error: 'غير مصرح' });
    return next();
  };
}

async function audit(user, actionType, description, extra = {}) {
  await query(
    `INSERT INTO audit_logs (id, user_id, user_name, user_role, action_type, description, target_type, target_id, ip_address, device_info)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
    [nid('a'), user.id, user.fullName || user.full_name || 'مستخدم', user.role, actionType, description, extra.targetType || null, extra.targetId || null, extra.ip || null, extra.device || 'API'],
  );
}

async function notify(userId, title, message, type = 'system', link = '') {
  if (!userId) return null;
  const id = nid('n');
  await query(
    `INSERT INTO notifications (id, user_id, title, message, type, link) VALUES ($1,$2,$3,$4,$5,$6)`,
    [id, userId, title, message, type, link],
  );
  sendPushToUser(query, userId, { id, title, message, type, link }).catch((error) => {
    console.error('FCM:', error.message);
  });
  return id;
}

async function notifyAdmins(title, message, type = 'admin', link = '/notifications') {
  const rows = (await query(`SELECT id FROM users WHERE role IN ('admin', 'owner')`)).rows;
  await Promise.all(rows.map((row) => notify(row.id, title, message, type, link)));
}

/** مهلة التعديل/الرفع بعد مسح QR (دقائق). العرض يبقى حسب مدة الجلسة. */
const WRITE_WINDOW_MINUTES = 10;

async function getActiveAccess(doctorId, patientId) {
  const { rows } = await query(
    `SELECT * FROM access_sessions
     WHERE doctor_id=$1 AND patient_id=$2 AND status='active' AND expires_at > NOW()
     ORDER BY granted_at DESC LIMIT 1`,
    [doctorId, patientId],
  );
  return rows[0] || null;
}

async function getWritableQrSession(doctorId, patientId) {
  const { rows } = await query(
    `SELECT * FROM access_sessions
     WHERE doctor_id=$1 AND patient_id=$2 AND status='active' AND expires_at > NOW()
       AND access_method='qr_scan'
       AND granted_at > NOW() - ($3 || ' minutes')::interval
     ORDER BY granted_at DESC LIMIT 1`,
    [doctorId, patientId, String(WRITE_WINDOW_MINUTES)],
  );
  return rows[0] || null;
}

async function assertCanWritePatient(res, doctor, patientId) {
  const session = await getWritableQrSession(doctor.id, patientId);
  if (!session) {
    res.status(403).json({
      error: `انتهت مهلة التعديل (${WRITE_WINDOW_MINUTES} دقائق بعد مسح QR). امسح رمز المريض مجدداً للتعديل أو رفع المستندات.`,
    });
    return false;
  }
  return true;
}

async function notifyProfileVisit(patient, doctor) {
  if (!patient?.user_id) return false;
  const recent = (
    await query(
      `SELECT 1 FROM notifications
       WHERE user_id=$1 AND type='profile_visit' AND message LIKE $2
         AND created_at > NOW() - INTERVAL '15 minutes'
       LIMIT 1`,
      [patient.user_id, `%د. ${doctor.full_name}%`],
    )
  ).rows[0];
  if (recent) return false;
  await notify(
    patient.user_id,
    'زيارة الملف الطبي',
    `د. ${doctor.full_name} زار ملفك الطبي الآن`,
    'profile_visit',
    '/notifications',
  );
  return true;
}

const DEMO_OTP_CODE = '111111';
const DEMO_PHONES = new Set([
  '9647720001122',
  '9647830004455',
  '9647701234567',
  '9647812345678',
  '9647505551212',
  '9647507778899',
]);

function isDemoPhone(phone) {
  return DEMO_PHONES.has(toIqIntl(phone));
}

async function createOtp(identifier, purpose, userId, payload, fixedCode) {
  const code = fixedCode || String(Math.floor(100000 + Math.random() * 900000));
  const otpId = nid('otp');
  await query('DELETE FROM otp_codes WHERE email=$1 AND purpose=$2', [identifier, purpose]);
  await query(
    `INSERT INTO otp_codes (id, email, code, purpose, user_id, payload, expires_at)
     VALUES ($1,$2,$3,$4,$5,$6, NOW() + INTERVAL '5 minutes')`,
    [otpId, identifier, code, purpose, userId || null, payload ? JSON.stringify(payload) : null],
  );
  return { id: otpId, code };
}

async function findUserByPhone(phone) {
  const variants = phoneLookupValues(phone);
  if (!variants.length) return null;
  const { rows } = await query(
    `SELECT * FROM users
     WHERE role IN ('doctor', 'patient')
       AND regexp_replace(COALESCE(phone, ''), '[^0-9]', '', 'g') = ANY($1::text[])
     LIMIT 1`,
    [variants],
  );
  return rows[0] || null;
}

async function findOtp(identifier, purpose) {
  const variants = [...new Set([identifier, toIqIntl(identifier), toIqLocal(identifier)].filter(Boolean))];
  const { rows } = await query(
    `SELECT * FROM otp_codes
     WHERE email = ANY($1::text[])
       AND ($2::text IS NULL OR purpose=$2)
     ORDER BY created_at DESC LIMIT 1`,
    [variants, purpose || null],
  );
  return rows[0] || null;
}

/// قنوات إيصال الرمز بالترتيب. الافتراضي SMS أولاً حتى لا يحتاج المستخدم أي تطبيق إضافي.
const OTP_SENDERS = { sms: sendSmsOtp, whatsapp: sendWhatsappOtp };

function otpChannels() {
  const list = String(process.env.OTP_CHANNELS || 'sms,whatsapp')
    .split(',')
    .map((c) => c.trim())
    .filter((c) => OTP_SENDERS[c]);
  return list.length ? list : ['sms'];
}

async function issuePhoneOtp(phone, purpose, userId, payload) {
  const identifier = toIqIntl(phone);
  const demo = isDemoPhone(identifier);
  const otp = await createOtp(identifier, purpose, userId, payload, demo ? DEMO_OTP_CODE : undefined);
  if (demo) return { ...otp, demo: true };
  let sentChannel = null;
  let lastError = null;
  for (const channel of otpChannels()) {
    try {
      await OTP_SENDERS[channel](identifier, otp.code);
      sentChannel = channel;
      break;
    } catch (error) {
      lastError = error;
      console.warn(`OTP channel=${channel} failed: ${error.message}`);
    }
  }
  if (!sentChannel) {
    await query('DELETE FROM otp_codes WHERE id=$1', [otp.id]);
    throw lastError || new Error('تعذر إرسال رمز التحقق');
  }
  return { ...otp, channel: sentChannel };
}

function otpResponse(phone, purpose, otp) {
  const payload = {
    requiresOtp: true,
    phone: toIqLocal(phone),
    email: toIqIntl(phone),
    purpose,
    channel: isDemoPhone(phone) ? 'demo' : (otp?.channel || 'sms'),
  };
  return payload;
}

async function settingsMap() {
  const { rows } = await query('SELECT key, value FROM settings');
  return Object.fromEntries(rows.map((r) => [r.key, r.value]));
}

app.get('/', (_req, res) => {
  res.json({ service: 'medical-qr-api', health: '/api/health' });
});

app.get('/api/health', async (_req, res) => {
  try {
    await query('SELECT 1');
    res.json({
      ok: true,
      service: 'medical-qr-api',
      db: 'up',
      otpiq: Boolean(process.env.OTPIQ_API_KEY),
    });
  } catch {
    res.status(500).json({ ok: false, db: 'down' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const { rows } = await query('SELECT * FROM users WHERE LOWER(email)=$1', [email]);
  const user = rows[0];
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' });
  }
  if (user.role !== 'admin' && user.role !== 'owner') {
    return res.status(403).json({ error: 'الأطباء والمرضى يدخلون برقم الهاتف ورمز التحقق فقط' });
  }
  await audit(user, 'login', 'تسجيل دخول المدير', { ip: req.ip });
  return res.json({ token: sign(user), user: publicUser(user), requiresOtp: false });
});

app.post('/api/auth/otp/request', async (req, res) => {
  try {
    const phone = String(req.body.phone || '').trim();
    if (!isIqMobile(phone)) return res.status(400).json({ error: 'رقم هاتف غير صالح (07XXXXXXXXX)' });
    const user = await findUserByPhone(phone);
    if (!user) return res.status(400).json({ error: 'لا يوجد حساب بهذا الرقم' });
    const otp = await issuePhoneOtp(user.phone || phone, 'login', user.id);
    return res.json(otpResponse(user.phone || phone, 'login', otp));
  } catch (error) {
    return res.status(error.status || 500).json({ error: error.message || 'تعذر إرسال رمز التحقق' });
  }
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const body = req.body || {};
    const phone = String(body.phone || '').trim();
    if (!body.fullName) return res.status(400).json({ error: 'الاسم مطلوب' });
    if (!isIqMobile(phone)) return res.status(400).json({ error: 'رقم هاتف غير صالح (07XXXXXXXXX)' });
    if (body.role === 'doctor' && !String(body.licenseNumber || '').trim()) {
      return res.status(400).json({ error: 'رقم الترخيص مطلوب' });
    }
    if (await findUserByPhone(phone)) return res.status(400).json({ error: 'هذا الرقم مسجّل مسبقاً' });
    const email = String(body.email || '').trim().toLowerCase() || `${toIqIntl(phone)}@phone.medical.iq`;
    if (body.email) {
      const exists = await query('SELECT id FROM users WHERE LOWER(email)=$1', [email]);
      if (exists.rows[0]) return res.status(400).json({ error: 'هذا البريد مسجّل مسبقاً' });
    }
    const otp = await issuePhoneOtp(phone, 'register', null, { ...body, phone: toIqLocal(phone), email });
    return res.json(otpResponse(phone, 'register', otp));
  } catch (error) {
    return res.status(error.status || 500).json({ error: error.message || 'تعذر إرسال رمز التحقق' });
  }
});

app.post('/api/auth/otp/resend', async (req, res) => {
  try {
    const identifier = String(req.body.phone || req.body.email || '').trim();
    const purpose = String(req.body.purpose || 'login');
    const prev = await findOtp(identifier, purpose);
    if (!prev) return res.status(400).json({ error: 'لا توجد عملية تحقق نشطة' });
    const otp = await issuePhoneOtp(prev.email, prev.purpose, prev.user_id, prev.payload);
    return res.json(otpResponse(prev.email, prev.purpose, otp));
  } catch (error) {
    return res.status(error.status || 500).json({ error: error.message || 'تعذر إرسال رمز التحقق' });
  }
});

app.post('/api/auth/otp/verify', async (req, res) => {
  const identifier = String(req.body.phone || req.body.email || '').trim();
  const code = String(req.body.code || '').trim();
  let otp = await findOtp(identifier);
  if (!otp && isDemoPhone(identifier) && code === DEMO_OTP_CODE) {
    // الحسابات التجريبية تقبل الرمز الثابت حتى لو انتهت أو استُهلكت جلسة التحقق.
    const demoUser = await findUserByPhone(identifier);
    if (demoUser) {
      await audit(demoUser, 'login', 'تسجيل دخول تجريبي', { ip: req.ip });
      return res.json({ token: sign(demoUser), user: publicUser(demoUser), requiresOtp: false });
    }
    otp = null;
  }
  if (!otp) return res.status(400).json({ error: 'لا توجد عملية تحقق نشطة' });
  if (new Date(otp.expires_at) < new Date()) return res.status(400).json({ error: 'انتهت صلاحية الرمز. أعد الإرسال' });
  if (otp.attempts >= 5) return res.status(400).json({ error: 'تجاوزت عدد المحاولات' });
  if (otp.code !== code) {
    await query('UPDATE otp_codes SET attempts = attempts + 1 WHERE id=$1', [otp.id]);
    return res.status(400).json({ error: `رمز التحقق غير صحيح (${5 - otp.attempts - 1} محاولات متبقية)` });
  }
  await query('DELETE FROM otp_codes WHERE id=$1', [otp.id]);

  if (otp.purpose === 'register') {
    const data = typeof otp.payload === 'string' ? JSON.parse(otp.payload) : (otp.payload || {});
    const userId = nid('u');
    const role = data.role === 'doctor' ? 'doctor' : 'patient';
    const phone = toIqLocal(data.phone || otp.email);
    const email = String(data.email || `${toIqIntl(phone)}@phone.medical.iq`).toLowerCase();
    await query(
      `INSERT INTO users (id, email, password_hash, full_name, role, phone) VALUES ($1,$2,$3,$4,$5,$6)`,
      [userId, email, bcrypt.hashSync(nid('otp-pass'), 10), data.fullName, role, phone],
    );
    if (role === 'patient') {
      const codeId = `IQ-P-${24000 + Math.floor(Math.random() * 900)}`;
      await query(
        `INSERT INTO patients (id, user_id, full_name, patient_id, qr_code_data, phone, email, city, gender, blood_type, date_of_birth)
         VALUES ($1,$2,$3,$4,$4,$5,$6,$7,$8,$9,$10)`,
        [nid('p'), userId, data.fullName, codeId, phone, email, data.city || 'بغداد', data.gender || 'Male', data.bloodType || 'O+', data.dateOfBirth || ''],
      );
    } else {
      await query(
        `INSERT INTO doctors (id, user_id, full_name, specialty, clinic_name, city, phone, email, license_number, status, subscription_status, gender, date_of_birth, years_of_experience, biography, qualifications, working_hours, profile_photo)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending','inactive',$10,$11,$12,$13,$14,$15,$16)`,
        [
          nid('d'), userId, data.fullName, data.specialty || 'طب عام', data.clinicName || 'عيادة خاصة', data.city || 'بغداد',
          phone, email, data.licenseNumber || '', data.gender || 'Male', data.dateOfBirth || '',
          Number(data.yearsOfExperience || 0), data.biography || '', data.qualifications || '', data.workingHours || '', data.profilePhoto || '',
        ],
      );
    }
    const created = (await query('SELECT * FROM users WHERE id=$1', [userId])).rows[0];
    await audit(created, 'login', 'تسجيل حساب جديد', { ip: req.ip });
    if (role === 'doctor') {
      await notify(userId, 'طلبك قيد المراجعة', 'استلمنا طلب انضمامك كطبيب. سنراجع الشهادات ونُعلمك عند الاعتماد.', 'system', '/profile');
      await notifyAdmins('طبيب جديد بانتظار المراجعة', `${data.fullName} قدّم طلباً للانضمام كطبيب.`, 'admin', '/notifications');
    } else {
      await notify(userId, 'أهلاً بك في MED QR', 'حسابك جاهز. احفظ رمزك الطبي واستخدمه في عيادتك القادمة.', 'welcome', '/notifications');
    }
    return res.json({ token: sign(created), user: publicUser(created), requiresOtp: false });
  }

  const user = (await query('SELECT * FROM users WHERE id=$1', [otp.user_id])).rows[0];
  await audit(user, 'login', 'تسجيل دخول بعد OTP', { ip: req.ip });
  return res.json({ token: sign(user), user: publicUser(user), requiresOtp: false });
});

app.post('/api/auth/password/reset', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  if (password.length < 6) return res.status(400).json({ error: 'كلمة المرور قصيرة' });
  const { rowCount } = await query('UPDATE users SET password_hash=$1 WHERE LOWER(email)=$2', [bcrypt.hashSync(password, 10), email]);
  if (!rowCount) return res.status(400).json({ error: 'الحساب غير موجود' });
  res.json({ ok: true });
});

app.post('/api/auth/refresh', async (req, res) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : String(req.body?.token || '');
  if (!token) return res.status(401).json({ error: 'يجب تسجيل الدخول' });
  let payload;
  try {
    payload = jwt.verify(token, JWT_SECRET, { ignoreExpiration: true });
  } catch {
    return res.status(401).json({ error: 'انتهت الجلسة' });
  }
  const user = (await query('SELECT * FROM users WHERE id=$1', [payload.id])).rows[0];
  if (!user) return res.status(401).json({ error: 'الحساب غير موجود' });
  return res.json({ token: sign(user), user: publicUser(user) });
});

app.get('/api/me', auth, async (req, res) => {
  const user = (await query('SELECT * FROM users WHERE id=$1', [req.user.id])).rows[0];
  res.json({ user: publicUser(user) });
});

app.patch('/api/me', auth, async (req, res) => {
  const b = req.body || {};
  await query(
    `UPDATE users SET full_name=COALESCE($1,full_name), phone=COALESCE($2,phone), profile_photo=COALESCE($3,profile_photo),
     language_preference=COALESCE($4,language_preference), notify_email=COALESCE($5,notify_email), notify_sms=COALESCE($6,notify_sms),
     notify_push=COALESCE($8,notify_push)
     WHERE id=$7`,
    [b.fullName || null, b.phone || null, b.profilePhoto || null, b.languagePreference || null, b.notifyEmail ?? null, b.notifySms ?? null, req.user.id, b.notifyPush ?? null],
  );
  if (b.currentPassword && b.nextPassword) {
    const user = (await query('SELECT * FROM users WHERE id=$1', [req.user.id])).rows[0];
    if (!bcrypt.compareSync(b.currentPassword, user.password_hash)) {
      return res.status(400).json({ error: 'كلمة المرور الحالية غير صحيحة' });
    }
    await query('UPDATE users SET password_hash=$1 WHERE id=$2', [bcrypt.hashSync(b.nextPassword, 10), req.user.id]);
  }
  const user = (await query('SELECT * FROM users WHERE id=$1', [req.user.id])).rows[0];
  res.json({ user: publicUser(user) });
});

app.get('/api/bootstrap', auth, async (req, res) => {
  const user = (await query('SELECT * FROM users WHERE id=$1', [req.user.id])).rows[0];
  const settings = await settingsMap();
  const doctors = (await query('SELECT * FROM doctors ORDER BY created_at DESC')).rows.map(mapDoctor);
  const patients = (await query('SELECT * FROM patients ORDER BY created_at DESC')).rows.map(mapPatient);
  const regions = (await query('SELECT * FROM map_regions WHERE is_active=TRUE ORDER BY sort_order, name')).rows.map(mapRegion);
  const posts = (await query('SELECT * FROM posts ORDER BY created_at DESC')).rows.map(mapPost);
  const comments = (await query('SELECT * FROM post_comments ORDER BY created_at')).rows.map(mapComment);
  const visits = (await query('SELECT * FROM visits ORDER BY visit_date DESC')).rows.map(mapVisit);
  const files = (await query('SELECT * FROM medical_files ORDER BY created_at DESC')).rows.map(mapFile);
  const sessions = (await query('SELECT * FROM access_sessions ORDER BY granted_at DESC')).rows.map(mapSession);
  const availability = (await query('SELECT * FROM availability ORDER BY day_of_week')).rows.map(mapAvailability);
  const appointments = (await query('SELECT * FROM appointments ORDER BY appointment_date DESC, appointment_time DESC')).rows.map(mapAppointment);
  const notifications = (await query('SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC', [user.id])).rows.map(mapNotification);
  const payload = {
    user: publicUser(user),
    branding: settings,
    doctors,
    patients,
    regions,
    posts,
    comments,
    visits,
    files,
    sessions,
    availability,
    appointments,
    notifications,
  };
  if (user.role === 'admin' || user.role === 'owner') {
    payload.audit = (await query('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 200')).rows.map(mapAudit);
    payload.activations = (await query('SELECT * FROM activations ORDER BY created_at DESC')).rows.map(mapActivation);
    payload.users = (await query('SELECT id, email, role, created_at FROM users ORDER BY created_at DESC')).rows.map(mapPlatformUser);
    payload.notifications = (await query('SELECT * FROM notifications ORDER BY created_at DESC LIMIT 200')).rows.map(mapNotification);
  }
  Object.assign(payload, await extraBootstrap(query, user));
  res.json(payload);
});

/// بيانات التصفح العامة — بلا حساب: الأطباء المعتمدون، المناطق، المنشورات، التوفر، التقييمات.
/// لا تُعيد أي بيانات مرضى أو جلسات أو ملفات.
app.get('/api/public/bootstrap', async (_req, res) => {
  try {
    const settings = await settingsMap();
    const doctors = (await query(`SELECT * FROM doctors WHERE status='approved' ORDER BY created_at DESC`)).rows.map(mapDoctor);
    const regions = (await query('SELECT * FROM map_regions WHERE is_active=TRUE ORDER BY sort_order, name')).rows.map(mapRegion);
    const posts = (await query('SELECT * FROM posts ORDER BY created_at DESC')).rows.map(mapPost);
    const comments = (await query('SELECT * FROM post_comments ORDER BY created_at')).rows.map(mapComment);
    const availability = (await query('SELECT * FROM availability ORDER BY day_of_week')).rows.map(mapAvailability);
    res.json({ branding: settings, doctors, regions, posts, comments, availability });
  } catch (error) {
    res.status(500).json({ error: 'تعذر تحميل البيانات' });
  }
});

app.patch('/api/doctors/:id', auth, requireRole('admin', 'owner', 'doctor'), async (req, res) => {
  const current = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
  if (!current) return res.status(404).json({ error: 'الطبيب غير موجود' });
  if (req.user.role === 'doctor' && current.user_id !== req.user.id) return res.status(403).json({ error: 'غير مصرح' });
  const b = req.body || {};
  const nextStatus = req.user.role === 'doctor' ? current.status : (b.status || current.status);
  const nextRegionId = Object.prototype.hasOwnProperty.call(b, 'regionId') ? (b.regionId || null) : current.region_id;
  const nextLat = Object.prototype.hasOwnProperty.call(b, 'latitude') ? (b.latitude == null ? null : Number(b.latitude)) : current.latitude;
  const nextLng = Object.prototype.hasOwnProperty.call(b, 'longitude') ? (b.longitude == null ? null : Number(b.longitude)) : current.longitude;
  await query(
    `UPDATE doctors SET
      full_name=COALESCE($1,full_name), phone=COALESCE($2,phone), email=COALESCE($3,email), specialty=COALESCE($4,specialty),
      clinic_name=COALESCE($5,clinic_name), city=COALESCE($6,city), license_number=COALESCE($7,license_number),
      biography=COALESCE($8,biography), working_hours=COALESCE($9,working_hours), qualifications=COALESCE($10,qualifications),
      years_of_experience=COALESCE($11,years_of_experience), certificates=COALESCE($12,certificates),
      gender=COALESCE($16,gender), date_of_birth=COALESCE($17,date_of_birth), profile_photo=COALESCE($18,profile_photo),
      featured=COALESCE($19,featured),
      region_id=$20,
      latitude=$21,
      longitude=$22,
      status=$13, last_modified_by=$14, last_modified_at=NOW()
     WHERE id=$15`,
    [
      b.fullName, b.phone, b.email, b.specialty, b.clinicName, b.city, b.licenseNumber, b.biography, b.workingHours,
      b.qualifications, b.yearsOfExperience, b.certificates || null, nextStatus, req.user.fullName, req.params.id,
      b.gender, b.dateOfBirth, b.profilePhoto, req.user.role === 'doctor' ? null : (b.featured ?? null),
      nextRegionId, nextLat, nextLng,
    ],
  );
  await audit(req.user, req.user.role === 'admin' ? 'admin_action' : 'profile_update', `تحديث ملف الطبيب ${current.full_name}`, { targetType: 'Doctor', targetId: current.id });
  const doctor = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
  res.json({ doctor: mapDoctor(doctor) });
});

app.post('/api/doctors/:id/approve', auth, requireRole('admin', 'owner'), async (req, res) => {
  await query(`UPDATE doctors SET status='approved' WHERE id=$1`, [req.params.id]);
  const doctor = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
  await audit(req.user, 'admin_action', `تمت الموافقة على الطبيب: ${doctor.full_name}`, { targetType: 'Doctor', targetId: doctor.id });
  await notify(doctor.user_id, 'تمت الموافقة على الحساب', 'تمت الموافقة على حسابك كطبيب. يمكنك الآن استقبال المرضى وإدارة عيادتك.', 'system', '/profile');
  res.json({ doctor: mapDoctor(doctor) });
});

app.post('/api/doctors/:id/suspend', auth, requireRole('admin', 'owner'), async (req, res) => {
  await query(`UPDATE doctors SET status='suspended' WHERE id=$1`, [req.params.id]);
  const doctor = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
  await audit(req.user, 'admin_action', `تم تعليق الطبيب: ${doctor.full_name}`, { targetType: 'Doctor', targetId: doctor.id });
  await notify(doctor.user_id, 'تم تعليق حسابك', 'علّقت الإدارة حسابك مؤقتاً. تواصل معنا إن كان ذلك عن طريق الخطأ.', 'system', '/profile');
  res.json({ doctor: mapDoctor(doctor) });
});

app.post('/api/doctors/:id/activate', auth, requireRole('admin', 'owner'), async (req, res) => {
  const months = Number(req.body.months || 1);
  const amount = Number(req.body.amount || 0);
  const duration = req.body.duration || '1_month';
  const doctor = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
  if (!doctor) return res.status(404).json({ error: 'الطبيب غير موجود' });
  await query(
    `UPDATE doctors SET subscription_status='active', subscription_start=NOW(), subscription_end=NOW() + ($1 || ' months')::interval,
     subscription_duration=$2, payment_amount=$3 WHERE id=$4`,
    [String(months), duration, amount, doctor.id],
  );
  const updated = (await query('SELECT * FROM doctors WHERE id=$1', [doctor.id])).rows[0];
  await query(
    `INSERT INTO activations (id, doctor_id, doctor_name, admin_name, payment_amount, duration, start_date, end_date, action)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
    [nid('al'), doctor.id, doctor.full_name, req.user.fullName, amount, duration, updated.subscription_start, updated.subscription_end, doctor.subscription_status === 'active' ? 'reactivate' : 'activate'],
  );
  await audit(req.user, 'admin_action', `تم تفعيل اشتراك الطبيب: ${doctor.full_name}`, { targetType: 'Doctor', targetId: doctor.id });
  await notify(doctor.user_id, 'تم تفعيل اشتراكك', `تم تفعيل اشتراكك حتى ${updated.subscription_end}`, 'access_granted', '/profile');
  res.json({ doctor: mapDoctor(updated) });
});

app.patch('/api/patients/:id', auth, async (req, res) => {
  const current = (await query('SELECT * FROM patients WHERE id=$1', [req.params.id])).rows[0];
  if (!current) return res.status(404).json({ error: 'المريض غير موجود' });
  if (req.user.role === 'patient' && current.user_id !== req.user.id) return res.status(403).json({ error: 'غير مصرح' });
  const b = req.body || {};
  await query(
    `UPDATE patients SET full_name=COALESCE($1,full_name), phone=COALESCE($2,phone), email=COALESCE($3,email), city=COALESCE($4,city),
     gender=COALESCE($5,gender), blood_type=COALESCE($6,blood_type), date_of_birth=COALESCE($7,date_of_birth),
     allergies=COALESCE($8,allergies), chronic_diseases=COALESCE($9,chronic_diseases), current_medications=COALESCE($10,current_medications),
     emergency_contact_name=COALESCE($11,emergency_contact_name), emergency_contact_phone=COALESCE($12,emergency_contact_phone),
     emergency_contact_relationship=COALESCE($13,emergency_contact_relationship), medical_history=COALESCE($14,medical_history),
     national_id=COALESCE($15,national_id), status=COALESCE($16,status),
     vaccination_records=COALESCE($19,vaccination_records), surgery_records=COALESCE($20,surgery_records),
     profile_photo=COALESCE($21,profile_photo),
     last_modified_by=$17, last_modified_at=NOW() WHERE id=$18`,
    [b.fullName, b.phone, b.email, b.city, b.gender, b.bloodType, b.dateOfBirth, b.allergies, b.chronicDiseases, b.currentMedications, b.emergencyContactName, b.emergencyContactPhone, b.emergencyContactRelationship, b.medicalHistory, b.nationalId, req.user.role === 'patient' ? current.status : (b.status || current.status), req.user.fullName, req.params.id, b.vaccinationRecords, b.surgeryRecords, b.profilePhoto],
  );
  const patient = (await query('SELECT * FROM patients WHERE id=$1', [req.params.id])).rows[0];
  res.json({ patient: mapPatient(patient) });
});

app.post('/api/appointments', auth, async (req, res) => {
  const b = req.body || {};
  const row = {
    id: nid('ap'),
    doctor_id: b.doctorId,
    doctor_user_id: b.doctorUserId,
    doctor_name: b.doctorName,
    doctor_specialty: b.doctorSpecialty || '',
    patient_id: b.patientId,
    patient_user_id: b.patientUserId || req.user.id,
    patient_name: b.patientName,
    patient_phone: b.patientPhone || '',
    appointment_date: b.appointmentDate,
    appointment_time: b.appointmentTime,
    reason: b.reason || '',
    status: 'pending',
  };
  await query(
    `INSERT INTO appointments (id, doctor_id, doctor_user_id, doctor_name, doctor_specialty, patient_id, patient_user_id, patient_name, patient_phone, appointment_date, appointment_time, reason, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'pending')`,
    [row.id, row.doctor_id, row.doctor_user_id, row.doctor_name, row.doctor_specialty, row.patient_id, row.patient_user_id, row.patient_name, row.patient_phone, row.appointment_date, row.appointment_time, row.reason],
  );
  await notify(row.doctor_user_id, 'طلب موعد جديد', `${row.patient_name} طلب موعداً في ${row.appointment_date} الساعة ${row.appointment_time}.`, 'appointment', '/appointments');
  const created = (await query('SELECT * FROM appointments WHERE id=$1', [row.id])).rows[0];
  res.json({ appointment: mapAppointment(created) });
});

app.patch('/api/appointments/:id', auth, async (req, res) => {
  const b = req.body || {};
  await query(
    `UPDATE appointments SET
      status=COALESCE($1,status),
      appointment_date=COALESCE($2,appointment_date),
      appointment_time=COALESCE($3,appointment_time),
      notes=COALESCE($4,notes),
      reason=COALESCE($5,reason)
     WHERE id=$6`,
    [b.status || null, b.appointmentDate || null, b.appointmentTime || null, b.notes, b.reason, req.params.id],
  );
  const appt = (await query('SELECT * FROM appointments WHERE id=$1', [req.params.id])).rows[0];
  if (b.status === 'confirmed') await notify(appt.patient_user_id, 'تم تأكيد الموعد', `أكد د. ${appt.doctor_name} موعدك في ${appt.appointment_date} الساعة ${appt.appointment_time}.`, 'appointment', '/appointments');
  if (b.status === 'declined') await notify(appt.patient_user_id, 'تم رفض الموعد', `رفض د. ${appt.doctor_name} طلب موعدك.`, 'appointment', '/appointments');
  if (b.status === 'completed') await notify(appt.patient_user_id, 'اكتملت الزيارة', `أُغلقت زيارة د. ${appt.doctor_name}. راجع السجل الطبي للمتابعة.`, 'appointment', '/my-records');
  if (b.status === 'cancelled') {
    const other = req.user.role === 'doctor' ? appt.patient_user_id : appt.doctor_user_id;
    await notify(other, 'إلغاء موعد', `تم إلغاء موعد ${appt.appointment_date}`, 'appointment', '/appointments');
  }
  if ((b.appointmentDate || b.appointmentTime) && b.status !== 'cancelled') {
    await notify(appt.patient_user_id, 'تم تعديل الموعد', `تم تغيير موعدك إلى ${appt.appointment_date} الساعة ${appt.appointment_time}`, 'appointment', '/appointments');
  }
  res.json({ appointment: mapAppointment(appt) });
});

app.post('/api/availability', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  const itemId = nid('av');
  await query(
    `INSERT INTO availability (id, doctor_id, doctor_name, day_of_week, start_time, end_time) VALUES ($1,$2,$3,$4,$5,$6)`,
    [itemId, doctor.id, doctor.full_name, req.body.dayOfWeek, req.body.startTime, req.body.endTime],
  );
  const row = (await query('SELECT * FROM availability WHERE id=$1', [itemId])).rows[0];
  res.json({ slot: mapAvailability(row) });
});

app.patch('/api/availability/:id', auth, requireRole('doctor'), async (req, res) => {
  await query('UPDATE availability SET is_available=$1 WHERE id=$2', [req.body.isAvailable, req.params.id]);
  const row = (await query('SELECT * FROM availability WHERE id=$1', [req.params.id])).rows[0];
  res.json({ slot: mapAvailability(row) });
});

app.delete('/api/availability/:id', auth, requireRole('doctor'), async (req, res) => {
  await query('DELETE FROM availability WHERE id=$1', [req.params.id]);
  res.json({ ok: true });
});

app.post('/api/access', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  const patient = (await query('SELECT * FROM patients WHERE id=$1 OR patient_id=$1 OR qr_code_data=$1', [req.body.patientId || req.body.qr])).rows[0];
  if (!patient) return res.status(404).json({ error: 'لم يتم العثور على مريض' });
  const method = req.body.method || 'qr_scan';
  const existing = await getActiveAccess(doctor.id, patient.id);

  if (existing) {
    // مسح QR مجدداً يجدد مهلة التعديل 10 دقائق.
    if (method === 'qr_scan') {
      await query(
        `UPDATE access_sessions SET granted_at=NOW(), access_method='qr_scan' WHERE id=$1`,
        [existing.id],
      );
      const updated = (await query('SELECT * FROM access_sessions WHERE id=$1', [existing.id])).rows[0];
      await notifyProfileVisit(patient, doctor);
      return res.json({
        session: mapSession(updated),
        patient: mapPatient(patient),
        writeWindowMinutes: WRITE_WINDOW_MINUTES,
      });
    }
    await notifyProfileVisit(patient, doctor);
    return res.json({ session: mapSession(existing), patient: mapPatient(patient), writeWindowMinutes: WRITE_WINDOW_MINUTES });
  }

  const hours = Number((await settingsMap()).access_duration_hours || 24);
  const sid = nid('s');
  await query(
    `INSERT INTO access_sessions (id, patient_id, patient_user_id, doctor_id, patient_name, doctor_name, status, expires_at, duration_hours, access_method)
     VALUES ($1,$2,$3,$4,$5,$6,'active', NOW() + ($7 || ' hours')::interval, $7, $8)`,
    [sid, patient.id, patient.user_id, doctor.id, patient.full_name, doctor.full_name, String(hours), method],
  );
  await notify(patient.user_id, 'تم منح الوصول', `تم منح د. ${doctor.full_name} صلاحية الوصول إلى سجلاتك الطبية`, 'access_granted', '/notifications');
  if (method === 'qr_scan') {
    await notify(patient.user_id, 'زيارة الملف الطبي', `د. ${doctor.full_name} زار ملفك الطبي عبر مسح QR`, 'profile_visit', '/notifications');
  }
  await audit(req.user, 'access_create', `تم إنشاء جلسة وصول للمريض ${patient.full_name}`, { targetType: 'Patient', targetId: patient.id });
  const session = (await query('SELECT * FROM access_sessions WHERE id=$1', [sid])).rows[0];
  res.json({ session: mapSession(session), patient: mapPatient(patient), writeWindowMinutes: WRITE_WINDOW_MINUTES });
});

app.post('/api/access/view', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  const patient = (await query('SELECT * FROM patients WHERE id=$1 OR patient_id=$1 OR qr_code_data=$1', [req.body.patientId])).rows[0];
  if (!doctor || !patient) return res.status(404).json({ error: 'غير موجود' });
  const session = await getActiveAccess(doctor.id, patient.id);
  if (!session) return res.status(403).json({ error: 'لا توجد جلسة وصول نشطة' });
  const notified = await notifyProfileVisit(patient, doctor);
  const writable = await getWritableQrSession(doctor.id, patient.id);
  res.json({
    ok: true,
    notified,
    canWrite: !!writable,
    writeWindowMinutes: WRITE_WINDOW_MINUTES,
    writeExpiresAt: writable ? new Date(new Date(writable.granted_at).getTime() + WRITE_WINDOW_MINUTES * 60 * 1000).toISOString() : null,
  });
});

app.post('/api/visits', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  const b = req.body || {};
  if (!(await assertCanWritePatient(res, doctor, b.patientId))) return;
  const vid = nid('v');
  await query(
    `INSERT INTO visits (id, doctor_id, doctor_name, doctor_specialty, patient_id, patient_name, visit_date, visit_time, symptoms, diagnosis, treatment_plan, prescribed_medications, follow_up_notes)
     VALUES ($1,$2,$3,$4,$5,$6,NOW(),$7,$8,$9,$10,$11,$12)`,
    [vid, doctor.id, doctor.full_name, doctor.specialty, b.patientId, b.patientName, b.visitTime || '', b.symptoms || '', b.diagnosis || '', b.treatmentPlan || '', b.medications || '', b.followUp || ''],
  );
  const patientUserId = b.patientUserId || (await query('SELECT user_id FROM patients WHERE id=$1', [b.patientId])).rows[0]?.user_id;
  if (b.diagnosis) await notify(patientUserId, 'تشخيص جديد', `أضاف د. ${doctor.full_name} تشخيصاً جديداً`, 'diagnosis', '/my-records');
  if (b.medications) await notify(patientUserId, 'وصفة طبية جديدة', `وصف د. ${doctor.full_name} أدوية جديدة`, 'prescription', '/my-records');
  if (!b.diagnosis && !b.medications) {
    await notify(patientUserId, 'زيارة جديدة', `سجّل د. ${doctor.full_name} زيارة في ملفك الطبي`, 'visit', '/my-records');
  }
  await audit(req.user, 'visit_create', `تم إنشاء زيارة لـ ${b.patientName}`, { targetType: 'Visit', targetId: vid });
  const visit = (await query('SELECT * FROM visits WHERE id=$1', [vid])).rows[0];
  res.json({ visit: mapVisit(visit) });
});

app.patch('/api/visits/:id', auth, requireRole('doctor'), async (req, res) => {
  const current = (await query('SELECT * FROM visits WHERE id=$1', [req.params.id])).rows[0];
  if (!current) return res.status(404).json({ error: 'الزيارة غير موجودة' });
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  if (current.doctor_id !== doctor.id) return res.status(403).json({ error: 'يمكنك تعديل سجلاتك فقط' });
  if (!(await assertCanWritePatient(res, doctor, current.patient_id))) return;
  const hours = Number((await settingsMap()).diagnosis_edit_hours || 24);
  const deadline = new Date(new Date(current.created_at).getTime() + hours * 60 * 60 * 1000);
  if (new Date() > deadline) return res.status(400).json({ error: 'انتهت مدة التعديل. تم قفل هذا التشخيص.' });
  const latest = (await query('SELECT id FROM visits WHERE patient_id=$1 AND doctor_id=$2 ORDER BY created_at DESC LIMIT 1', [current.patient_id, doctor.id])).rows[0];
  if (latest && latest.id !== current.id) return res.status(400).json({ error: 'يمكن تعديل آخر زيارة فقط' });
  const b = req.body || {};
  await query(
    `UPDATE visits SET symptoms=COALESCE($1,symptoms), diagnosis=COALESCE($2,diagnosis), treatment_plan=COALESCE($3,treatment_plan),
     prescribed_medications=COALESCE($4,prescribed_medications), follow_up_notes=COALESCE($5,follow_up_notes) WHERE id=$6`,
    [b.symptoms, b.diagnosis, b.treatmentPlan, b.medications, b.followUp, req.params.id],
  );
  await audit(req.user, 'diagnosis_edit', `تم تعديل زيارة لـ ${current.patient_name}`, { targetType: 'Visit', targetId: current.id });
  const visit = (await query('SELECT * FROM visits WHERE id=$1', [req.params.id])).rows[0];
  res.json({ visit: mapVisit(visit) });
});

app.post('/api/files', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  if (!(await assertCanWritePatient(res, doctor, req.body.patientId))) return;
  const fid = nid('f');
  await query(
    `INSERT INTO medical_files (id, doctor_id, doctor_name, patient_id, file_type, file_name, description, file_url, visit_id, doctor_specialty)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
    [fid, doctor.id, doctor.full_name, req.body.patientId, req.body.fileType, req.body.fileName || '', req.body.description || '', req.body.fileUrl || '', req.body.visitId || '', doctor.specialty || ''],
  );
  const patient = (await query('SELECT user_id FROM patients WHERE id=$1', [req.body.patientId])).rows[0];
  await notify(patient?.user_id, 'ملف طبي جديد', `أضاف د. ${doctor.full_name} ملفاً طبياً`, 'file', '/my-records');
  await audit(req.user, 'file_upload', `رفع ملف للمريض`, { targetType: 'MedicalFile', targetId: fid });
  const file = (await query('SELECT * FROM medical_files WHERE id=$1', [fid])).rows[0];
  res.json({ file: mapFile(file) });
});

app.post('/api/posts', auth, requireRole('doctor'), async (req, res) => {
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  const pid = nid('po');
  await query(
    `INSERT INTO posts (id, doctor_id, doctor_name, content, category, images, doctor_specialty, doctor_photo)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
    [pid, doctor.id, doctor.full_name, req.body.content, req.body.category || 'educational', req.body.images || [], doctor.specialty || '', doctor.profile_photo || ''],
  );
  const post = (await query('SELECT * FROM posts WHERE id=$1', [pid])).rows[0];
  const followers = (await query(
    `SELECT p.user_id FROM follows f JOIN patients p ON p.id = f.patient_id WHERE f.doctor_id=$1 AND p.user_id IS NOT NULL`,
    [doctor.id],
  )).rows;
  await Promise.all(followers.map((row) => notify(row.user_id, 'منشور جديد', `د. ${doctor.full_name} نشر محتوى جديداً`, 'post', '/social')));
  res.json({ post: mapPost(post) });
});

app.post('/api/posts/:id/like', auth, async (req, res) => {
  const existing = (await query('SELECT 1 FROM post_likes WHERE user_id=$1 AND post_id=$2', [req.user.id, req.params.id])).rows[0];
  if (existing) {
    await query('DELETE FROM post_likes WHERE user_id=$1 AND post_id=$2', [req.user.id, req.params.id]);
    await query('UPDATE posts SET likes_count = GREATEST(likes_count-1,0) WHERE id=$1', [req.params.id]);
  } else {
    await query('INSERT INTO post_likes (user_id, post_id) VALUES ($1,$2)', [req.user.id, req.params.id]);
    await query('UPDATE posts SET likes_count = likes_count+1 WHERE id=$1', [req.params.id]);
  }
  const post = (await query('SELECT * FROM posts WHERE id=$1', [req.params.id])).rows[0];
  res.json({ post: mapPost(post), liked: !existing });
});

app.post('/api/posts/:id/comments', auth, requireRole('doctor', 'admin', 'owner'), async (req, res) => {
  const cid = nid('c');
  const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
  await query(
    'INSERT INTO post_comments (id, post_id, author_name, content, doctor_id, doctor_photo) VALUES ($1,$2,$3,$4,$5,$6)',
    [cid, req.params.id, req.user.fullName, req.body.content, doctor?.id || null, doctor?.profile_photo || ''],
  );
  await query('UPDATE posts SET comments_count = comments_count+1 WHERE id=$1', [req.params.id]);
  const comment = (await query('SELECT * FROM post_comments WHERE id=$1', [cid])).rows[0];
  const post = (await query('SELECT doctor_id FROM posts WHERE id=$1', [req.params.id])).rows[0];
  if (post && doctor?.id !== post.doctor_id) {
    const author = (await query('SELECT user_id FROM doctors WHERE id=$1', [post.doctor_id])).rows[0];
    await notify(author?.user_id, 'تعليق جديد', `${req.user.fullName} علّق على منشورك`, 'post', '/social');
  }
  res.json({ comment: mapComment(comment) });
});

app.post('/api/posts/:id/archive', auth, requireRole('admin', 'owner'), async (req, res) => {
  await query(`UPDATE posts SET status='archived' WHERE id=$1`, [req.params.id]);
  await audit(req.user, 'admin_action', 'أرشفة منشور', { targetType: 'Post', targetId: req.params.id });
  res.json({ ok: true });
});

app.patch('/api/settings/:key', auth, requireRole('admin', 'owner'), async (req, res) => {
  await query(
    `INSERT INTO settings (key, value) VALUES ($1,$2) ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value`,
    [req.params.key, String(req.body.value ?? '')],
  );
  await audit(req.user, 'admin_action', `تم تحديث الإعداد: ${req.params.key}`, { targetType: 'AppSettings', targetId: req.params.key });
  res.json({ branding: await settingsMap() });
});

app.post('/api/notifications/:id/read', auth, async (req, res) => {
  await query('UPDATE notifications SET is_read=TRUE WHERE id=$1', [req.params.id]);
  res.json({ ok: true });
});

app.post('/api/notifications/read-all', auth, async (req, res) => {
  await query('UPDATE notifications SET is_read=TRUE WHERE user_id=$1', [req.user.id]);
  res.json({ ok: true });
});

app.put('/api/me/device-token', auth, async (req, res) => {
  const token = String(req.body?.token || '').trim();
  const platform = String(req.body?.platform || 'android').slice(0, 20);
  const deviceInfo = String(req.body?.deviceInfo || req.headers['user-agent'] || '').slice(0, 240);
  if (!token || token.length < 20) return res.status(400).json({ error: 'رمز الجهاز غير صالح' });
  await query('DELETE FROM device_tokens WHERE token=$1 AND user_id <> $2', [token, req.user.id]);
  const existing = (await query('SELECT id FROM device_tokens WHERE token=$1', [token])).rows[0];
  if (existing) {
    await query(
      `UPDATE device_tokens SET user_id=$1, platform=$2, device_info=$3, updated_at=NOW() WHERE token=$4`,
      [req.user.id, platform, deviceInfo, token],
    );
  } else {
    await query(
      `INSERT INTO device_tokens (id, user_id, token, platform, device_info) VALUES ($1,$2,$3,$4,$5)`,
      [nid('dt'), req.user.id, token, platform, deviceInfo],
    );
  }
  res.json({ ok: true });
});

app.delete('/api/me/device-token', auth, async (req, res) => {
  const token = String(req.body?.token || req.query.token || '').trim();
  if (token) {
    await query('DELETE FROM device_tokens WHERE user_id=$1 AND token=$2', [req.user.id, token]);
  } else {
    await query('DELETE FROM device_tokens WHERE user_id=$1', [req.user.id]);
  }
  res.json({ ok: true });
});

app.post('/api/notifications/broadcast', auth, requireRole('admin', 'owner'), async (req, res) => {
  const b = req.body || {};
  const title = String(b.title || '').trim();
  const message = String(b.message || '').trim();
  if (!title || !message) return res.status(400).json({ error: 'العنوان والنص مطلوبان' });
  let userIds = Array.isArray(b.userIds) ? b.userIds.filter(Boolean) : [];
  if (!userIds.length) {
    const role = String(b.role || 'all');
    if (role === 'patient' || role === 'doctor') {
      userIds = (await query('SELECT id FROM users WHERE role=$1', [role])).rows.map((r) => r.id);
    } else {
      userIds = (await query(`SELECT id FROM users WHERE role IN ('patient', 'doctor')`)).rows.map((r) => r.id);
    }
  }
  await Promise.all(userIds.map((id) => notify(id, title, message, b.type || 'admin', b.link || '/notifications')));
  await audit(req.user, 'admin_action', `إرسال إشعار جماعي إلى ${userIds.length} مستخدماً`);
  res.json({ ok: true, sent: userIds.length });
});

function publicUser(u) {
  if (!u) return null;
  return {
    id: u.id,
    email: u.email,
    fullName: u.full_name,
    role: u.role,
    phone: u.phone || '',
    profilePhoto: u.profile_photo || '',
    languagePreference: u.language_preference || 'ar',
    notifyEmail: u.notify_email !== false,
    notifySms: u.notify_sms !== false,
    notifyPush: u.notify_push !== false,
  };
}

function iso(value) {
  return value ? new Date(value).toISOString() : null;
}

function mapDoctor(d) {
  return {
    id: d.id,
    userId: d.user_id,
    fullName: d.full_name,
    gender: d.gender,
    dateOfBirth: d.date_of_birth || '',
    specialty: d.specialty,
    clinicName: d.clinic_name,
    city: d.city,
    phone: d.phone,
    email: d.email,
    licenseNumber: d.license_number,
    status: d.status,
    subscriptionStatus: d.subscription_status,
    subscriptionStart: iso(d.subscription_start),
    subscriptionEnd: iso(d.subscription_end),
    subscriptionDuration: d.subscription_duration,
    paymentAmount: Number(d.payment_amount || 0),
    yearsOfExperience: d.years_of_experience || 0,
    qualifications: d.qualifications || '',
    biography: d.biography || '',
    workingHours: d.working_hours || '',
    profilePhoto: d.profile_photo || '',
    certificates: d.certificates || [],
    featured: !!d.featured,
    rating: Number(d.rating || 4.5),
    reviews: d.reviews || 0,
    regionId: d.region_id || null,
    latitude: d.latitude == null ? null : Number(d.latitude),
    longitude: d.longitude == null ? null : Number(d.longitude),
    lastModifiedBy: d.last_modified_by,
    lastModifiedAt: iso(d.last_modified_at),
    createdDate: iso(d.created_at),
  };
}

function mapPatient(p) {
  return {
    id: p.id,
    userId: p.user_id,
    fullName: p.full_name,
    patientId: p.patient_id,
    qrCodeData: p.qr_code_data,
    phone: p.phone,
    email: p.email,
    city: p.city,
    gender: p.gender,
    bloodType: p.blood_type,
    status: p.status,
    nationalId: p.national_id || '',
    dateOfBirth: p.date_of_birth || '',
    allergies: p.allergies || '',
    chronicDiseases: p.chronic_diseases || '',
    currentMedications: p.current_medications || '',
    emergencyContactName: p.emergency_contact_name || '',
    emergencyContactRelationship: p.emergency_contact_relationship || '',
    emergencyContactPhone: p.emergency_contact_phone || '',
    medicalHistory: p.medical_history || '',
    vaccinationRecords: p.vaccination_records || '',
    surgeryRecords: p.surgery_records || '',
    profilePhoto: p.profile_photo || '',
    lastModifiedBy: p.last_modified_by,
    lastModifiedAt: iso(p.last_modified_at),
    createdDate: iso(p.created_at),
  };
}

function mapPost(p) {
  return {
    id: p.id,
    doctorId: p.doctor_id,
    doctorName: p.doctor_name,
    doctorSpecialty: p.doctor_specialty || '',
    doctorPhoto: p.doctor_photo || '',
    content: p.content,
    category: p.category,
    status: p.status,
    images: p.images || [],
    likesCount: p.likes_count,
    commentsCount: p.comments_count,
    createdDate: iso(p.created_at),
  };
}

function mapComment(c) {
  return {
    id: c.id,
    postId: c.post_id,
    authorName: c.author_name,
    content: c.content,
    doctorId: c.doctor_id || '',
    doctorPhoto: c.doctor_photo || '',
    createdDate: iso(c.created_at),
  };
}

function mapVisit(v) {
  return {
    id: v.id,
    doctorId: v.doctor_id,
    doctorName: v.doctor_name,
    doctorSpecialty: v.doctor_specialty || '',
    patientId: v.patient_id,
    patientName: v.patient_name,
    visitDate: iso(v.visit_date),
    visitTime: v.visit_time || '',
    symptoms: v.symptoms || '',
    diagnosis: v.diagnosis || '',
    treatmentPlan: v.treatment_plan || '',
    prescribedMedications: v.prescribed_medications || '',
    followUpNotes: v.follow_up_notes || '',
    status: v.status || 'active',
    patientUserId: v.patient_user_id || '',
    createdDate: iso(v.created_at),
  };
}

function mapFile(f) {
  return {
    id: f.id,
    doctorId: f.doctor_id || '',
    doctorName: f.doctor_name || '',
    patientId: f.patient_id || '',
    fileType: f.file_type,
    fileName: f.file_name || '',
    description: f.description || '',
    fileUrl: f.file_url || '',
    status: f.status || 'active',
    visitId: f.visit_id || '',
    doctorSpecialty: f.doctor_specialty || '',
    createdDate: iso(f.created_at),
  };
}

function mapSession(s) {
  return {
    id: s.id,
    patientId: s.patient_id,
    patientUserId: s.patient_user_id,
    doctorId: s.doctor_id,
    patientName: s.patient_name,
    doctorName: s.doctor_name,
    status: s.status,
    grantedAt: iso(s.granted_at),
    expiresAt: iso(s.expires_at),
    durationHours: s.duration_hours,
    accessMethod: s.access_method,
  };
}

function mapAvailability(a) {
  return {
    id: a.id,
    doctorId: a.doctor_id,
    doctorName: a.doctor_name || '',
    dayOfWeek: a.day_of_week,
    startTime: a.start_time,
    endTime: a.end_time,
    isAvailable: a.is_available !== false,
  };
}

function mapAppointment(a) {
  return {
    id: a.id,
    doctorId: a.doctor_id,
    doctorUserId: a.doctor_user_id,
    doctorName: a.doctor_name,
    doctorSpecialty: a.doctor_specialty || '',
    patientId: a.patient_id,
    patientUserId: a.patient_user_id,
    patientName: a.patient_name,
    patientPhone: a.patient_phone || '',
    appointmentDate: a.appointment_date,
    appointmentTime: a.appointment_time,
    reason: a.reason || '',
    durationMinutes: a.duration_minutes || 30,
    notes: a.notes || '',
    status: a.status,
  };
}

function mapNotification(n) {
  return {
    id: n.id,
    userId: n.user_id,
    title: n.title,
    message: n.message,
    type: n.type,
    link: n.link || '',
    read: !!n.is_read,
    createdDate: iso(n.created_at),
  };
}

function mapAudit(a) {
  return {
    id: a.id,
    userId: a.user_id,
    userName: a.user_name,
    userRole: a.user_role,
    actionType: a.action_type,
    description: a.description,
    targetType: a.target_type,
    targetId: a.target_id,
    ipAddress: a.ip_address,
    deviceInfo: a.device_info,
    createdDate: iso(a.created_at),
  };
}

function mapActivation(a) {
  return {
    id: a.id,
    doctorId: a.doctor_id,
    doctorName: a.doctor_name,
    adminName: a.admin_name,
    paymentAmount: Number(a.payment_amount),
    duration: a.duration,
    startDate: iso(a.start_date),
    endDate: iso(a.end_date),
    action: a.action,
    createdDate: iso(a.created_at),
  };
}

function mapCard(c) {
  return {
    doctorId: c.doctor_id,
    bankName: c.bank_name,
    cardNumber: c.card_number,
    cardHolderName: c.card_holder_name,
    cardExpiry: c.card_expiry,
    cardCvv: c.card_cvv,
  };
}

function mapPlatformUser(u) {
  return { id: u.id, email: u.email, role: u.role, createdDate: iso(u.created_at) };
}

function mapRegion(r) {
  return {
    id: r.id,
    name: r.name,
    city: r.city || 'بغداد',
    centerLat: Number(r.center_lat),
    centerLng: Number(r.center_lng),
    zoom: Number(r.zoom || 13),
    sortOrder: Number(r.sort_order || 0),
    isActive: r.is_active !== false,
    createdDate: iso(r.created_at),
  };
}

registerLegal(app, { query, nid, notifyAdmins, audit, isIqMobile });

registerFeatures({
  app,
  query,
  auth,
  requireRole,
  audit,
  notify,
  nid,
  settingsMap,
  mapDoctor,
  mapPost,
  mapVisit,
  mapFile,
  mapAppointment,
  mapAudit,
  mapCard,
  mapRegion,
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: err.message || 'خطأ في الخادم' });
});

async function start() {
  await waitForDb();
  await migrate();
  await seedIfEmpty();
  await seedRegionsIfEmpty();
  const fcm = initFirebaseAdmin();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Medical QR API listening on ${PORT}${fcm ? ' · FCM جاهز' : ' · FCM غير مهيأ'}`);
  });
}

process.on('unhandledRejection', (err) => {
  console.error(err);
});

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
