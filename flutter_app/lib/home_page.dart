import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/sections/navbar_section.dart';
import 'package:flutter_app/sections/hero_section.dart';
import 'package:flutter_app/sections/problem_section.dart';
import 'package:flutter_app/sections/solution_section.dart';
import 'package:flutter_app/sections/how_it_works_section.dart';
import 'package:flutter_app/sections/cta_section.dart';
import 'package:flutter_app/sections/faq_section.dart';
import 'package:flutter_app/sections/about_section.dart';
import 'package:flutter_app/sections/footer_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sectionKeys = <String, GlobalKey>{
    'hero': GlobalKey(),
    'problem': GlobalKey(),
    'solution': GlobalKey(),
    'howItWorks': GlobalKey(),
    'cta': GlobalKey(),
    'faq': GlobalKey(),
    'about': GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Spacer for fixed navbar
                const SizedBox(height: 64),
                HeroSection(key: _sectionKeys['hero'], l10n: l10n),
                ProblemSection(key: _sectionKeys['problem'], l10n: l10n),
                SolutionSection(key: _sectionKeys['solution'], l10n: l10n),
                HowItWorksSection(key: _sectionKeys['howItWorks'], l10n: l10n),
                CtaSection(key: _sectionKeys['cta'], l10n: l10n),
                FaqSection(key: _sectionKeys['faq'], l10n: l10n),
                AboutSection(key: _sectionKeys['about'], l10n: l10n),
                FooterSection(l10n: l10n),
              ],
            ),
          ),
          // Fixed navbar at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavbarSection(sectionKeys: _sectionKeys),
          ),
        ],
      ),
    );
  }
}
