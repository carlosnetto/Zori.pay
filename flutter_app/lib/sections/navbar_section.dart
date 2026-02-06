import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/auth_modal.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/zori_logo.dart';

class NavbarSection extends StatelessWidget {
  final Map<String, GlobalKey> sectionKeys;

  const NavbarSection({super.key, required this.sectionKeys});

  void _scrollTo(String key) {
    final ctx = sectionKeys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  static const _languages = [
    (locale: 'en', flag: '\u{1F1FA}\u{1F1F8}', name: 'English'),
    (locale: 'es', flag: '\u{1F1EA}\u{1F1F8}', name: 'Espa\u00f1ol'),
    (locale: 'pt', flag: '\u{1F1E7}\u{1F1F7}', name: 'Portugu\u00eas'),
    (locale: 'zh', flag: '\u{1F1E8}\u{1F1F3}', name: '\u4E2D\u6587'),
    (locale: 'fr', flag: '\u{1F1EB}\u{1F1F7}', name: 'Fran\u00e7ais'),
    (locale: 'it', flag: '\u{1F1EE}\u{1F1F9}', name: 'Italiano'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const ZoriLogo(),
                const Spacer(),
                if (isDesktop) ...[
                  _NavLink(label: l10n.nav_problem, onTap: () => _scrollTo('problem')),
                  _NavLink(label: l10n.nav_solution, onTap: () => _scrollTo('solution')),
                  _NavLink(label: l10n.nav_how, onTap: () => _scrollTo('howItWorks')),
                  _NavLink(label: l10n.nav_faq, onTap: () => _scrollTo('faq')),
                  _NavLink(label: l10n.nav_about, onTap: () => _scrollTo('about')),
                  const SizedBox(width: 16),
                ],
                // Language dropdown
                _LanguageDropdown(),
                const SizedBox(width: 12),
                // Get Zori button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => showAuthModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue600,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue600.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.nav_cta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _hovering ? AppColors.blue600 : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final current = NavbarSection._languages.firstWhere(
          (l) => l.locale == locale.languageCode,
          orElse: () => NavbarSection._languages.first,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.locale,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700),
              items: NavbarSection._languages.map((lang) {
                return DropdownMenuItem(
                  value: lang.locale,
                  child: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                );
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  localeNotifier.value = Locale(code);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
