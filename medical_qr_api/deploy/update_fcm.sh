#!/bin/bash
set -euo pipefail
# يُشغَّل على السيرفر بعد رفع الأرشيف ومفتاح Firebase إلى /tmp
install -d -m 700 /opt/medical-qr-api/secrets
if [ -f /tmp/firebase-adminsdk.json ]; then
  install -m 600 /tmp/firebase-adminsdk.json /opt/medical-qr-api/secrets/firebase-adminsdk.json
  shred -u /tmp/firebase-adminsdk.json 2>/dev/null || rm -f /tmp/firebase-adminsdk.json
fi
if [ -f /tmp/medical-qr-api.tar ]; then
  tar -xf /tmp/medical-qr-api.tar -C /opt/medical-qr-api
fi
cd /opt/medical-qr-api
npm install --omit=dev
ENV_FILE=/opt/medical-qr-api/.env
touch "$ENV_FILE"
set_kv() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}
set_kv FIREBASE_PROJECT_ID medqr-990bc
set_kv FIREBASE_SERVICE_ACCOUNT_PATH /opt/medical-qr-api/secrets/firebase-adminsdk.json
systemctl restart medical-qr-api
sleep 2
systemctl is-active medical-qr-api
journalctl -u medical-qr-api -n 20 --no-pager
