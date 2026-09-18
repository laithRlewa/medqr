const OTPIQ_URL = process.env.OTPIQ_URL || 'https://api.otpiq.com/api/sms';
const DEFAULT_TEMPLATE = 'alnomoor';
const DEFAULT_ACCOUNT_ID = '68d93e92528ac3db3eac6deb';
const DEFAULT_PHONE_ID = '68d93e9d528ac3db3eac6e1d';

function digits(phone) {
  return String(phone || '').replace(/\D/g, '');
}

function toIqIntl(phone) {
  let value = digits(phone);
  if (value.startsWith('00964')) value = value.slice(2);
  if (value.startsWith('9640')) value = `964${value.slice(4)}`;
  if (value.startsWith('964')) return value;
  if (value.startsWith('0')) value = value.slice(1);
  if (value.startsWith('7') && value.length === 10) return `964${value}`;
  return value;
}

function toIqLocal(phone) {
  const intl = toIqIntl(phone);
  if (intl.startsWith('964') && intl.length === 13) return `0${intl.slice(3)}`;
  return String(phone || '').trim();
}

function isIqMobile(phone) {
  return /^9647\d{9}$/.test(toIqIntl(phone));
}

function phoneLookupValues(phone) {
  const intl = toIqIntl(phone);
  const national = intl.startsWith('964') ? intl.slice(3) : digits(phone);
  const local = national.startsWith('0') ? national : `0${national}`;
  return [...new Set([digits(phone), intl, national, local].filter(Boolean))];
}

function otpiqConfig() {
  const apiKey = process.env.OTPIQ_API_KEY;
  if (!apiKey) {
    const error = new Error('خدمة واتساب غير مهيأة على الخادم');
    error.status = 503;
    throw error;
  }
  return {
    apiKey,
    templateName: process.env.OTPIQ_TEMPLATE_NAME || DEFAULT_TEMPLATE,
    whatsappAccountId: process.env.OTPIQ_WHATSAPP_ACCOUNT_ID || DEFAULT_ACCOUNT_ID,
    whatsappPhoneId: process.env.OTPIQ_WHATSAPP_PHONE_ID || DEFAULT_PHONE_ID,
  };
}

function errorText(data, fallback) {
  if (!data || typeof data !== 'object') return fallback;
  const value = data.message || data.error || data.msg || data.detail;
  if (typeof value === 'string' && value.trim()) return value;
  if (value && typeof value === 'object') return JSON.stringify(value);
  return fallback;
}

async function postOtpiq(apiKey, body) {
  const response = await fetch(OTPIQ_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  return { ok: response.ok, status: response.status, data };
}

/// يرسل رمز التحقق عبر واتساب بنفس حساب OTPIQ وقالب alnomoor.
async function sendWhatsappOtp(phone, code) {
  const { apiKey, templateName, whatsappAccountId, whatsappPhoneId } = otpiqConfig();
  const phoneNumber = toIqIntl(phone);
  const otp = String(code);

  const attempts = [
    {
      phoneNumber,
      smsType: 'whatsapp-template',
      provider: 'whatsapp',
      templateName,
      whatsappAccountId,
      whatsappPhoneId,
      templateParameters: { body: { 1: otp } },
    },
    {
      phoneNumber,
      smsType: 'verification',
      provider: 'whatsapp',
      verificationCode: otp,
      whatsappAccountId,
      whatsappPhoneId,
    },
  ];

  let lastError = 'تعذر إرسال رمز واتساب';
  for (const body of attempts) {
    try {
      const result = await postOtpiq(apiKey, body);
      if (result.ok) {
        console.log(`OTPIQ ok type=${body.smsType} to=${phoneNumber}`);
        return result.data;
      }
      lastError = errorText(result.data, `OTPIQ ${result.status}`);
      console.warn(`OTPIQ fail type=${body.smsType} status=${result.status} err=${lastError}`);
    } catch (error) {
      lastError = error.message || lastError;
      console.warn(`OTPIQ network type=${body.smsType} err=${lastError}`);
    }
  }

  const error = new Error(typeof lastError === 'string' ? lastError : 'تعذر إرسال رمز واتساب');
  error.status = 502;
  throw error;
}

/// يرسل رمز التحقق عبر رسالة SMS عادية بنفس حساب OTPIQ — لا يتطلب أي تطبيق إضافي.
async function sendSmsOtp(phone, code) {
  const { apiKey } = otpiqConfig();
  const phoneNumber = toIqIntl(phone);
  const otp = String(code);

  const attempts = [
    {
      phoneNumber,
      smsType: 'verification',
      provider: 'sms',
      verificationCode: otp,
    },
    {
      phoneNumber,
      smsType: 'sms',
      provider: 'sms',
      message: `رمز التحقق الخاص بك في MED QR: ${otp}`,
    },
  ];

  let lastError = 'تعذر إرسال رمز التحقق';
  for (const body of attempts) {
    try {
      const result = await postOtpiq(apiKey, body);
      if (result.ok) {
        console.log(`OTPIQ ok type=${body.smsType} to=${phoneNumber}`);
        return result.data;
      }
      lastError = errorText(result.data, `OTPIQ ${result.status}`);
      console.warn(`OTPIQ fail type=${body.smsType} status=${result.status} err=${lastError}`);
    } catch (error) {
      lastError = error.message || lastError;
      console.warn(`OTPIQ network type=${body.smsType} err=${lastError}`);
    }
  }

  const error = new Error(typeof lastError === 'string' ? lastError : 'تعذر إرسال رمز التحقق');
  error.status = 502;
  throw error;
}

module.exports = {
  digits,
  toIqIntl,
  toIqLocal,
  isIqMobile,
  phoneLookupValues,
  sendWhatsappOtp,
  sendSmsOtp,
};
