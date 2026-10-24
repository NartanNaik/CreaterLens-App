import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// VS Code "Dark+" and "Light+" colours, matching the web dashboard.
class AppTheme {
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: const Color(0xFF1E1E1E), // editor.background
    surface: const Color(0xFF252526), // sideBar.background
    bar: const Color(0xFF3C3C3C), // titleBar.activeBackground
    primary: const Color(0xFF0E639C), // button.background
    accent: const Color(0xFF007ACC),
    text: const Color(0xFFD4D4D4),
    muted: const Color(0xFF9D9D9D),
    border: const Color(0xFF3C3C3C),
    error: const Color(0xFFF14C4C),
    success: const Color(0xFF89D185),
  );

  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF3F3F3),
    bar: const Color(0xFFDDDDDD),
    primary: const Color(0xFF007ACC),
    accent: const Color(0xFF007ACC),
    text: const Color(0xFF333333),
    muted: const Color(0xFF616161),
    border: const Color(0xFFE5E5E5),
    error: const Color(0xFFA1260D),
    success: const Color(0xFF388A34),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color bar,
    required Color primary,
    required Color accent,
    required Color text,
    required Color muted,
    required Color border,
    required Color error,
    required Color success,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: bar,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: text,
            displayColor: text,
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[
        StatusColors(success: success, muted: muted),
      ],
    );
  }
}

/// Extra colours that Material's ColorScheme has no slot for.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.muted});

  final Color success;
  final Color muted;

  @override
  StatusColors copyWith({Color? success, Color? muted}) =>
      StatusColors(success: success ?? this.success, muted: muted ?? this.muted);

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

/// Remembers the chosen theme between launches.
class ThemeController extends ChangeNotifier {
  static const _key = 'creatorlens-theme';

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = prefs.getString(_key) == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {
      _mode = ThemeMode.dark;
    }
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, isDark ? 'dark' : 'light');
    } catch (_) {
      // Not saving the preference is not worth interrupting the user for.
    }
  }
}