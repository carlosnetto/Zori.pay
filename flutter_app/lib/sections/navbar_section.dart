import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/auth_modal.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/zori_logo.dart';

class NavbarSection extends StatelessWidget {
  final Map<String, GlobalKey>? sectionKeys;

  const NavbarSection({super.key, this.sectionKeys});

  void _scrollTo(String key) {
    final ctx = sectionKeys?[key]?.currentContext;
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
    return ValueListenableBuilder<AppView>(
      valueListenable: viewNotifier,
      builder: (context, currentView, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isLoggedIn,
          builder: (context, loggedIn, _) {
            return _NavbarContent(
              currentView: currentView,
              loggedIn: loggedIn,
              sectionKeys: sectionKeys,
              onScrollTo: _scrollTo,
            );
          },
        );
      },
    );
  }
}

class _NavbarContent extends StatelessWidget {
  final AppView currentView;
  final bool loggedIn;
  final Map<String, GlobalKey>? sectionKeys;
  final void Function(String) onScrollTo;

  const _NavbarContent({
    required this.currentView,
    required this.loggedIn,
    required this.sectionKeys,
    required this.onScrollTo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isLanding = currentView == AppView.landing;

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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (!isLanding) {
                        viewNotifier.value = AppView.dashboard;
                      }
                    },
                    child: const ZoriLogo(),
                  ),
                ),
                const Spacer(),
                if (isLanding && isDesktop && sectionKeys != null) ...[
                  _NavLink(label: l10n.nav_problem, onTap: () => onScrollTo('problem')),
                  _NavLink(label: l10n.nav_solution, onTap: () => onScrollTo('solution')),
                  _NavLink(label: l10n.nav_how, onTap: () => onScrollTo('howItWorks')),
                  _NavLink(label: l10n.nav_faq, onTap: () => onScrollTo('faq')),
                  _NavLink(label: l10n.nav_about, onTap: () => onScrollTo('about')),
                  const SizedBox(width: 16),
                ],
                // Language dropdown
                const _LanguageDropdown(),
                const SizedBox(width: 12),
                // Right side: different actions based on view state
                if (loggedIn) ...[
                  _UserAvatar(
                    initials: _getInitials(userDisplayName),
                    onSignOut: () => logout(),
                    onSettings: () => viewNotifier.value = AppView.settings,
                    signOutLabel: l10n.nav_signout,
                    settingsLabel: l10n.nav_settings,
                    myAccountLabel: l10n.nav_myAccount,
                  ),
                ] else ...[
                  _NavPill(
                    label: l10n.nav_signin,
                    color: AppColors.blue600,
                    onTap: () => showAuthModal(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.substring(0, 2).toUpperCase();
  }
}

class _NavPill extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.color, required this.onTap});

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? Color.lerp(widget.color, Colors.black, 0.1)! : widget.color,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatefulWidget {
  final String initials;
  final VoidCallback onSignOut;
  final VoidCallback onSettings;
  final String signOutLabel;
  final String settingsLabel;
  final String myAccountLabel;
  const _UserAvatar({
    required this.initials,
    required this.onSignOut,
    required this.onSettings,
    required this.signOutLabel,
    required this.settingsLabel,
    required this.myAccountLabel,
  });

  @override
  State<_UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<_UserAvatar> {
  final _overlayKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      return;
    }

    final renderBox = _overlayKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userDisplayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            userDisplayEmail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _DropdownItem(
                      icon: Icons.settings_outlined,
                      label: widget.settingsLabel,
                      isLast: false,
                      onTap: () {
                        _overlayEntry?.remove();
                        _overlayEntry = null;
                        widget.onSettings();
                      },
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    _DropdownItem(
                      icon: Icons.logout,
                      label: widget.signOutLabel,
                      isLast: true,
                      onTap: () {
                        _overlayEntry?.remove();
                        _overlayEntry = null;
                        widget.onSignOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: _overlayKey,
        onTap: _toggleMenu,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.blue600,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;
  const _DropdownItem({required this.icon, required this.label, required this.onTap, this.isLast = true});

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.gray50 : Colors.transparent,
            borderRadius: widget.isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.zero,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppColors.gray600),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray700,
                ),
              ),
            ],
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
  const _LanguageDropdown();

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
