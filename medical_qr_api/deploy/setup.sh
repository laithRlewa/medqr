#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y postgresql postgresql-contrib nodejs npm curl ufw openssl

systemctl enable --now postgresql

install -d -m 755 /opt/medical-qr-api
if [ -f /tmp/medical-qr-api.tar ]; then
  tar -xf /tmp/medical-qr-api.tar -C /opt/medical-qr-api
fi

if [ ! -f /opt/medical-qr-api/.env ]; then
  PG_PASS="$(openssl rand -hex 18)"
  JWT_SECRET="$(openssl rand -hex 32)"
  cat > /opt/medical-qr-api/.env <<EOF
PORT=8080
DATABASE_URL=postgres://medical:${PG_PASS}@127.0.0.1:5432/medical_qr
JWT_SECRET=${JWT_SECRET}
DEMO_OTP=true
CORS_ORIGIN=*
EOF
  chmod 600 /opt/medical-qr-api/.env
else
  PG_PASS="$(sed -n 's/.*medical:\([^@]*\)@.*/\1/p' /opt/medical-qr-api/.env | head -n1)"
fi

sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'medical') THEN
    CREATE ROLE medical LOGIN PASSWORD '${PG_PASS}';
  ELSE
    ALTER ROLE medical WITH LOGIN PASSWORD '${PG_PASS}';
  END IF;
END
\$\$;
SQL

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='medical_qr'" | grep -q 1; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE medical_qr OWNER medical;"
fi
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "GRANT ALL PRIVILEGES ON DATABASE medical_qr TO medical;"

cd /opt/medical-qr-api
npm install --omit=dev

cat > /etc/systemd/system/medical-qr-api.service <<'EOF'
[Unit]
Description=Medical QR API
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/medical-qr-api
EnvironmentFile=/opt/medical-qr-api/.env
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

# If node lives elsewhere (some Ubuntu images)
if [ ! -x /usr/bin/node ] && command -v node >/dev/null; then
  NODE_BIN="$(command -v node)"
  sed -i "s#/usr/bin/node#${NODE_BIN}#" /etc/systemd/system/medical-qr-api.service
fi

systemctl daemon-reload
systemctl enable --now medical-qr-api
systemctl restart medical-qr-api

ufw allow 22/tcp || true
ufw allow 8080/tcp || true
echo "y" | ufw enable || true

sleep 3
systemctl --no-pager --full status medical-qr-api || true
curl -fsS http://127.0.0.1:8080/api/health
echo
echo "DEPLOY_OK"
