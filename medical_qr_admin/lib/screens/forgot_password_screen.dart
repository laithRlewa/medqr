import 'package:flutter/material.dart';

import '../state/admin_store.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline, size: 40),
                  const SizedBox(height: 12),
                  Text('نسيت كلمة المرور؟', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('أدخل بريدك وسنرسل رابط إعادة التعيين'),
                  const SizedBox(height: 20),
                  if (store.passwordResetSent)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('تم إرسال الرابط. تحقق من بريدك الإلكتروني.'),
                    ),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: store.requestPasswordReset,
                      child: const Text('إرسال الرابط'),
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
