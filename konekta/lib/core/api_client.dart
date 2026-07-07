import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

class ApiClient {
  final Session session;
  // For Android emulator: 10.0.2.2 maps to host's localhost.
  // For iOS simulator: localhost works directly.
  // Override with --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  ApiClient(this.session);

  Map<String, String> _headers({bool auth = true}) {
    final h = {'Content-Type': 'application/json'};
    if (auth && session.token != null) {
      h['Authorization'] = 'Bearer ${session.token}';
    }
    return h;
  }

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: path,
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await http.get(_u(path, query), headers: _headers(auth: auth))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(_u(path), headers: _headers(auth: auth), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(_u(path), headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(_u(path), headers: _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_u(path), headers: _headers())
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final body = res.body.isEmpty ? '{}' : res.body;
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    if (!ok) {
      throw ApiException(res.statusCode, parsed['message']?.toString() ?? parsed['error']?.toString() ?? 'Request failed');
    }
    return parsed['data'];
  }
}
