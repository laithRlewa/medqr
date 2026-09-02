const fs = require('fs');
const path = require('path');

let admin = null;
let ready = false;

function loadServiceAccount() {
  const raw = String(process.env.FIREBASE_SERVICE_ACCOUNT || '').trim();
  if (raw) {
    try {
      return JSON.parse(raw);
    } catch (error) {
      console.error('FIREBASE_SERVICE_ACCOUNT ليس JSON صالحاً');
    }
  }

  const envPath = String(process.env.FIREBASE_SERVICE_ACCOUNT_PATH || '').trim();
  const candidates = [
    envPath,
    path.join(__dirname, '..', 'secrets', 'firebase-adminsdk.json'),
    '/opt/medical-qr-api/secrets/firebase-adminsdk.json',
  ].filter(Boolean);

  for (const file of candidates) {
    try {
      if (fs.existsSync(file)) {
        return JSON.parse(fs.readFileSync(file, 'utf8'));
      }
    } catch (error) {
      console.error('تعذر قراءة حساب خدمة Firebase:', file, error.message);
    }
  }
  return null;
}

function initFirebaseAdmin() {
  if (ready) return true;
  try {
    admin = require('firebase-admin');
  } catch {
    console.warn('حزمة firebase-admin غير مثبتة — لن تُرسل إشعارات الدفع');
    return false;
  }
  if (admin.apps.length) {
    ready = true;
    return true;
  }
  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    console.warn('لا يوجد حساب خدمة Firebase — إشعارات الدفع معطّلة إلى أن يُضبط FIREBASE_SERVICE_ACCOUNT');
    return false;
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id || process.env.FIREBASE_PROJECT_ID || 'medqr-990bc',
  });
  ready = true;
  return true;
}

function asData(payload) {
  const data = {};
  for (const [key, value] of Object.entries(payload || {})) {
    if (value == null) continue;
    data[String(key)] = String(value);
  }
  return data;
}

async function dropInvalidTokens(query, tokens, responses) {
  const stale = [];
  responses.forEach((item, index) => {
    if (item.success) return;
    const code = item.error?.code || '';
    if (
      code.includes('registration-token-not-registered') ||
      code.includes('invalid-registration-token') ||
      code.includes('messaging/registration-token-not-registered') ||
      code.includes('messaging/invalid-registration-token')
    ) {
      stale.push(tokens[index]);
    }
  });
  if (!stale.length) return;
  await query('DELETE FROM device_tokens WHERE token = ANY($1::text[])', [stale]);
}

async function sendPushToUser(query, userId, notification) {
  if (!userId || !initFirebaseAdmin()) return { sent: 0 };
  const prefs = (await query('SELECT notify_push FROM users WHERE id=$1', [userId])).rows[0];
  if (prefs && prefs.notify_push === false) return { sent: 0, skipped: 'prefs' };

  const devices = (await query(
    'SELECT token, platform FROM device_tokens WHERE user_id=$1',
    [userId],
  )).rows;
  if (!devices.length) return { sent: 0 };

  const title = String(notification.title || 'MED QR');
  const body = String(notification.message || '');
  const data = asData({
    notificationId: notification.id || '',
    type: notification.type || 'system',
    link: notification.link || '/notifications',
    title,
    body,
  });

  const tokens = devices.map((d) => d.token);
  try {
    const result = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'medqr_alerts',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          icon: 'ic_launcher',
          color: '#14738F',
        },
      },
      webpush: {
        notification: { title, body, icon: '/icons/Icon-192.png' },
        fcmOptions: { link: '/' },
      },
    });
    await dropInvalidTokens(query, tokens, result.responses);
    return { sent: result.successCount, failed: result.failureCount };
  } catch (error) {
    console.error('فشل إرسال FCM:', error.message);
    return { sent: 0, error: error.message };
  }
}

module.exports = { initFirebaseAdmin, sendPushToUser };
