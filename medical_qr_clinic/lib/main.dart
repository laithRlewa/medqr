import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash_gate.dart';
import 'services/push_service.dart';
import 'state/clinic_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  final store = ClinicStore();
  final push = PushService.instance;
  push.registerToken = store.registerDeviceToken;
  push.unregisterToken = store.unregisterDeviceToken;
  push.refreshInbox = store.refresh;
  push.openNotification = (type, link) {
    store.openFromNotification(type: type, link: link);
  };
  push.isLoggedIn = () => store.loggedIn;
  await PushService.instance.bootstrap();
  await store.restoreSession();
  runApp(ClinicScope(store: store, child: const MedicalQrClinicApp()));
}

class MedicalQrClinicApp extends StatelessWidget {
  const MedicalQrClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
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

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashGate();
  }
}
