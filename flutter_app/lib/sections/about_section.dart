import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';

class AboutSection extends StatelessWidget {
  final AppLocalizations l10n;
  const AboutSection({super.key, required this.l10n});

  static const _imageUrls = [
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=400',
    'https://images.unsplash.com/photo-1551434678-e076c223a692?auto=format&fit=crop&q=80&w=400',
    'https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&q=80&w=400',
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=400',
  ];

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
                    Expanded(child: _AboutText(l10n: l10n)),
                    const SizedBox(width: 64),
                    Expanded(child: _ImageGrid()),
                  ],
                )
              : Column(
                  children: [
                    _AboutText(l10n: l10n),
                    const SizedBox(height: 48),
                    _ImageGrid(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AboutText extends StatelessWidget {
  final AppLocalizations l10n;
  const _AboutText({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.about_label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.blue600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.about_title,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.about_desc,
          style: const TextStyle(fontSize: 18, color: AppColors.gray600, height: 1.6),
        ),
        const SizedBox(height: 24),
        // Mission quote with blue left border
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border(left: BorderSide(color: AppColors.blue600, width: 4)),
          ),
          child: Text(
            l10n.about_mission,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.gray900,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.about_vision,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.blue600,
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative blur
        Positioned.fill(
          child: Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue50.withValues(alpha: 0.5),
                    AppColors.blue50.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column (staggered down)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    _RoundedImage(url: AboutSection._imageUrls[0], aspectRatio: 1),
                    const SizedBox(height: 16),
                    _RoundedImage(url: AboutSection._imageUrls[1], aspectRatio: 3 / 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right column
            Expanded(
              child: Column(
                children: [
                  _RoundedImage(url: AboutSection._imageUrls[2], aspectRatio: 3 / 4),
                  const SizedBox(height: 16),
                  _RoundedImage(url: AboutSection._imageUrls[3], aspectRatio: 1),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundedImage extends StatelessWidget {
  final String url;
  final double aspectRatio;
  const _RoundedImage({required this.url, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.gray200,
            child: const Icon(Icons.image, size: 48, color: AppColors.gray400),
          ),
        ),
      ),
    );
  }
}
