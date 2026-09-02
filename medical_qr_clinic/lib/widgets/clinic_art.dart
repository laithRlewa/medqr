import 'package:flutter/material.dart';

/// رسوم طبية توضيحية لاستخدامها في الشاشات الرئيسية والحالات الفارغة.
abstract final class ClinicArt {
  static const dnaReview = 'assets/illustrations/dna_review.png';
  static const patientSearch = 'assets/illustrations/patient_search.png';
  static const clipboardMeds = 'assets/illustrations/clipboard_meds.png';
  static const heartCheck = 'assets/illustrations/heart_check.png';
  static const nurseLab = 'assets/illustrations/nurse_lab.png';
  static const dnaClipboard = 'assets/illustrations/dna_clipboard.png';
  static const telemedicine = 'assets/illustrations/telemedicine.png';
  static const ecgReview = 'assets/illustrations/ecg_review.png';
  static const labMonitor = 'assets/illustrations/lab_monitor.png';
  static const profileVisit = 'assets/illustrations/profile_visit.png';
}

class ClinicIllustration extends StatelessWidget {
  const ClinicIllustration(
    this.asset, {
    super.key,
    this.height = 140,
    this.width,
    this.opacity = 1,
  });

  final String asset;
  final double height;
  final double? width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Image.asset(
        asset,
        height: height,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => SizedBox(height: height * 0.4),
      ),
    );
  }
}
