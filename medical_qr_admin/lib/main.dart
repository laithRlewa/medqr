import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'state/admin_store.dart';
import 'theme/app_theme.dart';
import 'widgets/brand_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  runApp(AdminScope(store: AdminStore(), child: const MedicalQrAdminApp()));
}

class MedicalQrAdminApp extends StatelessWidget {
  const MedicalQrAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return MaterialApp(
      title: store.branding.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(store.branding, dark: false),
      darkTheme: buildAppTheme(store.branding, dark: true),
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool splashDone = false;
  bool sessionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdminScope.of(context).restoreSession();
      if (mounted) setState(() => sessionChecked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!splashDone || !sessionChecked) {
      return SplashScreen(onDone: () => setState(() => splashDone = true));
    }
    final store = AdminScope.of(context);
    if (store.currentUser == null) return const LoginScreen();
    return const AdminShell();
  }
}
