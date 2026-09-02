/// صور احترافية محلية للأطباء التجريبيين.
const Map<String, String> doctorPhotosById = {
  'd1': 'assets/doctors/doctor_ahmed.jpg',
  'd2': 'assets/doctors/doctor_sara.jpg',
  'd3': 'assets/doctors/doctor_hussein.jpg',
  'd6': 'assets/doctors/doctor_nora.jpg',
};

const Map<String, String> doctorPhotosByName = {
  'أحمد الكعبي': 'assets/doctors/doctor_ahmed.jpg',
  'سارة الموسوي': 'assets/doctors/doctor_sara.jpg',
  'حسين الجبوري': 'assets/doctors/doctor_hussein.jpg',
  'نورا قادر': 'assets/doctors/doctor_nora.jpg',
};

String resolveDoctorPhoto({String? id, String? name, String existing = ''}) {
  if (existing.isNotEmpty) return existing;
  if (id != null && doctorPhotosById.containsKey(id)) return doctorPhotosById[id]!;
  if (name == null || name.isEmpty) return '';
  final clean = name.replaceFirst(RegExp(r'^د\.?\s*'), '').trim();
  return doctorPhotosByName[clean] ?? '';
}

bool isAssetPhoto(String path) => path.startsWith('assets/');
