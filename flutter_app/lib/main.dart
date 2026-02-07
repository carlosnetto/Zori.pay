import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/app_shell.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

// View states matching React App.tsx pattern
enum AppView { landing, onboarding, dashboard, settings }

// Global notifiers
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
final ValueNotifier<AppView> viewNotifier = ValueNotifier(AppView.landing);
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

// Real user info (populated from API)
String userDisplayName = '';
String userDisplayEmail = '';
final ValueNotifier<String?> oauthError = ValueNotifier(null);

void login(Map<String, dynamic> user, {bool isNewUser = false}) {
  userDisplayName = (user['display_name'] as String?) ?? '';
  userDisplayEmail = (user['email'] as String?) ?? '';
  isLoggedIn.value = true;
  viewNotifier.value = isNewUser ? AppView.onboarding : AppView.dashboard;
}

Future<void> logout() async {
  await AuthService().logout();
  userDisplayName = '';
  userDisplayEmail = '';
  isLoggedIn.value = false;
  viewNotifier.value = AppView.landing;
}

void _restoreSession() {
  final authService = AuthService();
  if (authService.isAuthenticated()) {
    final user = authService.getUser();
    if (user != null) {
      userDisplayName = (user['display_name'] as String?) ?? '';
      userDisplayEmail = (user['email'] as String?) ?? '';
    }
    isLoggedIn.value = true;
    viewNotifier.value = AppView.dashboard;
  }
}

Future<void> _handleOAuthCallback() async {
  final uri = Uri.parse(web.window.location.href);
  final code = uri.queryParameters['code'];
  if (code == null) return;

  // Clear URL params immediately
  web.window.history.replaceState(''.toJS, '', uri.origin + uri.path);

  final authService = AuthService();
  try {
    final user = await authService.handleGoogleCallback(code);
    await authService.bypassPasskey();
    login(user, isNewUser: false);
  } catch (e) {
    debugPrint('OAuth callback error: $e');
    oauthError.value = e.toString();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Check for OAuth callback first
    final uri = Uri.parse(web.window.location.href);
    if (uri.queryParameters.containsKey('code')) {
      await _handleOAuthCallback();
    } else {
      _restoreSession();
    }
    if (mounted) setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Zori.pay',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.blue600,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(),
            useMaterial3: true,
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('pt'),
            Locale('zh'),
            Locale('fr'),
            Locale('it'),
          ],
          home: _initializing
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : const AppShell(),
        );
      },
    );
  }
}
