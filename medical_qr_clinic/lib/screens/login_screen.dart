import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/brand_logo.dart';
import '../widgets/clinic_art.dart';
import '../widgets/mobile_kit.dart';
import 'register_screen.dart';

const _highlights = [
  (icon: Icons.folder_shared_outlined, title: 'سجل طبي موحّد', body: 'كل زياراتك وتحاليلك وأدويتك في مكان واحد'),
  (icon: Icons.qr_code_2_rounded, title: 'وصول برمز QR', body: 'يقرأ الطبيب ملفك خلال ثانية وبإذنك أنت'),
  (icon: Icons.lock_outline_rounded, title: 'خصوصية محمية', body: 'دخول برمز مؤقت عبر واتساب بدل كلمة المرور'),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final phone = TextEditingController();
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
    phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _intro.dispose();
    phone.dispose();
    super.dispose();
  }

  bool get _valid => phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;

  Future<void> _submit() async {
    if (!_valid) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ClinicScope.read(context).login(phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: SafeArea(
        top: !wide,
        child: wide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 4, child: _form(compact: false)),
                ],
              )
            : Column(
                children: [
                  const _MobileHeader(),
                  Expanded(child: _form(compact: true)),
                ],
              ),
      ),
    );
  }

  Widget _form({required bool compact}) {
    final store = ClinicScope.of(context);
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic)),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: compact ? 22 : 48, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مرحباً بعودتك',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ClinicColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل رقم هاتفك المسجّل وسنرسل لك رمز تحقق عبر واتساب.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: ClinicColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 26),
                  const _FieldLabel('رقم الهاتف'),
                  const SizedBox(height: 8),
                  _PhoneField(controller: phone, valid: _valid, onSubmit: _submit),
                  if (store.authError != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: store.authError!),
                  ],
                  const SizedBox(height: 22),
                  OrangeButton(
                    label: store.busy ? 'جاري إرسال الرمز…' : 'إرسال رمز واتساب',
                    icon: Icons.chat_bubble_outline_rounded,
                    loading: store.busy,
                    onTap: _valid ? _submit : null,
                  ),
                  const SizedBox(height: 14),
                  const _TrustNote(),
                  const SizedBox(height: 24),
                  const _OrDivider(),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                    label: const Text('إنشاء حساب جديد'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ClinicColors.primaryDeep),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.valid, required this.onSubmit});

  final TextEditingController controller;
  final bool valid;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(15),
      ],
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1.1),
      decoration: InputDecoration(
        hintText: '07XX XXX XXXX',
        hintTextDirection: TextDirection.ltr,
        hintStyle: const TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w500, color: ClinicColors.muted),
        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: ClinicColors.primary),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: valid
              ? const Icon(Icons.check_circle_rounded, color: ClinicColors.available, key: ValueKey('ok'))
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicRadii.pill),
          borderSide: const BorderSide(color: ClinicColors.border),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: error, fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: ClinicColors.muted),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'الرمز صالح لدقائق ولا يُستخدم إلا مرة واحدة',
            style: TextStyle(fontSize: 12, color: ClinicColors.muted),
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: ClinicColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('أو', style: TextStyle(color: ClinicColors.muted, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Divider(color: ClinicColors.border, height: 1)),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ClinicColors.primaryDeep, ClinicColors.primary, ClinicColors.accent],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: CustomPaint(painter: _QrPatternPainter(opacity: 0.10)),
            ),
          ),
          Column(
            children: [
              const BrandLogoTile(size: 62, padding: 10, radius: 20),
              const SizedBox(height: 12),
              const Wordmark(size: 20, color: Colors.white, accent: Colors.white),
              const SizedBox(height: 10),
              Text(
                'منصتك الصحية الرقمية في العراق',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ClinicColors.primaryDeep, ClinicColors.primary, ClinicColors.accent],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _QrPatternPainter(opacity: 0.09))),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        BrandLogoTile(size: 54, padding: 9, radius: 18),
                        SizedBox(width: 14),
                        Wordmark(size: 24, color: Colors.white, accent: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Center(child: ClinicIllustration(ClinicArt.heartCheck, height: 148)),
                    const SizedBox(height: 24),
                    const Text(
                      'صحتك… بمسحة واحدة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'سجل طبي إلكتروني آمن يرافقك من عيادة إلى أخرى، '
                      'يفتحه الطبيب برمز QR خاص بك وبموافقتك وحدك.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 38),
                    for (final item in _highlights) ...[
                      _Highlight(icon: item.icon, title: item.title, body: item.body),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// خلفية زخرفية من وحدات شبيهة بمربعات الـ QR، بتوزيع ثابت لا يتغيّر بين البنيات.
class _QrPatternPainter extends CustomPainter {
  const _QrPatternPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final random = math.Random(7);
    const cell = 34.0;
    final module = cell * 0.62;
    for (var y = -cell; y < size.height + cell; y += cell) {
      for (var x = -cell; x < size.width + cell; x += cell) {
        if (random.nextDouble() > 0.42) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, module, module),
            Radius.circular(module * 0.26),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPatternPainter oldDelegate) => oldDelegate.opacity != opacity;
}
