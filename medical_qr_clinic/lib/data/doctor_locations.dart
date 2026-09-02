import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// الخدمة حالياً مغلقة على بغداد فقط.
const String serviceCity = 'بغداد';

/// مركز بغداد للخريطة.
const LatLng baghdadCenter = LatLng(33.3152, 44.3661);

/// مواقع تجريبية احتياطية حسب معرّف الطبيب.
const Map<String, LatLng> baghdadClinicCoords = {
  'd1': LatLng(33.3128, 44.3615), // الكرادة
  'd2': LatLng(33.3402, 44.4001), // الأعظمية
  'd3': LatLng(33.2985, 44.3420), // المنصور
  'd6': LatLng(33.3255, 44.3855), // الجادرية
};

LatLng regionCenter(MapRegion region) => LatLng(region.centerLat, region.centerLng);

LatLng doctorLatLng(Doctor doctor, {List<MapRegion> regions = const []}) {
  if (doctor.latitude != null && doctor.longitude != null) {
    return LatLng(doctor.latitude!, doctor.longitude!);
  }
  final fixed = baghdadClinicCoords[doctor.id];
  if (fixed != null) return fixed;

  final regionId = doctor.regionId;
  if (regionId != null && regionId.isNotEmpty) {
    final region = regions.where((r) => r.id == regionId).firstOrNull;
    if (region != null) return regionCenter(region);
  }

  final h = doctor.id.hashCode.abs();
  final dLat = ((h % 97) - 48) / 12000.0;
  final dLng = (((h ~/ 97) % 97) - 48) / 12000.0;
  return LatLng(baghdadCenter.latitude + dLat, baghdadCenter.longitude + dLng);
}

bool isBaghdadDoctor(Doctor doctor) => doctor.city.trim() == serviceCity;
