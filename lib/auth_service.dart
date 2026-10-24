import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Google sign-in -> backend JWT, stored securely. The UI listens to this object.
class AuthService extends ChangeNotifier {
  AuthService() {
    client = ApiClient(tokens: _tokens, onSessionExpired: _expire);
  }

  final TokenStore _tokens = TokenStore();
  late final ApiClient client;

  // serverClientId makes Google issue an ID token the backend can verify.
  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId,
  );

  bool _ready = false;
  bool _busy = false;
  String? _token;
  String? _name;
  String? _email;
  String? _error;

  bool get ready => _ready;
  bool get busy => _busy;
  bool get isSignedIn => _token != null;
  String? get name => _name;
  String? get email => _email;
  String? get error => _error;
  String? get token => _token;

  /// Called once at start-up.
  Future<void> restore() async {
    _token = await _tokens.readToken();
    _name = await _tokens.readName();
    _email = await _tokens.readEmail();
    _ready = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      if (!AppConfig.googleConfigured) {
        throw const _AuthFailure('Google sign-in is not configured yet (missing web client ID).');
      }

      // Always show the account chooser, even if an account was used before.
      await _google.signOut();
      final account = await _google.signIn();
      if (account == null) return; // the user closed the picker

      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        throw const _AuthFailure('Google did not return an ID token. Check the OAuth client setup.');
      }

      final http.Response res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': idToken}),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        throw _AuthFailure(ApiClient.errorMessage(res) ?? 'Sign-in failed (error ${res.statusCode}).');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const _AuthFailure('The server did not return a session token.');
      }

      final user = data['user'] as Map<String, dynamic>?;
      await _tokens.saveToken(token);
      await _tokens.saveUser(
        name: (user?['name'] as String?) ?? account.displayName,
        email: (user?['email'] as String?) ?? account.email,
      );

      _token = token;
      _name = (user?['name'] as String?) ?? account.displayName;
      _email = (user?['email'] as String?) ?? account.email;
    } on _AuthFailure catch (e) {
      _error = e.message;
    } on TimeoutException {
      _error = 'The server took too long to answer. Try again.';
    } catch (e) {
      _error = 'Could not sign in: $e';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
    await _expire();
  }

  Future<void> _expire() async {
    await _tokens.clear();
    _token = null;
    _name = null;
    _email = null;
    notifyListeners();
  }
}

class _AuthFailure implements Exception {
  const _AuthFailure(this.message);
  final String message;
}