# medqr

منصة **MED QR** الصحية الرقمية: سجل طبي واحد يرافق المريض، ويُفتح للطبيب بمسح رمز QR.

## المشاريع

- `medical_qr_clinic` — تطبيق المريض والطبيب (Flutter / Android)
- `medical_qr_admin` — لوحة الإدارة
- `medical_qr_api` — واجهة Node.js و PostgreSQL
- `docs` — عرض المنتج

## التشغيل السريع

```bash
cd medical_qr_clinic
flutter pub get
flutter run
```

الخادم:

```bash
cd medical_qr_api
npm install
node src/server.js
```
