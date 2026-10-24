import 'package:flutter/material.dart';
import 'package:pink_data_mobile/app_theme.dart';
import 'package:pink_data_mobile/auth_service.dart';
import 'package:pink_data_mobile/login_screen.dart';
import 'package:pink_data_mobile/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final theme = ThemeController();
  final auth = AuthService();
  await Future.wait([theme.load(), auth.restore()]);

  runApp(CreatorLensApp(auth: auth, theme: theme));
}

class CreatorLensApp extends StatelessWidget {
  const CreatorLensApp({super.key, required this.auth, required this.theme});

  final AuthService auth;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([auth, theme]),
      builder: (context, _) {
        return MaterialApp(
          title: 'CreatorLens',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: auth.isSignedIn
              ? HomeScreen(key: ValueKey(auth.email), auth: auth, theme: theme)
              : LoginScreen(auth: auth, theme: theme),
        );
      },
    );
  }
}