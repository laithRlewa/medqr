const cities = ['بغداد', 'البصرة', 'أربيل', 'السليمانية', 'الموصل', 'النجف', 'كربلاء', 'كركوك', 'دهوك'];
const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const specialties = [
  'طب عام', 'أمراض القلب', 'الجراحة العامة', 'الأطفال', 'النساء والولادة',
  'العظام', 'الجلدية', 'الباطنية', 'الأعصاب', 'العيون', 'الأنف والأذن والحنجرة',
  'الأسنان', 'الطب النفسي', 'الأشعة', 'التخدير', 'المسالك البولية',
];

const fonts = [
  ('Cairo', 'القاهرة (Cairo)'),
  ('Tajawal', 'تجوال (Tajawal)'),
  ('Amiri', 'أميري (Amiri)'),
  ('Noto Kufi Arabic', 'نوتو كوفي (Noto Kufi)'),
];

const durations = [
  ('1_month', 'شهر واحد', 1),
  ('3_months', '3 أشهر', 3),
  ('6_months', '6 أشهر', 6),
  ('1_year', 'سنة كاملة', 12),
];

const actionTypesAr = {
  'login': 'تسجيل الدخول',
  'logout': 'تسجيل الخروج',
  'qr_scan': 'مسح QR',
  'patient_search': 'بحث عن مريض',
  'file_upload': 'رفع ملف',
  'file_download': 'تحميل ملف',
  'diagnosis_create': 'إنشاء تشخيص',
  'diagnosis_edit': 'تعديل تشخيص',
  'prescription_create': 'إنشاء وصفة',
  'access_create': 'منح وصول',
  'access_expire': 'انتهاء وصول',
  'visit_create': 'إنشاء زيارة',
  'profile_update': 'تحديث ملف',
  'post_create': 'إنشاء منشور',
  'account_delete': 'حذف حساب',
  'admin_action': 'إجراء إداري',
  'other': 'أخرى',
};

const fileTypesAr = {
  'prescription': 'وصفة',
  'lab_result': 'مخبري',
  'radiology': 'أشعة',
  'xray': 'سينية',
  'mri': 'رنين',
  'ct_scan': 'طبقي',
  'ultrasound': 'صوتية',
  'blood_test': 'دم',
  'document': 'مستند',
  'image': 'صورة',
  'other': 'أخرى',
};

const postCategoriesAr = {
  'achievement': 'إنجاز',
  'conference': 'مؤتمر',
  'workshop': 'ورشة',
  'seminar': 'ندوة',
  'publication': 'منشور علمي',
  'educational': 'توعية',
  'update': 'تحديث',
  'news': 'أخبار',
};

const phoneRegex = r'^07[0-9]{9}$';
const emailRegex = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';

bool validPhone(String? phone) => RegExp(phoneRegex).hasMatch((phone ?? '').trim());
bool validEmail(String? email) {
  if (email == null || email.trim().isEmpty) return true;
  return RegExp(emailRegex).hasMatch(email.trim());
}

String doctorStatusAr(String status) => switch (status) {
      'pending' => 'قيد المراجعة',
      'approved' => 'موافق عليه',
      'suspended' => 'معلّق',
      _ => status,
    };

String patientStatusAr(String status) => status == 'active' ? 'نشط' : 'معلّق';
String durationAr(String duration) =>
    durations.where((d) => d.$1 == duration).map((d) => d.$2).firstOrNull ?? duration;
String actionAr(String type) => actionTypesAr[type] ?? 'أخرى';
String roleAr(String role) => switch (role) {
      'admin' || 'owner' => 'مدير',
      'doctor' => 'طبيب',
      'patient' => 'مريض',
      _ => role,
    };
String fileTypeAr(String type) => fileTypesAr[type] ?? type;
String postCategoryAr(String category) => postCategoriesAr[category] ?? category;

String fromNow(DateTime date, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final diff = n.difference(date);
  if (diff.inMinutes.abs() < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return 'منذ ${(diff.inDays / 30).floor()} شهر';
}
