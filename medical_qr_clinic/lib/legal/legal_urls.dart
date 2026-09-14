import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../api/api_config.dart';

/// على الويب تُفتح صفحات الدومين نفسه، وعلى التطبيق تُفتح صفحات الخادم.
class LegalUrls {
  static String get privacy =>
      kIsWeb ? Uri.base.resolve('privacy.html').toString() : '${ApiConfig.baseUrl}/privacy';

  static String get accountDeletion =>
      kIsWeb ? Uri.base.resolve('account-deletion.html').toString() : '${ApiConfig.baseUrl}/account-deletion';

  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openPrivacy() => open(privacy);
  static Future<void> openAccountDeletion() => open(accountDeletion);
}
