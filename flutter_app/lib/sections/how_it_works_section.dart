import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';

class HowItWorksSection extends StatelessWidget {
  final AppLocalizations l10n;
  const HowItWorksSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    final steps = [
      (num: 1, title: l10n.how_step1_t, desc: l10n.how_step1_d, bgColor: AppColors.blue100, textColor: AppColors.blue600),
      (num: 2, title: l10n.how_step2_t, desc: l10n.how_step2_d, bgColor: AppColors.purple100, textColor: AppColors.purple600),
      (num: 3, title: l10n.how_step3_t, desc: l10n.how_step3_d, bgColor: AppColors.green100, textColor: AppColors.green600),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                l10n.how_label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple600,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.how_title,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              // Step cards
              isDesktop ? _DesktopSteps(steps: steps) : _MobileSteps(steps: steps),
              const SizedBox(height: 96),
              // Smartglasses banner
              _SmartglassesBanner(l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSteps extends StatelessWidget {
  final List<({int num, String title, String desc, Color bgColor, Color textColor})> steps;
  const _DesktopSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(child: _StepCard(step: steps[i])),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Icon(Icons.chevron_right, size: 48, color: AppColors.gray300),
            ),
        ],
      ],
    );
  }
}

class _MobileSteps extends StatelessWidget {
  final List<({int num, String title, String desc, Color bgColor, Color textColor})> steps;
  const _MobileSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps
          .map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _StepCard(step: step),
              ))
          .toList(),
    );
  }
}

class _StepCard extends StatefulWidget {
  final ({int num, String title, String desc, Color bgColor, Color textColor}) step;
  const _StepCard({required this.step});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.1 : 0.04),
              blurRadius: _hovering ? 24 : 12,
              offset: Offset(0, _hovering ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedScale(
              scale: _hovering ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.step.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.step.num}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: widget.step.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.step.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 16),
            Text(
              widget.step.desc,
              style: const TextStyle(fontSize: 16, color: AppColors.gray600, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartglassesBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _SmartglassesBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.stone800, AppColors.stone900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.how_noqr_t,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              l10n.how_noqr_d,
              style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.9), height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _TagPill(label: 'Wearable Ready'),
              _TagPill(label: 'NFC & QR Optical Pay'),
              _TagPill(label: 'Beta Program Open', accent: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final bool accent;
  const _TagPill({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent ? AppColors.blue500.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: accent ? Border.all(color: AppColors.blue500.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: accent ? FontWeight.bold : FontWeight.w500,
          color: accent ? AppColors.blue300 : Colors.white,
        ),
      ),
    );
  }
}
