import 'package:flutter/material.dart';

import '../theme/clinic_style.dart';

const _navy = Color(0xFF0B4459);
const _accent = Color(0xFF2D8AA8);

/// نسبة عرض الشعار الكامل (رمز + كلمة) إلى عرض الرمز وحده في ملف PNG.
const _fullToMarkRatio = 796 / 593;

/// شعار MED QR الرسمي — نفس ملف شاشة البداية في كل شاشات التطبيق.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.wordmarkSize = 22,
    this.color = _navy,
    this.accent = _accent,
  });

  final double size;
  final bool showWordmark;
  final double wordmarkSize;
  final Color color;
  final Color accent;

  Widget _vectorMark() => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: MedQrMarkPainter(color: color, accent: accent)),
      );

  @override
  Widget build(BuildContext context) {
    final asset = showWordmark ? 'assets/brand/logo_full.png' : 'assets/brand/logo_mark.png';
    final width = showWordmark ? size * _fullToMarkRatio : size;
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
    return Semantics(
      label: 'MED QR',
      child: Image.asset(
        asset,
        width: width,
        cacheWidth: (width * pixelRatio).round(),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (_, _, _) => showWordmark
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _vectorMark(),
                  SizedBox(height: size * 0.11),
                  Wordmark(size: wordmarkSize, color: color, accent: accent),
                ],
              )
            : _vectorMark(),
      ),
    );
  }
}

/// الشعار داخل بطاقة بيضاء — للاستعمال فوق الخلفيات الملوّنة.
class BrandLogoTile extends StatelessWidget {
  const BrandLogoTile({super.key, this.size = 56, this.padding = 10, this.radius = 18});

  final double size;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: BrandLogo(size: size),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.size = 22,
    this.color = _navy,
    this.accent = _accent,
  });

  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'MED ', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          TextSpan(text: 'QR', style: TextStyle(color: accent, fontWeight: FontWeight.w800)),
        ],
      ),
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: size,
        height: 1,
        letterSpacing: size * 0.1,
      ),
    );
  }
}

/// شعار MED QR: إطار مسح + أنماط QR + صليب طبي في المركز.
/// كل الأبعاد بنسبة مئوية من ضلع المربع حتى يبقى متناسقاً بأي حجم.
class MedQrMarkPainter extends CustomPainter {
  const MedQrMarkPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final u = s / 100;

