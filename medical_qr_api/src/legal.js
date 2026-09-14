const path = require('path');

const publicDir = path.join(__dirname, '..', 'public');
const recentRequests = new Map();
const WINDOW_MS = 15 * 60 * 1000;

function clientIp(req) {
  const forwarded = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
  return forwarded || req.ip || req.socket?.remoteAddress || 'unknown';
}

function tooMany(ip) {
  const now = Date.now();
  const stamps = (recentRequests.get(ip) || []).filter((time) => now - time < WINDOW_MS);
  if (stamps.length >= 3) {
    recentRequests.set(ip, stamps);
    return true;
  }
  stamps.push(now);
  recentRequests.set(ip, stamps);
  return false;
}

function registerLegal(app, { query, nid, notifyAdmins, audit, isIqMobile }) {
  app.get(['/privacy', '/privacy.html'], (_req, res) => {
    res.sendFile(path.join(publicDir, 'privacy.html'));
  });

  app.get(['/account-deletion', '/account-deletion.html', '/delete-account'], (_req, res) => {
    res.sendFile(path.join(publicDir, 'account-deletion.html'));
  });

  app.post('/api/account-deletion-requests', async (req, res) => {
    if (String(req.body?.website || '').trim()) {
      return res.json({ ok: true });
    }
    const ip = clientIp(req);
    if (tooMany(ip)) {
      return res.status(429).json({ error: 'محاولات كثيرة، حاول بعد ربع ساعة' });
    }

    const fullName = String(req.body?.fullName || '').trim().slice(0, 80);
    const phone = String(req.body?.phone || '').trim().slice(0, 20);
    const email = String(req.body?.email || '').trim().slice(0, 120);
    const role = req.body?.role === 'doctor' ? 'doctor' : 'patient';
    const note = String(req.body?.note || '').trim().slice(0, 500);

    if (fullName.length < 3) {
      return res.status(400).json({ error: 'الاسم مطلوب' });
    }
    if (!isIqMobile(phone)) {
      return res.status(400).json({ error: 'أدخل رقم الهاتف العراقي المسجّل' });
    }

    await audit(
      { id: 'public', fullName, role: 'guest' },
      'account_delete_request',
      `طلب حذف حساب (${role}) — ${fullName} — ${phone}${email ? ` — ${email}` : ''}${note ? ` — ${note}` : ''}`,
      { ip, device: 'privacy-web' },
    );
    await notifyAdmins(
      'طلب حذف حساب',
      `${fullName} يطلب حذف حساب ${role === 'doctor' ? 'طبيب' : 'مريض'} برقم ${phone}`,
      'admin',
      '/users',
    );
    res.json({ ok: true, message: 'تم استلام الطلب. سنتحقق من رقم الهاتف ثم نحذف الحساب.' });
  });
}

module.exports = { registerLegal };
