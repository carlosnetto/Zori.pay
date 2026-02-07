import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/home_page.dart';
import 'package:flutter_app/pages/dashboard_page.dart';
import 'package:flutter_app/pages/onboarding_page.dart';
import 'package:flutter_app/pages/settings_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppView>(
      valueListenable: viewNotifier,
      builder: (context, view, _) {
        return Stack(
          children: [
            switch (view) {
              AppView.landing => const HomePage(),
              AppView.dashboard => const DashboardPage(),
              AppView.onboarding => const OnboardingPage(),
              AppView.settings => const SettingsPage(),
            },
            // OAuth error banner
            ValueListenableBuilder<String?>(
              valueListenable: oauthError,
              builder: (context, error, _) {
                if (error == null) return const SizedBox.shrink();
                return Positioned(
                  top: 72,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Login failed: $error',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => oauthError.value = null,
                            child: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
