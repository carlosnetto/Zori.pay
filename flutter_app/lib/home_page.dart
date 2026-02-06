import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/main.dart'; 
import 'package:flutter_app/auth_modal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zori.pay', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (MediaQuery.of(context).size.width > 900) ...[
            TextButton(onPressed: () {}, child: Text(l10n.nav_problem)),
            TextButton(onPressed: () {}, child: Text(l10n.nav_solution)),
            TextButton(onPressed: () {}, child: Text(l10n.nav_how)),
            TextButton(onPressed: () {}, child: Text(l10n.nav_faq)),
            TextButton(onPressed: () {}, child: Text(l10n.nav_about)),
          ],
          const SizedBox(width: 16),
          // Language Picker
          DropdownButton<Locale>(
            value: localeNotifier.value,
            icon: const Icon(Icons.language, size: 20),
            underline: const SizedBox(),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                localeNotifier.value = newLocale;
              }
            },
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('EN')),
              DropdownMenuItem(value: Locale('es'), child: Text('ES')),
              DropdownMenuItem(value: Locale('pt'), child: Text('PT')),
              DropdownMenuItem(value: Locale('zh'), child: Text('ZH')),
              DropdownMenuItem(value: Locale('fr'), child: Text('FR')),
              DropdownMenuItem(value: Locale('it'), child: Text('IT')),
            ],
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => showAuthModal(context),
            child: Text(l10n.nav_signin),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(l10n: l10n),
            _AboutSection(l10n: l10n),
            _ProblemSection(l10n: l10n),
            _SolutionSection(l10n: l10n),
            _HowItWorksSection(l10n: l10n),
            _FaqSection(l10n: l10n),
            _CtaSection(l10n: l10n),
            _Footer(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _HeroSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.hero_title,
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              l10n.hero_subtitle,
              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => showAuthModal(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: Text(l10n.hero_cta1, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  side: const BorderSide(color: Colors.white),
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.hero_cta2, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _BenefitTag(icon: Icons.credit_card_off, label: l10n.hero_benefit1),
              _BenefitTag(icon: Icons.trending_down, label: l10n.hero_benefit2),
              _BenefitTag(icon: Icons.visibility, label: l10n.hero_benefit3),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BenefitTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _AboutSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Text(l10n.about_label.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(l10n.about_title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.about_desc, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 24),
                      Text(l10n.about_mission, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width > 800) ...[
                  const SizedBox(width: 48),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.public, size: 64, color: Colors.blue),
                            const SizedBox(height: 16),
                            Text(l10n.about_card_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _ProblemSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(l10n.problem_label.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.redAccent, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(l10n.problem_title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                children: [
                  _ProblemItem(text: l10n.problem_items_0),
                  _ProblemItem(text: l10n.problem_items_1),
                  _ProblemItem(text: l10n.problem_items_2),
                  _ProblemItem(text: l10n.problem_items_3),
                  _ProblemItem(text: l10n.problem_items_4),
                ],
              ),
              const SizedBox(height: 48),
              Text(l10n.problem_quote, 
                style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemItem extends StatelessWidget {
  final String text;
  const _ProblemItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class _SolutionSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _SolutionSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Text(l10n.solution_label.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(color: Colors.green, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(l10n.solution_title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.solution_desc, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 64),
            _SolutionFeature(title: l10n.solution_feat1_t, desc: l10n.solution_feat1_d, icon: Icons.qr_code_scanner),
            const Divider(height: 64),
            _SolutionFeature(title: l10n.solution_feat2_t, desc: l10n.solution_feat2_d, icon: Icons.sync_alt),
            const Divider(height: 64),
            _SolutionFeature(title: l10n.solution_feat3_t, desc: l10n.solution_feat3_d, icon: Icons.shield),
          ],
        ),
      ),
    );
  }
}

class _SolutionFeature extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  const _SolutionFeature({required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 32, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _HowItWorksSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(l10n.how_label.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(l10n.how_title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 64),
              _HowStep(number: "1", title: l10n.how_step1_t, desc: l10n.how_step1_d),
              _HowStep(number: "2", title: l10n.how_step2_t, desc: l10n.how_step2_d),
              _HowStep(number: "3", title: l10n.how_step3_t, desc: l10n.how_step3_d),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  const _HowStep({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 48.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary,
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _FaqSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Text(l10n.faq_title, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.faq_subtitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 48),
            _FaqItem(q: l10n.faq_items_0_q, a: l10n.faq_items_0_a),
            _FaqItem(q: l10n.faq_items_1_q, a: l10n.faq_items_1_a),
            _FaqItem(q: l10n.faq_items_2_q, a: l10n.faq_items_2_a),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(a),
        ),
      ],
    );
  }
}

class _CtaSection extends StatelessWidget {
  final AppLocalizations l10n;
  const _CtaSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          Text(l10n.cta_title, 
            style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(l10n.cta_subtitle, 
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => showAuthModal(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
            ),
            child: Text(l10n.cta_btn, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final AppLocalizations l10n;
  const _Footer({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      width: double.infinity,
      child: Column(
        children: [
          const Text('Zori.pay', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(l10n.footer_mission, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 48),
          Text(l10n.footer_rights, 
            style: const TextStyle(color: Colors.white24, fontSize: 12),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}