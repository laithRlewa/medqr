import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/brand_logo.dart';
import '../widgets/mobile_kit.dart';
import '../widgets/ui.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final code = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // المؤقّت يعيد البناء فقط؛ العدّادان يُحسبان داخل build من حالة المتجر،
    // فلا يُقرأ context خارج build إطلاقاً.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    code.dispose();
    super.dispose();
  }

  String _title(OtpPurpose purpose) => switch (purpose) {
        OtpPurpose.login => 'تحقق لتسجيل الدخول',
        OtpPurpose.register => 'تحقق من رقم هاتفك',
        OtpPurpose.resetPassword => 'تحقق لاستعادة الحساب',
      };

  Future<void> _verify() async {
    if (code.text.length < 6) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ClinicScope.read(context).verifyOtp(code.text);
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final challenge = store.otp;
    if (challenge == null) return const SizedBox.shrink();
    final remaining = challenge.remaining.inSeconds.clamp(0, 9999);
    final resendIn = (30 - DateTime.now().difference(challenge.sentAt).inSeconds).clamp(0, 30);
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SoftCard(
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleIconBtn(icon: Icons.arrow_forward_ios, onTap: store.cancelOtp),
                  ),
                  const SizedBox(height: 8),
                  const BrandLogo(size: 88),
                  const SizedBox(height: 16),
                  Text(_title(challenge.purpose), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('أرسلنا رمز تحقق برسالة نصية إلى ${challenge.email}', textAlign: TextAlign.center, style: const TextStyle(color: ClinicColors.muted)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(18)),
                    child: Text('ينتهي خلال $minutes:$seconds', textAlign: TextAlign.center, style: const TextStyle(color: ClinicColors.muted, fontSize: 12)),
                  ),
                  if (store.authError != null) ...[
                    const SizedBox(height: 12),
                    Text(store.authError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  OtpBoxes(controller: code, onChanged: (_) => setState(() {}), onCompleted: (_) => _verify()),
                  const SizedBox(height: 20),
                  OrangeButton(label: 'تحقق', loading: store.busy, onTap: code.text.length == 6 && !store.busy ? _verify : null),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: resendIn > 0
                        ? null
                        : () async {
                            final err = await store.resendOtp();
                            if (!context.mounted) return;
                            if (err != null) toast(context, err);
                            code.clear();
                            setState(() {});
                          },
                    child: Text(
                      resendIn > 0 ? 'إعادة الإرسال خلال $resendIn ث' : 'لم تستلم الرمز؟ إعادة الإرسال',
                      style: TextStyle(color: resendIn > 0 ? ClinicColors.muted : ClinicColors.primary, fontWeight: FontWeight.w700),
                    ),
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

class OtpBoxes extends StatefulWidget {
  const OtpBoxes({super.key, required this.controller, this.onChanged, this.onCompleted});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => focus.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (text) {
                  setState(() {});
                  widget.onChanged?.call(text);
                  if (text.length == 6) widget.onCompleted?.call(text);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 6; i++)
                  Container(
                    width: 42,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ClinicColors.tint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: value.length == i || (value.length == 6 && i == 5) ? ClinicColors.primary : ClinicColors.border,
                        width: 1.6,
                      ),
                    ),
                    child: Text(
                      i < value.length ? value[i] : '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
