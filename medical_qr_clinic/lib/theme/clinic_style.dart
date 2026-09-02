import 'package:flutter/material.dart';

/// لوحة ألوان أوضح وأكثر تبايناً من شعار MED QR.
class ClinicColors {
  static const primary = Color(0xFF157A96);
  static const primaryDeep = Color(0xFF083847);
  static const accent = Color(0xFF1F8FB0);

  /// خلفية أنظف وأقل بهوتاناً.
  static const bg = Color(0xFFF7FBFC);
  static const bgDeep = Color(0xFFE3EEF2);
  static const tint = Color(0xFFDCECF1);

  static const card = Colors.white;
  static const available = Color(0xFF1F8F6F);
  static const ink = Color(0xFF071E27);
  static const muted = Color(0xFF4F6B76);
  static const star = Color(0xFFE89A2E);
  static const border = Color(0xFFB4D0DA);
}

class ClinicRadii {
  static const card = 18.0;
  static const pill = 28.0;
  static const button = 14.0;
  static const tile = 14.0;
}

bool isMobileLayout(BuildContext context) => MediaQuery.sizeOf(context).width < 840;

EdgeInsets clinicPadding(BuildContext context) =>
    EdgeInsets.fromLTRB(14, 10, 14, isMobileLayout(context) ? 100 : 18);

List<BoxShadow> get softShadow => [
      BoxShadow(
        color: ClinicColors.primaryDeep.withValues(alpha: 0.10),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ];

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'صباح الخير';
  if (hour < 17) return 'مساء الخير';
  return 'مساء الخير';
}
