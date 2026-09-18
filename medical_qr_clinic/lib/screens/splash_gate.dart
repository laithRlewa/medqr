import 'package:flutter/material.dart';

import '../widgets/brand_logo.dart';
import 'login_screen.dart';
import 'new_password_screen.dart';
import 'otp_screen.dart';
import 'shell.dart';
import '../state/clinic_store.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  Widget _destination() {
    final store = ClinicScope.of(context);
    if (store.currentUser != null) return const ClinicShell();
    if (store.otp != null) return const OtpScreen();
    if (store.guestMode && !store.wantsAuth) return const ClinicShell();
    if (store.resetEmail != null) return const NewPasswordScreen();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      // الشاشتان تتبادلان الظهور في نفس المكان بدل أن تُزاح إحداهما.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('app'), child: _destination())
          : SplashScreen(
              key: const ValueKey('splash'),
              onDone: () => setState(() => _ready = true),
            ),
    );
  }
}
