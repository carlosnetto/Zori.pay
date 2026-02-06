import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';


class ProblemSection extends StatelessWidget {
  final AppLocalizations l10n;
  const ProblemSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isTablet = MediaQuery.of(context).size.width > 768;

    final items = [
      (text: l10n.problem_items_0, icon: Icons.credit_card_off),
      (text: l10n.problem_items_1, icon: Icons.currency_exchange),
      (text: l10n.problem_items_2, icon: Icons.lock_outline),
      (text: l10n.problem_items_3, icon: Icons.block),
      (text: l10n.problem_items_4, icon: Icons.delete_outline),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.slate950,
      child: Stack(
        children: [
          // Decorative blur circles
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width * 0.25,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.red500.withValues(alpha: 0.1),
                    AppColors.red500.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: MediaQuery.of(context).size.width * 0.25,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.amber500.withValues(alpha: 0.1),
                    AppColors.amber500.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 128, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // Label
                    Text(
                      l10n.problem_label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red500,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title with gradient on last word
                    _GradientTitle(title: l10n.problem_title),
                    const SizedBox(height: 96),
                    // Cards grid
                    _buildGrid(items, isDesktop, isTablet),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<({String text, IconData icon})> items, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    final children = <Widget>[
      ...items.asMap().entries.map((e) => _ProblemCard(
            text: e.value.text,
            icon: e.value.icon,
            stagger: e.key % 2 == 0 && isDesktop,
          )),
      // Quote card
      _QuoteCard(quote: l10n.problem_quote),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: children.map((child) {
        return SizedBox(
          width: crossAxisCount == 1
              ? double.infinity
              : crossAxisCount == 2
                  ? (1200 - 24) / 2
                  : (1200 - 48) / 3,
          child: child,
        );
      }).toList(),
    );
  }
}

class _GradientTitle extends StatelessWidget {
  final String title;
  const _GradientTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final words = title.split(' ');
    if (words.length <= 1) {
      return Text(title, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white));
    }
    final lastWord = words.removeLast();

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1),
        children: [
          TextSpan(text: '${words.join(' ')} ', style: const TextStyle(color: Colors.white)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.red400, AppColors.amber500],
              ).createShader(bounds),
              child: Text(
                lastWord,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool stagger;
  const _ProblemCard({required this.text, required this.icon, this.stagger = false});

  @override
  State<_ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<_ProblemCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -8 : 0, 0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovering ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
          ),
          color: _hovering ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.red500.withValues(alpha: 0.2),
                        AppColors.amber500.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: Icon(widget.icon, size: 24, color: AppColors.red400),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _hovering ? Colors.white : AppColors.gray300,
                    height: 1.5,
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

class _QuoteCard extends StatelessWidget {
  final String quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.red600, AppColors.amber600],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.red600.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
