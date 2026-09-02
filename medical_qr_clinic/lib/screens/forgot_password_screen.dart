import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  String? error;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final message = await ClinicScope.of(context).requestPasswordReset(email.text);
    if (!mounted) return;
    if (message != null) {
      setState(() => error = message);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClinicColors.bg,
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SoftCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 48, color: ClinicColors.primary),
                const SizedBox(height: 12),
                const Text('أدخل بريدك لإرسال رمز التحقق'),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                const SizedBox(height: 16),
                OrangeButton(label: 'إرسال الرمز', onTap: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
