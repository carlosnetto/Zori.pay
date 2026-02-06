import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/zori_logo.dart';

class FooterSection extends StatelessWidget {
  final AppLocalizations l10n;
  const FooterSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop ? _DesktopFooter(l10n: l10n) : _MobileFooter(l10n: l10n),
              ),
            ),
          ),
          // Bottom bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.gray200)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.footer_rights, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                          Text(l10n.footer_slogan, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                        ],
                      )
                    : Column(
                        children: [
                          Text(l10n.footer_rights, style: const TextStyle(fontSize: 12, color: AppColors.gray400), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(l10n.footer_slogan, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFooter extends StatelessWidget {
  final AppLocalizations l10n;
  const _DesktopFooter({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + mission (span 2)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZoriLogo(),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  l10n.footer_mission,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.6),
                ),
              ),
            ],
          ),
        ),
        // Product links
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.nav_solution,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900),
              ),
              const SizedBox(height: 16),
              _FooterLink(label: 'App Store'),
              _FooterLink(label: 'Google Play'),
              _FooterLink(label: 'Security'),
            ],
          ),
        ),
        // Legal links
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900),
              ),
              const SizedBox(height: 16),
              _FooterLink(label: 'Privacy'),
              _FooterLink(label: 'Terms'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileFooter extends StatelessWidget {
  final AppLocalizations l10n;
  const _MobileFooter({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZoriLogo(),
        const SizedBox(height: 16),
        Text(
          l10n.footer_mission,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.6),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.nav_solution,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900),
        ),
        const SizedBox(height: 12),
        _FooterLink(label: 'App Store'),
        _FooterLink(label: 'Google Play'),
        _FooterLink(label: 'Security'),
        const SizedBox(height: 24),
        const Text(
          'Legal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900),
        ),
        const SizedBox(height: 12),
        _FooterLink(label: 'Privacy'),
        _FooterLink(label: 'Terms'),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: _hovering ? AppColors.blue600 : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}
