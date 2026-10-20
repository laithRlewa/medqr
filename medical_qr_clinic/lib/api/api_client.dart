import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode = 0]);
  final String message;
  final int statusCode;
  bool get isUnauthorized => statusCode == 401;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient();

  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) async {
    final res = await http.delete(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> upload(String filePath, {String field = 'file'}) async {
    final request = http.MultipartRequest('POST', _uri('/api/upload'));
    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(field, filePath, filename: filePath.split(RegExp(r'[\\/]')).last));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final raw = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{'data': raw};
    if (res.statusCode >= 400) {
      throw ApiException(map['error']?.toString() ?? 'فشل الاتصال بالخادم (${res.statusCode})', res.statusCode);
    }
    return map;
  }
}
