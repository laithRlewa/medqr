import 'package:flutter/material.dart';

import '../state/clinic_store.dart';
import '../theme/clinic_style.dart';
import '../widgets/mobile_kit.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final message = await ClinicScope.of(context).completePasswordReset(password.text, confirm.text);
    if (!mounted) return;
    if (message != null) setState(() => error = message);
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      backgroundColor: ClinicColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SoftCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: ClinicColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.lock_reset, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text('كلمة مرور جديدة', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('للحساب ${store.resetEmail}', style: const TextStyle(color: ClinicColors.muted)),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
                const SizedBox(height: 12),
                TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور')),
                const SizedBox(height: 20),
                OrangeButton(label: 'حفظ وتسجيل الدخول', onTap: _save),
                const SizedBox(height: 8),
                TextButton(onPressed: store.cancelOtp, child: const Text('إلغاء', style: TextStyle(color: ClinicColors.primary))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
