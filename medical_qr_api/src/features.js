const fs = require('fs');
const path = require('path');
const multer = require('multer');

const { pool } = require('./db');

const uploadsDir = process.env.UPLOADS_DIR || path.join(__dirname, '..', 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').slice(0, 12);
    cb(null, `${Date.now()}-${Math.random().toString(16).slice(2)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 },
});

function fileUrl(req, filename) {
  return `/uploads/${filename}`;
}

/// يحوّل رابط ملف مرفوع إلى مسار فعلي داخل مجلد الرفع.
/// يعيد null لأي رابط خارجي أو يحاول الخروج من المجلد.
function uploadFilePath(url) {
  const raw = String(url || '').trim();
  if (!raw || !raw.includes('/uploads/')) return null;
  const name = path.basename(raw.split('?')[0]);
  if (!name || name === '.' || name === '..') return null;
  const root = path.resolve(uploadsDir);
  const target = path.resolve(root, name);
  return target.startsWith(root + path.sep) ? target : null;
}

function removeUploadedFiles(urls) {
  let removed = 0;
  for (const url of new Set(urls)) {
    const target = uploadFilePath(url);
    if (!target) continue;
    try {
      fs.unlinkSync(target);
      removed += 1;
    } catch {
      // الملف محذوف مسبقاً أو غير موجود على القرص.
    }
  }
  return removed;
}

function mapMessage(m) {
  return {
    id: m.id,
    conversationId: m.conversation_id,
    patientId: m.patient_id,
    doctorId: m.doctor_id,
    senderUserId: m.sender_user_id,
    senderName: m.sender_name,
    senderRole: m.sender_role,
    content: m.content,
    messageType: m.message_type || 'text',
    questionnaire: m.questionnaire || null,
    read: !!m.is_read,
    createdDate: m.created_at ? new Date(m.created_at).toISOString() : null,
  };
}

function mapReview(r) {
  return {
    id: r.id,
    doctorId: r.doctor_id,
    doctorName: r.doctor_name || '',
    patientId: r.patient_id,
    patientName: r.patient_name || '',
    visitId: r.visit_id || '',
    rating: Number(r.rating || 0),
    comment: r.comment || '',
    createdDate: r.created_at ? new Date(r.created_at).toISOString() : null,
  };
}

function mapAchievement(a) {
  return {
    id: a.id,
    doctorId: a.doctor_id,
    title: a.title,
    description: a.description || '',
    achievedAt: a.achieved_at || '',
    imageUrl: a.image_url || '',
    createdDate: a.created_at ? new Date(a.created_at).toISOString() : null,
  };
}

function mapFollow(f) {
  return {
    patientId: f.patient_id,
    doctorId: f.doctor_id,
    createdDate: f.created_at ? new Date(f.created_at).toISOString() : null,
  };
}

async function extraBootstrap(query, user) {
  let messageRows = [];
  if (user.role === 'admin' || user.role === 'owner') {
    messageRows = (await query('SELECT * FROM messages ORDER BY created_at DESC LIMIT 500')).rows;
  } else if (user.role === 'doctor') {
    const doctor = (await query('SELECT id FROM doctors WHERE user_id=$1', [user.id])).rows[0];
    messageRows = (await query('SELECT * FROM messages WHERE doctor_id=$1 ORDER BY created_at DESC LIMIT 400', [doctor?.id || ''])).rows;
  } else {
    const patient = (await query('SELECT id FROM patients WHERE user_id=$1', [user.id])).rows[0];
    messageRows = (await query('SELECT * FROM messages WHERE patient_id=$1 ORDER BY created_at DESC LIMIT 400', [patient?.id || ''])).rows;
  }
  const messages = messageRows.map(mapMessage);

  const reviews = (await query('SELECT * FROM doctor_reviews ORDER BY created_at DESC')).rows.map(mapReview);
  const achievements = (await query('SELECT * FROM achievements ORDER BY created_at DESC')).rows.map(mapAchievement);
  const follows = (await query('SELECT * FROM follows')).rows.map(mapFollow);
  const liked = (await query('SELECT post_id FROM post_likes WHERE user_id=$1', [user.id])).rows.map((r) => r.post_id);
  const cards = (await query(
    user.role === 'admin' || user.role === 'owner'
      ? 'SELECT * FROM payment_cards'
      : `SELECT pc.* FROM payment_cards pc
         JOIN doctors d ON d.id = pc.doctor_id
         WHERE d.user_id=$1`,
    user.role === 'admin' || user.role === 'owner' ? [] : [user.id],
  )).rows;

  return {
    messages,
    reviews,
    achievements,
    follows,
    likedPostIds: liked,
    cards: cards.map((c) => ({
      doctorId: c.doctor_id,
      bankName: c.bank_name,
      cardNumber: c.card_number,
      cardHolderName: c.card_holder_name,
      cardExpiry: c.card_expiry,
      cardCvv: c.card_cvv,
    })),
  };
}

function registerFeatures(ctx) {
  const {
    app, query, auth, requireRole, audit, notify, nid, settingsMap,
    mapDoctor, mapPost, mapVisit, mapFile, mapAppointment, mapAudit, mapCard, mapRegion,
  } = ctx;

  app.use('/uploads', require('express').static(uploadsDir));

  app.get('/api/regions', auth, async (_req, res) => {
    const rows = (await query('SELECT * FROM map_regions WHERE is_active=TRUE ORDER BY sort_order, name')).rows;
    res.json({ regions: rows.map(mapRegion) });
  });

  app.post('/api/regions', auth, requireRole('admin', 'owner', 'doctor'), async (req, res) => {
    const b = req.body || {};
    const name = String(b.name || '').trim();
    const centerLat = Number(b.centerLat);
    const centerLng = Number(b.centerLng);
    if (!name) return res.status(400).json({ error: 'اسم المنطقة مطلوب' });
    if (!Number.isFinite(centerLat) || !Number.isFinite(centerLng)) {
      return res.status(400).json({ error: 'حدد موقع المنطقة على الخريطة' });
    }
    const id = nid('reg');
    await query(
      `INSERT INTO map_regions (id, name, city, center_lat, center_lng, zoom, sort_order)
       VALUES ($1,$2,$3,$4,$5,$6,$7)`,
      [id, name, b.city || 'بغداد', centerLat, centerLng, Number(b.zoom || 13.5), Number(b.sortOrder || 100)],
    );
    await audit(req.user, 'admin_action', `إنشاء منطقة خريطة: ${name}`, { targetType: 'MapRegion', targetId: id });
    const region = (await query('SELECT * FROM map_regions WHERE id=$1', [id])).rows[0];
    res.json({ region: mapRegion(region) });
  });

  app.patch('/api/regions/:id', auth, requireRole('admin', 'owner', 'doctor'), async (req, res) => {
    const current = (await query('SELECT * FROM map_regions WHERE id=$1', [req.params.id])).rows[0];
    if (!current) return res.status(404).json({ error: 'المنطقة غير موجودة' });
    const b = req.body || {};
    await query(
      `UPDATE map_regions SET
        name=COALESCE($1,name),
        city=COALESCE($2,city),
        center_lat=COALESCE($3,center_lat),
        center_lng=COALESCE($4,center_lng),
        zoom=COALESCE($5,zoom),
        sort_order=COALESCE($6,sort_order),
        is_active=COALESCE($7,is_active)
       WHERE id=$8`,
      [
        b.name || null,
        b.city || null,
        b.centerLat == null ? null : Number(b.centerLat),
        b.centerLng == null ? null : Number(b.centerLng),
        b.zoom == null ? null : Number(b.zoom),
        b.sortOrder == null ? null : Number(b.sortOrder),
        b.isActive == null ? null : !!b.isActive,
        req.params.id,
      ],
    );
    const region = (await query('SELECT * FROM map_regions WHERE id=$1', [req.params.id])).rows[0];
    res.json({ region: mapRegion(region) });
  });

  app.delete('/api/regions/:id', auth, requireRole('admin', 'owner', 'doctor'), async (req, res) => {
    await query(`UPDATE doctors SET region_id=NULL WHERE region_id=$1`, [req.params.id]);
    await query(`UPDATE map_regions SET is_active=FALSE WHERE id=$1`, [req.params.id]);
    await audit(req.user, 'admin_action', 'تعطيل منطقة خريطة', { targetType: 'MapRegion', targetId: req.params.id });
    res.json({ ok: true });
  });

  app.post('/api/regions/:id/doctors', auth, requireRole('admin', 'owner', 'doctor'), async (req, res) => {
    const region = (await query('SELECT * FROM map_regions WHERE id=$1 AND is_active=TRUE', [req.params.id])).rows[0];
    if (!region) return res.status(404).json({ error: 'المنطقة غير موجودة' });
    const doctorIds = Array.isArray(req.body?.doctorIds) ? req.body.doctorIds.map(String) : [];
    const replace = req.body?.replace !== false;
    if (replace) {
      await query(`UPDATE doctors SET region_id=NULL WHERE region_id=$1`, [region.id]);
    }
    for (const doctorId of doctorIds) {
      await query(
        `UPDATE doctors SET region_id=$1, latitude=COALESCE(latitude,$2), longitude=COALESCE(longitude,$3),
         last_modified_by=$4, last_modified_at=NOW()
         WHERE id=$5`,
        [region.id, region.center_lat, region.center_lng, req.user.fullName, doctorId],
      );
    }
    await audit(req.user, 'admin_action', `تحديث أطباء منطقة ${region.name}`, { targetType: 'MapRegion', targetId: region.id });
    const doctors = (await query('SELECT * FROM doctors WHERE region_id=$1 ORDER BY full_name', [region.id])).rows.map(mapDoctor);
    res.json({ region: mapRegion(region), doctors });
  });

  app.post('/api/me/deactivate', auth, requireRole('patient'), async (req, res) => {
    await query(`UPDATE patients SET status='suspended', last_modified_by=$1, last_modified_at=NOW() WHERE user_id=$2`, [req.user.fullName, req.user.id]);
    await audit(req.user, 'profile_update', 'تم إيقاف الحساب من الملف الشخصي');
    res.json({ ok: true });
  });

  // حذف نهائي للحساب مع كل سجلاته ومستنداته. لا يمكن التراجع عنه.
  app.delete('/api/me', auth, async (req, res) => {
    if (req.user.role === 'admin' || req.user.role === 'owner') {
      return res.status(403).json({ error: 'حسابات الإدارة تُحذف من لوحة التحكم فقط' });
    }

    const userId = req.user.id;
    const client = await pool.connect();
    const uploads = [];
    let deleted = 0;

    try {
      await client.query('BEGIN');

      const user = (await client.query('SELECT * FROM users WHERE id=$1 FOR UPDATE', [userId])).rows[0];
      if (!user) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'الحساب غير موجود' });
      }

      const patientIds = (await client.query('SELECT id FROM patients WHERE user_id=$1', [userId])).rows.map((r) => r.id);
      const doctorIds = (await client.query('SELECT id FROM doctors WHERE user_id=$1', [userId])).rows.map((r) => r.id);

      const drop = async (sql, params) => {
        const { rowCount } = await client.query(sql, params);
        deleted += rowCount;
        return rowCount;
      };

      uploads.push(user.profile_photo);

      if (patientIds.length) {
        const own = (await client.query('SELECT profile_photo FROM patients WHERE id = ANY($1)', [patientIds])).rows;
        own.forEach((r) => uploads.push(r.profile_photo));
        const files = (await client.query('SELECT file_url FROM medical_files WHERE patient_id = ANY($1)', [patientIds])).rows;
        files.forEach((r) => uploads.push(r.file_url));
      }

      if (doctorIds.length) {
        const own = (await client.query('SELECT profile_photo, certificates FROM doctors WHERE id = ANY($1)', [doctorIds])).rows;
        own.forEach((r) => {
          uploads.push(r.profile_photo);
          (r.certificates || []).forEach((c) => uploads.push(c));
        });
        const files = (await client.query('SELECT file_url FROM medical_files WHERE doctor_id = ANY($1)', [doctorIds])).rows;
        files.forEach((r) => uploads.push(r.file_url));
        const posts = (await client.query('SELECT images FROM posts WHERE doctor_id = ANY($1)', [doctorIds])).rows;
        posts.forEach((r) => (r.images || []).forEach((image) => uploads.push(image)));
        const badges = (await client.query('SELECT image_url FROM achievements WHERE doctor_id = ANY($1)', [doctorIds])).rows;
        badges.forEach((r) => uploads.push(r.image_url));
      }

      // تُلتقط قبل الحذف لإعادة حساب المتوسطات والعدادات بعده.
      const ratedDoctorIds = patientIds.length
        ? (await client.query('SELECT DISTINCT doctor_id FROM doctor_reviews WHERE patient_id = ANY($1)', [patientIds])).rows.map((r) => r.doctor_id)
        : [];
      const commentedPostIds = doctorIds.length
        ? (await client.query('SELECT DISTINCT post_id FROM post_comments WHERE doctor_id = ANY($1) AND post_id IS NOT NULL', [doctorIds])).rows.map((r) => r.post_id)
        : [];

      if (patientIds.length) {
        await drop('DELETE FROM messages WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM doctor_reviews WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM follows WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM access_sessions WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM medical_files WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM visits WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM appointments WHERE patient_id = ANY($1)', [patientIds]);
        await drop('DELETE FROM patients WHERE id = ANY($1)', [patientIds]);
      }

      if (doctorIds.length) {
        await drop('DELETE FROM post_comments WHERE post_id IN (SELECT id FROM posts WHERE doctor_id = ANY($1))', [doctorIds]);
        await drop('DELETE FROM post_likes WHERE post_id IN (SELECT id FROM posts WHERE doctor_id = ANY($1))', [doctorIds]);
        await drop('DELETE FROM posts WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM post_comments WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM messages WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM doctor_reviews WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM achievements WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM follows WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM availability WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM access_sessions WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM medical_files WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM visits WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM appointments WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM activations WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM payment_cards WHERE doctor_id = ANY($1)', [doctorIds]);
        await drop('DELETE FROM doctors WHERE id = ANY($1)', [doctorIds]);
      }

      await drop('DELETE FROM messages WHERE sender_user_id=$1', [userId]);
      await drop('DELETE FROM appointments WHERE doctor_user_id=$1 OR patient_user_id=$1', [userId]);
      await drop('DELETE FROM notifications WHERE user_id=$1', [userId]);
      await drop('DELETE FROM device_tokens WHERE user_id=$1', [userId]);
      await drop('DELETE FROM post_likes WHERE user_id=$1', [userId]);
      await drop('DELETE FROM otp_codes WHERE user_id=$1 OR LOWER(email)=LOWER($2)', [userId, user.email]);
      await drop('DELETE FROM audit_logs WHERE user_id=$1', [userId]);
      await drop('DELETE FROM users WHERE id=$1', [userId]);

      for (const doctorId of ratedDoctorIds) {
        const agg = (await client.query(
          'SELECT AVG(rating)::float AS avg, COUNT(*)::int AS count FROM doctor_reviews WHERE doctor_id=$1',
          [doctorId],
        )).rows[0];
        await client.query('UPDATE doctors SET rating=$1, reviews=$2 WHERE id=$3', [agg.count ? agg.avg : 4.5, agg.count, doctorId]);
      }
      for (const postId of commentedPostIds) {
        await client.query('UPDATE posts SET comments_count=(SELECT COUNT(*) FROM post_comments WHERE post_id=$1) WHERE id=$1', [postId]);
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK').catch(() => {});
      return res.status(500).json({ error: 'تعذر حذف الحساب، حاول مرة أخرى' });
    } finally {
      client.release();
    }

    // بعد نجاح المعاملة فقط، حتى لا تُفقد ملفات إن فشل الحذف من القاعدة.
    const removedFiles = removeUploadedFiles(uploads);

    // أثر مجهّل بلا بيانات شخصية، لأن سجلات المستخدم نفسه حُذفت.
    await query(
      `INSERT INTO audit_logs (id, user_id, user_name, user_role, action_type, description, device_info)
       VALUES ($1,'deleted-account','حساب محذوف',$2,'account_delete',$3,'API')`,
      [nid('a'), req.user.role, `حذف نهائي لحساب مع ${deleted} سجلاً و${removedFiles} ملفاً`],
    );

    res.json({ ok: true, deletedRecords: deleted, deletedFiles: removedFiles });
  });

  app.post('/api/upload', auth, upload.single('file'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'لم يتم اختيار ملف' });
    const url = fileUrl(req, req.file.filename);
    res.json({
      url,
      fileUrl: url,
      fileName: req.file.originalname || req.file.filename,
      mimeType: req.file.mimetype,
      size: req.file.size,
    });
  });

  app.post('/api/auth/password/reset-request', async (req, res) => {
    const email = String(req.body.email || '').trim().toLowerCase();
    const { rows } = await query('SELECT * FROM users WHERE LOWER(email)=$1', [email]);
    const user = rows[0];
    if (!user) return res.status(400).json({ error: 'الحساب غير موجود' });
    if (user.role !== 'admin' && user.role !== 'owner') {
      return res.status(400).json({ error: 'الأطباء والمرضى يدخلون برقم الهاتف ورمز واتساب فقط' });
    }
    return res.json({
      ok: true,
      email: user.email,
      message: 'إن كانت بيانات الحساب صحيحة يمكن تعيين كلمة مرور جديدة من شاشة الاستعادة',
    });
  });

  app.get('/api/audit', auth, requireRole('admin', 'owner'), async (req, res) => {
    const limit = Math.min(Number(req.query.limit || 200), 500);
    const actionType = String(req.query.actionType || '').trim();
    const rows = actionType
      ? (await query('SELECT * FROM audit_logs WHERE action_type=$1 ORDER BY created_at DESC LIMIT $2', [actionType, limit])).rows
      : (await query('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT $1', [limit])).rows;
    res.json({ audit: rows.map(mapAudit) });
  });

  app.get('/api/analytics/daily-logins', auth, requireRole('admin', 'owner'), async (req, res) => {
    const days = Math.min(Math.max(Number(req.query.days || 7), 1), 90);
    const { rows } = await query(
      `SELECT date_trunc('day', created_at) AS day, user_role, COUNT(*)::int AS count
       FROM audit_logs
       WHERE action_type='login' AND created_at >= NOW() - ($1 || ' days')::interval
       GROUP BY 1, 2
       ORDER BY 1`,
      [String(days)],
    );
    res.json({ days, rows });
  });

  app.post('/api/messages', auth, async (req, res) => {
    const b = req.body || {};
    const patientId = b.patientId;
    const doctorId = b.doctorId;
    if (!patientId || !doctorId) return res.status(400).json({ error: 'المحادثة غير مكتملة' });
    const conversationId = b.conversationId || `${patientId}__${doctorId}`;
    const mid = nid('m');
    await query(
      `INSERT INTO messages (id, conversation_id, patient_id, doctor_id, sender_user_id, sender_name, sender_role, content, message_type, questionnaire)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [
        mid, conversationId, patientId, doctorId, req.user.id, req.user.fullName, req.user.role,
        b.content || '', b.messageType || 'text', b.questionnaire ? JSON.stringify(b.questionnaire) : null,
      ],
    );
    const other = req.user.role === 'doctor'
      ? (await query('SELECT user_id FROM patients WHERE id=$1', [patientId])).rows[0]
      : (await query('SELECT user_id FROM doctors WHERE id=$1', [doctorId])).rows[0];
    await notify(other?.user_id, req.user.role === 'doctor' ? 'رسالة من الطبيب' : 'رسالة من المريض', String(b.content || 'رسالة جديدة').slice(0, 80), 'message', '/messages');
    const row = (await query('SELECT * FROM messages WHERE id=$1', [mid])).rows[0];
    res.json({ message: mapMessage(row) });
  });

  app.post('/api/messages/read', auth, async (req, res) => {
    const conversationId = String(req.body.conversationId || '');
    await query(
      `UPDATE messages SET is_read=TRUE WHERE conversation_id=$1 AND sender_user_id <> $2`,
      [conversationId, req.user.id],
    );
    res.json({ ok: true });
  });

  app.post('/api/reviews', auth, async (req, res) => {
    if (req.user.role !== 'patient') return res.status(403).json({ error: 'التقييم متاح للمرضى فقط' });
    const b = req.body || {};
    const rating = Number(b.rating || 0);
    if (rating < 1 || rating > 5) return res.status(400).json({ error: 'يرجى تحديد التقييم' });
    const existing = b.visitId
      ? (await query('SELECT * FROM doctor_reviews WHERE visit_id=$1 AND patient_id=$2', [b.visitId, b.patientId])).rows[0]
      : (await query('SELECT * FROM doctor_reviews WHERE doctor_id=$1 AND patient_id=$2 AND visit_id IS NULL', [b.doctorId, b.patientId])).rows[0];
    if (existing) {
      await query('UPDATE doctor_reviews SET rating=$1, comment=$2 WHERE id=$3', [rating, b.comment || '', existing.id]);
    } else {
      await query(
        `INSERT INTO doctor_reviews (id, doctor_id, doctor_name, patient_id, patient_name, visit_id, rating, comment)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
        [nid('rv'), b.doctorId, b.doctorName || '', b.patientId, b.patientName || '', b.visitId || null, rating, b.comment || ''],
      );
    }
    const agg = (await query('SELECT AVG(rating)::float AS avg, COUNT(*)::int AS count FROM doctor_reviews WHERE doctor_id=$1', [b.doctorId])).rows[0];
    await query('UPDATE doctors SET rating=$1, reviews=$2 WHERE id=$3', [agg.avg || rating, agg.count || 1, b.doctorId]);
    const review = (await query(
      existing
        ? 'SELECT * FROM doctor_reviews WHERE id=$1'
        : 'SELECT * FROM doctor_reviews WHERE doctor_id=$1 AND patient_id=$2 ORDER BY created_at DESC LIMIT 1',
      existing ? [existing.id] : [b.doctorId, b.patientId],
    )).rows[0];
    if (!existing) {
      const doctor = (await query('SELECT user_id FROM doctors WHERE id=$1', [b.doctorId])).rows[0];
      await notify(doctor?.user_id, 'تقييم جديد', `${b.patientName || 'مريض'} قيّمك بـ ${rating} من 5`, 'review', '/notifications');
    }
    res.json({ review: mapReview(review), doctor: mapDoctor((await query('SELECT * FROM doctors WHERE id=$1', [b.doctorId])).rows[0]) });
  });

  app.post('/api/achievements', auth, requireRole('doctor'), async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
    const b = req.body || {};
    if (!b.title) return res.status(400).json({ error: 'عنوان الإنجاز مطلوب' });
    const id = nid('ac');
    await query(
      `INSERT INTO achievements (id, doctor_id, title, description, achieved_at, image_url) VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, doctor.id, b.title, b.description || '', b.achievedAt || '', b.imageUrl || ''],
    );
    const row = (await query('SELECT * FROM achievements WHERE id=$1', [id])).rows[0];
    res.json({ achievement: mapAchievement(row) });
  });

  app.patch('/api/achievements/:id', auth, requireRole('doctor'), async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
    const current = (await query('SELECT * FROM achievements WHERE id=$1 AND doctor_id=$2', [req.params.id, doctor.id])).rows[0];
    if (!current) return res.status(404).json({ error: 'الإنجاز غير موجود' });
    const b = req.body || {};
    await query(
      `UPDATE achievements SET title=COALESCE($1,title), description=COALESCE($2,description), achieved_at=COALESCE($3,achieved_at), image_url=COALESCE($4,image_url) WHERE id=$5`,
      [b.title, b.description, b.achievedAt, b.imageUrl, current.id],
    );
    const row = (await query('SELECT * FROM achievements WHERE id=$1', [current.id])).rows[0];
    res.json({ achievement: mapAchievement(row) });
  });

  app.delete('/api/achievements/:id', auth, requireRole('doctor'), async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
    await query('DELETE FROM achievements WHERE id=$1 AND doctor_id=$2', [req.params.id, doctor.id]);
    res.json({ ok: true });
  });

  app.post('/api/doctors/:id/follow', auth, requireRole('patient'), async (req, res) => {
    const patient = (await query('SELECT * FROM patients WHERE user_id=$1', [req.user.id])).rows[0];
    if (!patient) return res.status(400).json({ error: 'ملف المريض غير موجود' });
    await query(
      `INSERT INTO follows (patient_id, doctor_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`,
      [patient.id, req.params.id],
    );
    const doctor = (await query('SELECT user_id, full_name FROM doctors WHERE id=$1', [req.params.id])).rows[0];
    await notify(doctor?.user_id, 'متابع جديد', `${patient.full_name} بدأ بمتابعتك`, 'follow', '/notifications');
    res.json({ ok: true, following: true });
  });

  app.delete('/api/doctors/:id/follow', auth, requireRole('patient'), async (req, res) => {
    const patient = (await query('SELECT * FROM patients WHERE user_id=$1', [req.user.id])).rows[0];
    await query('DELETE FROM follows WHERE patient_id=$1 AND doctor_id=$2', [patient.id, req.params.id]);
    res.json({ ok: true, following: false });
  });

  app.put('/api/doctors/:id/payment-card', auth, async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE id=$1', [req.params.id])).rows[0];
    if (!doctor) return res.status(404).json({ error: 'الطبيب غير موجود' });
    if (req.user.role === 'doctor' && doctor.user_id !== req.user.id) return res.status(403).json({ error: 'غير مصرح' });
    const b = req.body || {};
    await query(
      `INSERT INTO payment_cards (doctor_id, bank_name, card_number, card_holder_name, card_expiry, card_cvv)
       VALUES ($1,$2,$3,$4,$5,$6)
       ON CONFLICT (doctor_id) DO UPDATE SET
         bank_name=EXCLUDED.bank_name, card_number=EXCLUDED.card_number,
         card_holder_name=EXCLUDED.card_holder_name, card_expiry=EXCLUDED.card_expiry, card_cvv=EXCLUDED.card_cvv`,
      [doctor.id, b.bankName || '', b.cardNumber || '', b.cardHolderName || '', b.cardExpiry || '', b.cardCvv || ''],
    );
    const card = (await query('SELECT * FROM payment_cards WHERE doctor_id=$1', [doctor.id])).rows[0];
    res.json({ card: mapCard(card) });
  });

  app.post('/api/access/:id/revoke', auth, requireRole('doctor'), async (req, res) => {
    const session = (await query('SELECT * FROM access_sessions WHERE id=$1', [req.params.id])).rows[0];
    await query(`UPDATE access_sessions SET status='revoked' WHERE id=$1`, [req.params.id]);
    if (session?.patient_user_id) {
      await notify(session.patient_user_id, 'انتهى الوصول', `أُغلقت صلاحية اطلاع د. ${session.doctor_name} على سجلك`, 'access_expired', '/notifications');
    }
    res.json({ ok: true });
  });

  app.patch('/api/posts/:id', auth, requireRole('doctor'), async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
    const post = (await query('SELECT * FROM posts WHERE id=$1 AND doctor_id=$2', [req.params.id, doctor.id])).rows[0];
    if (!post) return res.status(404).json({ error: 'المنشور غير موجود' });
    const b = req.body || {};
    await query(
      `UPDATE posts SET content=COALESCE($1,content), category=COALESCE($2,category), images=COALESCE($3,images), status=COALESCE($4,status) WHERE id=$5`,
      [b.content, b.category, b.images || null, b.status, post.id],
    );
    const updated = (await query('SELECT * FROM posts WHERE id=$1', [post.id])).rows[0];
    res.json({ post: mapPost(updated) });
  });

  app.post('/api/posts/:id/delete-own', auth, requireRole('doctor'), async (req, res) => {
    const doctor = (await query('SELECT * FROM doctors WHERE user_id=$1', [req.user.id])).rows[0];
    await query(`UPDATE posts SET status='archived' WHERE id=$1 AND doctor_id=$2`, [req.params.id, doctor.id]);
    res.json({ ok: true });
  });
}

module.exports = { registerFeatures, extraBootstrap, uploadsDir, mapMessage, mapReview, mapAchievement, mapFollow };