    final navy = Paint()
      ..color = color
      ..isAntiAlias = true;
    final tint = Paint()
      ..color = accent
      ..isAntiAlias = true;
    final bracket = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // تحت 56 بكسل تُرسم نسخة مبسّطة حتى يبقى الشعار واضحاً في الشريط العلوي.
    final detailed = s >= 56;
    _brackets(canvas, u, bracket);
    for (final origin in const [Offset(13, 13), Offset(66, 13), Offset(13, 66)]) {
      if (detailed) {
        _finder(canvas, u, origin, navy);
      } else {
        _square(canvas, u, origin.translate(3.5, 3.5), 14, 4.2, navy);
      }
    }
    if (detailed) {
      _alignment(canvas, u, navy);
      _modules(canvas, u, navy);
    }
    _cross(canvas, u, tint);
  }

  void _brackets(Canvas canvas, double u, Paint stroke) {
    const inset = 2.6;
    const arm = 19.0;
    const r = 9.0;
    const far = 100 - inset;
    final paths = [
      Path()
        ..moveTo(u * inset, u * (inset + arm))
        ..lineTo(u * inset, u * (inset + r))
        ..quadraticBezierTo(u * inset, u * inset, u * (inset + r), u * inset)
        ..lineTo(u * (inset + arm), u * inset),
      Path()
        ..moveTo(u * (far - arm), u * inset)
        ..lineTo(u * (far - r), u * inset)
        ..quadraticBezierTo(u * far, u * inset, u * far, u * (inset + r))
        ..lineTo(u * far, u * (inset + arm)),
      Path()
        ..moveTo(u * inset, u * (far - arm))
        ..lineTo(u * inset, u * (far - r))
        ..quadraticBezierTo(u * inset, u * far, u * (inset + r), u * far)
        ..lineTo(u * (inset + arm), u * far),
      Path()
        ..moveTo(u * (far - arm), u * far)
        ..lineTo(u * (far - r), u * far)
        ..quadraticBezierTo(u * far, u * far, u * far, u * (far - r))
        ..lineTo(u * far, u * (far - arm)),
    ];
    for (final path in paths) {
      canvas.drawPath(path, stroke);
    }
  }

  void _finder(Canvas canvas, double u, Offset origin, Paint fill) {
    _ring(canvas, u, origin, side: 21, thickness: 4.7, outerRadius: 6.4, fill: fill);
    _square(canvas, u, origin.translate(7, 7), 7, 2.0, fill);
  }

  void _alignment(Canvas canvas, double u, Paint fill) {
    _ring(canvas, u, const Offset(70, 70), side: 13, thickness: 3.4, outerRadius: 4.2, fill: fill);
    _square(canvas, u, const Offset(74.2, 74.2), 4.6, 1.4, fill);
  }

  void _ring(
    Canvas canvas,
    double u,
    Offset origin, {
    required double side,
    required double thickness,
    required double outerRadius,
    required Paint fill,
  }) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(u * origin.dx, u * origin.dy, u * side, u * side),
      Radius.circular(u * outerRadius),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        u * (origin.dx + thickness),
        u * (origin.dy + thickness),
        u * (side - thickness * 2),
        u * (side - thickness * 2),
      ),
      Radius.circular(u * (outerRadius - thickness * 0.55)),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(outer)
        ..addRRect(inner),
      fill,
    );
  }

  void _square(Canvas canvas, double u, Offset origin, double side, double radius, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(u * origin.dx, u * origin.dy, u * side, u * side),
        Radius.circular(u * radius),
      ),
      fill,
    );
  }

  void _modules(Canvas canvas, double u, Paint fill) {
    const module = 6.4;
    const centers = <Offset>[
      Offset(40, 23.5), Offset(50, 23.5), Offset(60, 23.5),
      Offset(23.5, 40), Offset(23.5, 50), Offset(23.5, 60),
      Offset(76.5, 40), Offset(76.5, 50), Offset(76.5, 60),
      Offset(40, 76.5), Offset(50, 76.5), Offset(60, 76.5),
    ];
    for (final c in centers) {
      _square(canvas, u, c.translate(-module / 2, -module / 2), module, 1.7, fill);
    }
  }

  void _cross(Canvas canvas, double u, Paint fill) {
    const thickness = 11.0;
    const arm = 17.0;
    final center = Offset(u * 50, u * 50);
    final radius = Radius.circular(u * 3);
    canvas.drawPath(
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: u * arm * 2, height: u * thickness),
          radius,
        ))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: u * thickness, height: u * arm * 2),
          radius,
        )),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant MedQrMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

/// شاشة البداية داخل التطبيق. تكرّر تخطيط الشاشة الأصلية (رمز في المنتصف
/// وكلمة MED QR أسفل الشاشة) حتى يكون الانتقال بينهما غير محسوس، ثم تضيف
/// حركة الظهور والشعار الفرعي ومؤشر التحميل.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  static const backgroundColor = ClinicColors.bg;

  /// نفس قياسات `flutter_native_splash`: الرمز 160dp والكلمة 160dp على بعد 48dp.
  static const markSize = 160.0;
  static const wordmarkWidth = 160.0;
  static const wordmarkBottomPadding = 48.0;

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagline = CurvedAnimation(parent: _anim, curve: const Interval(0.45, 1, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(
                    CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
                  ),
                  child: const BrandLogo(size: SplashScreen.markSize),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: tagline,
                  child: const Text(
                    'منصتك الصحية الرقمية في العراق',
                    style: TextStyle(color: ClinicColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: SplashScreen.wordmarkBottomPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: tagline,
                  child: const SizedBox(
                    width: 90,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: ClinicColors.bgDeep,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Image.asset(
                  'assets/brand/wordmark.png',
                  width: SplashScreen.wordmarkWidth,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const Wordmark(size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
