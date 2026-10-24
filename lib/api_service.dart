import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pink_data_mobile/auth_service.dart';

/// Outcome of sending one shared link to the backend.
class ShareResult {
  const ShareResult(this.ok, this.message);
  final bool ok;
  final String message;
}

class ApiService {
  ApiService(this._auth);

  final AuthService _auth;

  static const String baseUrl = 'https://pink-backend.vercel.app/api';

  Future<ShareResult> sendUrlToBackend(String rawText) async {
    final token = _auth.token;
    if (token == null) {
      return const ShareResult(false, 'Not signed in.');
    }

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/staging/share'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'url': rawText,
              'text': rawText,
              'title': 'Mobile Share',
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('share -> ${res.statusCode} ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return const ShareResult(true, 'Added to your Staging Queue');
      }
      if (res.statusCode == 401) {
        return const ShareResult(false, 'Session expired. Log out and sign in again.');
      }
      return ShareResult(false, 'Failed (error ${res.statusCode})');
    } on TimeoutException {
      return const ShareResult(false, 'Server took too long. Tap Retry.');
    } catch (e) {
      debugPrint('share error: $e');
      return const ShareResult(false, 'Could not reach the server.');
    }
  }
}