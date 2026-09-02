const cities = [
  'بغداد', 'البصرة', 'أربيل', 'السليمانية', 'الموصل', 'النجف', 'كربلاء', 'كركوك', 'دهوك',
  'الديوانية', 'الناصرية', 'العمارة', 'الحلة', 'الرمادي', 'الفلوجة', 'تكريت', 'السماوة', 'الكوت',
];
const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const specialties = [
  'طب عام', 'طب الأسرة', 'طب الطوارئ', 'أمراض القلب', 'الأمراض الجلدية', 'الغدد الصماء',
  'أمراض الجهاز الهضمي', 'الباطنية', 'الأعصاب', 'الأورام', 'طب العيون', 'جراحة العظام',
  'طب الأطفال', 'الطب النفسي', 'أمراض الصدر', 'الأشعة', 'الجراحة العامة', 'المسالك البولية',
  'النساء والولادة', 'الأنف والأذن والحنجرة', 'طب الأسنان', 'التخدير',
];
const genders = [('Male', 'ذكر'), ('Female', 'أنثى')];
const weekDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const weekDaysShort = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

const fileTypesAr = {
  'prescription': 'وصفة طبية',
  'lab_result': 'نتيجة مخبرية',
  'radiology': 'أشعة',
  'xray': 'أشعة سينية',
  'mri': 'رنين مغناطيسي',
  'ct_scan': 'طبقي محوري',
  'ultrasound': 'موجات صوتية',
  'blood_test': 'تحليل دم',
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

const appointmentStatusAr = {
  'pending': 'قيد المراجعة',
  'confirmed': 'مؤكد',
  'declined': 'مرفوض',
  'cancelled': 'ملغى',
  'completed': 'مكتمل',
};

const phoneRegex = r'^07[0-9]{9}$';
const emailRegex = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';

bool validPhone(String? phone) {
  final raw = (phone ?? '').trim();
  if (RegExp(phoneRegex).hasMatch(raw)) return true;
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'^(964)?7[0-9]{9}$').hasMatch(digits);
}
bool validEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  return RegExp(emailRegex).hasMatch(email.trim());
}

String fileTypeAr(String type) => fileTypesAr[type] ?? type;
String postCategoryAr(String category) => postCategoriesAr[category] ?? category;
String appointmentStatusLabel(String status) => appointmentStatusAr[status] ?? status;
String genderAr(String gender) => gender == 'Male' ? 'ذكر' : 'أنثى';
String roleAr(String role) => switch (role) {
      'doctor' => 'طبيب',
      'patient' => 'مريض',
      _ => role,
    };
String dayName(int day) => weekDays[day.clamp(0, 6)];

String fromNow(DateTime date, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final diff = n.difference(date);
  if (diff.inMinutes.abs() < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return 'منذ ${(diff.inDays / 30).floor()} شهر';
}

List<String> generateSlots(String startTime, String endTime, {int minutes = 30}) {
  final start = _parseHm(startTime);
  final end = _parseHm(endTime);
  if (start == null || end == null || !start.isBefore(end)) return [];
  final slots = <String>[];
  var cursor = start;
  while (cursor.isBefore(end)) {
    slots.add('${cursor.hour.toString().padLeft(2, '0')}:${cursor.minute.toString().padLeft(2, '0')}');
    cursor = cursor.add(Duration(minutes: minutes));
  }
  return slots;
}

DateTime? _parseHm(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(2000, 1, 1, h, m);
}
