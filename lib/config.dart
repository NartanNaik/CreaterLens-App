/// App-wide settings. Override at build time with --dart-define, for example:
///   flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=123-abc.apps.googleusercontent.com
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pink-backend.vercel.app/api',
  );

  /// The WEB application OAuth client ID. It must be the same value as GOOGLE_CLIENT_ID on the backend,
  /// because the backend verifies the Google ID token against it.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '187379725888-75rgk2nj8ahgh1dblfte3ege0kf6pnld.apps.googleusercontent.com',
  );

  static bool get googleConfigured =>
      !googleServerClientId.startsWith('187379725888-75rgk2nj8ahgh1dblfte3ege0kf6pnld');
}