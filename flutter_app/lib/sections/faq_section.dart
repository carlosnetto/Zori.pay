import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';

class FaqSection extends StatelessWidget {
  final AppLocalizations l10n;
  const FaqSection({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      (q: l10n.faq_items_0_q, a: l10n.faq_items_0_a),
      (q: l10n.faq_items_1_q, a: l10n.faq_items_1_a),
      (q: l10n.faq_items_2_q, a: l10n.faq_items_2_a),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                l10n.faq_title,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.faq_subtitle,
                style: const TextStyle(fontSize: 16, color: AppColors.gray600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              ...items.map((item) => _FaqAccordion(question: item.q, answer: item.a)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqAccordion extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqAccordion({required this.question, required this.answer});

  @override
  State<_FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<_FaqAccordion> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isOpen = !_isOpen),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.125 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Text(
                        '+',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.gray600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 32),
              child: Text(
                widget.answer,
                style: const TextStyle(fontSize: 16, color: AppColors.gray600, height: 1.6),
              ),
            ),
            crossFadeState: _isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
