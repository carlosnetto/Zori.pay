import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';

class SolutionSection extends StatelessWidget {
  final AppLocalizations l10n;
  const SolutionSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _SolutionImage()),
                    const SizedBox(width: 64),
                    Expanded(child: _SolutionContent(l10n: l10n)),
                  ],
                )
              : Column(
                  children: [
                    _SolutionContent(l10n: l10n),
                    const SizedBox(height: 48),
                    _SolutionImage(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SolutionImage extends StatefulWidget {
  @override
  State<_SolutionImage> createState() => _SolutionImageState();
}

class _SolutionImageState extends State<_SolutionImage> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            AnimatedScale(
              scale: _hovering ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: Image.asset(
                'assets/images/solution_hero.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 500,
              ),
            ),
            // Dark gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Caption overlay
            Positioned(
              left: 32,
              bottom: 32,
              right: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green500,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'No Hardware Needed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.solution_caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionContent extends StatelessWidget {
  final AppLocalizations l10n;
  const _SolutionContent({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final features = [
      (title: l10n.solution_feat1_t, desc: l10n.solution_feat1_d),
      (title: l10n.solution_feat2_t, desc: l10n.solution_feat2_d),
      (title: l10n.solution_feat3_t, desc: l10n.solution_feat3_d),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.solution_label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.green600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.solution_title,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.solution_desc,
          style: const TextStyle(fontSize: 20, color: AppColors.gray600, height: 1.6),
        ),
        const SizedBox(height: 24),
        ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.green100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 24, color: AppColors.green600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                        const SizedBox(height: 4),
                        Text(f.desc, style: const TextStyle(fontSize: 16, color: AppColors.gray600)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        // Kast promotion
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray900,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.solution_kast,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray800, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
