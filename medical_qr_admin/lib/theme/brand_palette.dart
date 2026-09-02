import 'package:flutter/material.dart';

/// لوحة ألوان مشتقّة من شعار MED QR:
/// البترولي الغامق #0B4459 والتركوازي #2D8AA8.
class BrandPalette {
  /// اللون الرئيسي للأزرار والعناصر النشطة.
  static const primary = Color(0xFF1A7A99);

  /// بترولي الشعار الغامق.
  static const primaryDeep = Color(0xFF0B4459);

  /// تركوازي الشعار كما هو.
  static const accent = Color(0xFF2D8AA8);

  static const bg = Color(0xFFF1F7F9);
  static const tint = Color(0xFFE4F1F5);
  static const border = Color(0xFFBFDCE5);
  static const ink = Color(0xFF0C2B37);
  static const muted = Color(0xFF6C8792);

  static const success = Color(0xFF2E9E7E);
  static const warning = Color(0xFFE0A32E);
  static const danger = Color(0xFFD2544B);

  static const darkBg = Color(0xFF061A22);
  static const darkSurface = Color(0xFF0B2731);
  static const darkCard = Color(0xFF10333F);

  /// ألوان الرسوم البيانية، مرتّبة لتبقى متمايزة وضمن عائلة الشعار.
  static const chart = <Color>[
    accent,
    primaryDeep,
    success,
    warning,
    Color(0xFF5B7FA6),
    danger,
  ];
}
