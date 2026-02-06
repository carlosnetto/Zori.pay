import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/auth_modal.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/phone_mockup.dart';

class HeroSection extends StatelessWidget {
  final AppLocalizations l10n;
  const HeroSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 120 : 80,
        horizontal: 24,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _HeroText(l10n: l10n)),
                    const SizedBox(width: 64),
                    _PhoneSection(),
                  ],
                )
              : Column(
                  children: [
                    _HeroText(l10n: l10n, centered: !isTablet),
                    const SizedBox(height: 64),
                    _PhoneSection(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final AppLocalizations l10n;
  final bool centered;
  const _HeroText({required this.l10n, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final titleParts = l10n.hero_title.split('.');
    final align = centered ? TextAlign.center : TextAlign.start;
    final crossAxis = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final wrapAlign = centered ? WrapAlignment.center : WrapAlignment.start;

    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        RichText(
          textAlign: align,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppColors.gray900,
              height: 1.1,
            ),
            children: titleParts.length >= 2
                ? [
                    TextSpan(text: '${titleParts[0]}.'),
                    TextSpan(
                      text: '\n${titleParts[1].trim()}',
                      style: const TextStyle(color: AppColors.blue600),
                    ),
                  ]
                : [TextSpan(text: l10n.hero_title, style: const TextStyle(color: AppColors.blue600))],
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            l10n.hero_subtitle,
            textAlign: align,
            style: const TextStyle(fontSize: 20, color: AppColors.gray600, height: 1.6),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: wrapAlign,
          children: [
            _HeroCta(
              label: l10n.hero_cta1,
              onTap: () => showAuthModal(context),
              primary: true,
            ),
            _HeroCta(label: l10n.hero_cta2, onTap: () {}, primary: false),
          ],
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          alignment: wrapAlign,
          children: [
            _BenefitBadge(label: l10n.hero_benefit1),
            _BenefitBadge(label: l10n.hero_benefit2),
            _BenefitBadge(label: l10n.hero_benefit3),
          ],
        ),
      ],
    );
  }
}

class _HeroCta extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _HeroCta({required this.label, required this.onTap, required this.primary});

  @override
  State<_HeroCta> createState() => _HeroCtaState();
}

class _HeroCtaState extends State<_HeroCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: widget.primary ? AppColors.blue600 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: widget.primary ? null : Border.all(color: AppColors.gray200, width: 2),
              boxShadow: widget.primary
                  ? [
                      BoxShadow(
                        color: AppColors.blue200.withValues(alpha: 0.7),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.primary ? Colors.white : AppColors.gray700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitBadge extends StatelessWidget {
  final String label;
  const _BenefitBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.green500,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _PhoneSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative blur circle
        Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.blue100.withValues(alpha: 0.6),
                AppColors.blue100.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const PhoneMockup(),
      ],
    );
  }
}
