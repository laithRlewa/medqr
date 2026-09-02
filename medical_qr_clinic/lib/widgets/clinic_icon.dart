import 'package:flutter/material.dart';

/// مسارات أيقونات الرعاية الصحية المعبّأة (PNG).
abstract final class ClinicIcons {
  static const ambulance = 'assets/icons/ambulance.png';
  static const appointment = 'assets/icons/appointment.png';
  static const bandage = 'assets/icons/bandage.png';
  static const defibrillator = 'assets/icons/defibrillator.png';
  static const emergencyCall = 'assets/icons/emergency_call.png';
  static const emergencyRoom = 'assets/icons/emergency_room.png';
  static const femaleDoctor = 'assets/icons/female_doctor.png';
  static const fracture = 'assets/icons/fracture.png';
  static const gipsLeg = 'assets/icons/gips_leg.png';
  static const hospital = 'assets/icons/hospital.png';
  static const infusion = 'assets/icons/infusion.png';
  static const insurance = 'assets/icons/insurance.png';
  static const maleDoctor = 'assets/icons/male_doctor.png';
  static const medicalApp = 'assets/icons/medical_app.png';
  static const medicalBill = 'assets/icons/medical_bill.png';
  static const medicalCheckUp = 'assets/icons/medical_check_up.png';
  static const medicalRecord = 'assets/icons/medical_record.png';
  static const nurse = 'assets/icons/nurse.png';
  static const onlineConsultation = 'assets/icons/online_consultation.png';
  static const patient = 'assets/icons/patient.png';
  static const pregnancy = 'assets/icons/pregnancy.png';
  static const prescription = 'assets/icons/prescription.png';
  static const rubberGlove = 'assets/icons/rubber_glove.png';
  static const sfigmomanometer = 'assets/icons/sfigmomanometer.png';
  static const surgeon = 'assets/icons/surgeon.png';
  static const testTube = 'assets/icons/test_tube.png';
  static const transfusion = 'assets/icons/transfusion.png';
  static const waitingRoom = 'assets/icons/waiting_room.png';
  static const wheelchair = 'assets/icons/wheelchair.png';
  static const xRay = 'assets/icons/x_ray.png';

  static String forFileType(String type) => switch (type) {
        'prescription' => prescription,
        'lab_result' || 'blood_test' => testTube,
        'radiology' || 'xray' || 'mri' || 'ct_scan' || 'ultrasound' => xRay,
        'image' => medicalCheckUp,
        'document' => medicalRecord,
        _ => medicalRecord,
      };
}

class ClinicIcon extends StatelessWidget {
  const ClinicIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.opacity = 1,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double size;
  final double opacity;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined, size: size),
      ),
    );
  }
}

class ClinicIconBadge extends StatelessWidget {
  const ClinicIconBadge(
    this.asset, {
    super.key,
    this.size = 40,
    this.iconSize = 24,
    this.color,
    this.radius = 12,
  });

  final String asset;
  final double size;
  final double iconSize;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE8F3F5),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: ClinicIcon(asset, size: iconSize),
    );
  }
}
