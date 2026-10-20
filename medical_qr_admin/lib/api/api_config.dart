import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const _serverUrl = 'http://178.104.255.180:8080';
  static const baseUrl = kIsWeb ? '' : _serverUrl;

  static String mediaUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
}
