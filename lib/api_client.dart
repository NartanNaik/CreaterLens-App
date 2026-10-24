import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

/// Small HTTP wrapper: adds the Bearer token and, on 401/403, silently refreshes it once
/// (the same behaviour as the web app's axios interceptor).
class ApiClient {
  ApiClient({required TokenStore tokens, required Future<void> Function() onSessionExpired})
      : _tokens = tokens,
        _onSessionExpired = onSessionExpired;

  final TokenStore _tokens;
  final Future<void> Function() _onSessionExpired;

  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<http.Response> _send(String path, Map<String, dynamic> body, String? token) {
    return http
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  /// POST with the saved token. Retries once after a refresh; if that fails the user is signed out.
  Future<http.Response> postAuthed(String path, Map<String, dynamic> body) async {
    final token = await _tokens.readToken();
    var res = await _send(path, body, token);

    if (res.statusCode == 401 || res.statusCode == 403) {
      final fresh = await _refresh(token);
      if (fresh == null) {
        await _onSessionExpired();
        return res;
      }
      res = await _send(path, body, fresh);
    }
    return res;
  }

  Future<String?> _refresh(String? oldToken) async {
    if (oldToken == null) return null;
    try {
      final res = await http
          .post(_uri('/auth/refresh'), headers: {'Authorization': 'Bearer $oldToken'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final fresh = (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String?;
      if (fresh == null || fresh.isEmpty) return null;

      await _tokens.saveToken(fresh);
      return fresh;
    } catch (_) {
      return null;
    }
  }

  /// Pulls the server's "error" message out of a JSON body, if there is one.
  static String? errorMessage(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['error'] is String) return data['error'] as String;
    } catch (_) {}
    return null;
  }
}