import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// No description provided for @nav_problem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get nav_problem;

  /// No description provided for @nav_solution.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get nav_solution;

  /// No description provided for @nav_how.
  ///
  /// In en, this message translates to:
  /// **'How it Works'**
  String get nav_how;

  /// No description provided for @nav_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get nav_faq;

  /// No description provided for @nav_about.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get nav_about;

  /// No description provided for @nav_cta.
  ///
  /// In en, this message translates to:
  /// **'Get Zori'**
  String get nav_cta;

  /// No description provided for @nav_openAccount.
  ///
  /// In en, this message translates to:
  /// **'Open Account'**
  String get nav_openAccount;

  /// No description provided for @nav_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get nav_signin;

  /// No description provided for @nav_signout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get nav_signout;

  /// No description provided for @nav_myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get nav_myAccount;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @hero_title.
  ///
  /// In en, this message translates to:
  /// **'Pay like a local. Anywhere.'**
  String get hero_title;

  /// No description provided for @hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold digital currencies. Scan local QR codes. Pay instantly with your phone or smartglasses.'**
  String get hero_subtitle;

  /// No description provided for @hero_benefit1.
  ///
  /// In en, this message translates to:
  /// **'Zero Cards Needed'**
  String get hero_benefit1;

  /// No description provided for @hero_benefit2.
  ///
  /// In en, this message translates to:
  /// **'Near-FX Rates'**
  String get hero_benefit2;

  /// No description provided for @hero_benefit3.
  ///
  /// In en, this message translates to:
  /// **'Smartglass Ready'**
  String get hero_benefit3;

  /// No description provided for @hero_cta1.
  ///
  /// In en, this message translates to:
  /// **'Get Zori'**
  String get hero_cta1;

  /// No description provided for @hero_cta2.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get hero_cta2;

  /// No description provided for @hero_mock_balance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get hero_mock_balance;

  /// No description provided for @hero_mock_scanner.
  ///
  /// In en, this message translates to:
  /// **'Scan local QR'**
  String get hero_mock_scanner;

  /// No description provided for @hero_mock_btn.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get hero_mock_btn;

  /// No description provided for @about_label.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get about_label;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'Built for a world without borders'**
  String get about_title;

  /// No description provided for @about_desc.
  ///
  /// In en, this message translates to:
  /// **'Zori was born from a simple observation: the world is moving faster than banking systems. Travelers, digital nomads, and expats shouldn’t be penalized with fees just for moving between countries.'**
  String get about_desc;

  /// No description provided for @about_mission.
  ///
  /// In en, this message translates to:
  /// **'Our mission is to make money as fluid as information. By leveraging secure digital currency infrastructure, we enable you to step into any shop, anywhere in the world, and pay just like someone who lives there.'**
  String get about_mission;

  /// No description provided for @about_vision.
  ///
  /// In en, this message translates to:
  /// **'No plastic. No hidden spreads. Just instant local payments.'**
  String get about_vision;

  /// No description provided for @about_card_title.
  ///
  /// In en, this message translates to:
  /// **'Borderless Finance'**
  String get about_card_title;

  /// No description provided for @problem_label.
  ///
  /// In en, this message translates to:
  /// **'The Problem'**
  String get problem_label;

  /// No description provided for @problem_title.
  ///
  /// In en, this message translates to:
  /// **'Paying abroad is always a mess'**
  String get problem_title;

  /// No description provided for @problem_items_0.
  ///
  /// In en, this message translates to:
  /// **'Cards charge high foreign transaction fees'**
  String get problem_items_0;

  /// No description provided for @problem_items_1.
  ///
  /// In en, this message translates to:
  /// **'Traditional exchange rates are unfair'**
  String get problem_items_1;

  /// No description provided for @problem_items_2.
  ///
  /// In en, this message translates to:
  /// **'Physical cards are often stolen or lost'**
  String get problem_items_2;

  /// No description provided for @problem_items_3.
  ///
  /// In en, this message translates to:
  /// **'Local apps like Pix or UPI are restricted to residents'**
  String get problem_items_3;

  /// No description provided for @problem_items_4.
  ///
  /// In en, this message translates to:
  /// **'You carry plastic while the world moves to QR'**
  String get problem_items_4;

  /// No description provided for @problem_quote.
  ///
  /// In en, this message translates to:
  /// **'\"There should be a better way.\"'**
  String get problem_quote;

  /// No description provided for @solution_label.
  ///
  /// In en, this message translates to:
  /// **'The Solution'**
  String get solution_label;

  /// No description provided for @solution_title.
  ///
  /// In en, this message translates to:
  /// **'Meet Zori'**
  String get solution_title;

  /// No description provided for @solution_desc.
  ///
  /// In en, this message translates to:
  /// **'The travel payment app that lets you pay like a local. No cards required. Use your phone or compatible smartglasses to bridge borders.'**
  String get solution_desc;

  /// No description provided for @solution_feat1_t.
  ///
  /// In en, this message translates to:
  /// **'Instant QR Scanning'**
  String get solution_feat1_t;

  /// No description provided for @solution_feat1_d.
  ///
  /// In en, this message translates to:
  /// **'Scan Pix, UPI, and local QR systems directly at any POS terminal.'**
  String get solution_feat1_d;

  /// No description provided for @solution_feat2_t.
  ///
  /// In en, this message translates to:
  /// **'Cross-Border Rails'**
  String get solution_feat2_t;

  /// No description provided for @solution_feat2_d.
  ///
  /// In en, this message translates to:
  /// **'Zori handles conversion instantly. The merchant receives normal local currency.'**
  String get solution_feat2_d;

  /// No description provided for @solution_feat3_t.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get solution_feat3_t;

  /// No description provided for @solution_feat3_d.
  ///
  /// In en, this message translates to:
  /// **'Merchants never see your identity or card numbers—because there are none.'**
  String get solution_feat3_d;

  /// No description provided for @solution_caption.
  ///
  /// In en, this message translates to:
  /// **'Pure digital payments at any POS. No plastic required.'**
  String get solution_caption;

  /// No description provided for @solution_kast.
  ///
  /// In en, this message translates to:
  /// **'Visiting a country where QR Codes are not popular? Need a card? Download Kast app, have a card in your apple pay or google wallet and transfer funds directly from Zori to the card.'**
  String get solution_kast;

  /// No description provided for @how_label.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get how_label;

  /// No description provided for @how_title.
  ///
  /// In en, this message translates to:
  /// **'How Zori works'**
  String get how_title;

  /// No description provided for @how_step1_t.
  ///
  /// In en, this message translates to:
  /// **'Hold digital currencies'**
  String get how_step1_t;

  /// No description provided for @how_step1_d.
  ///
  /// In en, this message translates to:
  /// **'Keep balances in Digital Dollars, Euros, and more. Powered by stablecoins.'**
  String get how_step1_d;

  /// No description provided for @how_step2_t.
  ///
  /// In en, this message translates to:
  /// **'Convert instantly'**
  String get how_step2_t;

  /// No description provided for @how_step2_d.
  ///
  /// In en, this message translates to:
  /// **'Switch between currencies in seconds at near-FX rates.'**
  String get how_step2_d;

  /// No description provided for @how_step3_t.
  ///
  /// In en, this message translates to:
  /// **'Scan and pay'**
  String get how_step3_t;

  /// No description provided for @how_step3_d.
  ///
  /// In en, this message translates to:
  /// **'Zori recognizes the QR and pays in local currency automatically via your device.'**
  String get how_step3_d;

  /// No description provided for @how_noqr_t.
  ///
  /// In en, this message translates to:
  /// **'Future Ready: Smartglasses'**
  String get how_noqr_t;

  /// No description provided for @how_noqr_d.
  ///
  /// In en, this message translates to:
  /// **'Zori is built for the next generation of payments. Pay hands-free with compatible AR glasses.'**
  String get how_noqr_d;

  /// No description provided for @faq_title.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq_title;

  /// No description provided for @faq_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to know about Zori.'**
  String get faq_subtitle;

  /// No description provided for @faq_items_0_q.
  ///
  /// In en, this message translates to:
  /// **'What is Zori?'**
  String get faq_items_0_q;

  /// No description provided for @faq_items_0_a.
  ///
  /// In en, this message translates to:
  /// **'Zori is a payment wallet that lets you pay any local QR system using your digital currencies.'**
  String get faq_items_0_a;

  /// No description provided for @faq_items_1_q.
  ///
  /// In en, this message translates to:
  /// **'Is it safe?'**
  String get faq_items_1_q;

  /// No description provided for @faq_items_1_a.
  ///
  /// In en, this message translates to:
  /// **'Yes, Zori uses institutional-grade security to protect your balances and transactions.'**
  String get faq_items_1_a;

  /// No description provided for @faq_items_2_q.
  ///
  /// In en, this message translates to:
  /// **'How do smartglasses work?'**
  String get faq_items_2_q;

  /// No description provided for @faq_items_2_a.
  ///
  /// In en, this message translates to:
  /// **'Compatible smartglasses use Zori Vision to recognize QR codes in your field of view for hands-free payment.'**
  String get faq_items_2_a;

  /// No description provided for @cta_title.
  ///
  /// In en, this message translates to:
  /// **'Money shouldn’t have borders'**
  String get cta_title;

  /// No description provided for @cta_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Zori makes them disappear. Pay like a local today.'**
  String get cta_subtitle;

  /// No description provided for @cta_btn.
  ///
  /// In en, this message translates to:
  /// **'Start with Zori'**
  String get cta_btn;

  /// No description provided for @footer_mission.
  ///
  /// In en, this message translates to:
  /// **'Money shouldn\'t have borders. Zori makes them disappear.'**
  String get footer_mission;

  /// No description provided for @footer_rights.
  ///
  /// In en, this message translates to:
  /// **'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79'**
  String get footer_rights;

  /// No description provided for @footer_slogan.
  ///
  /// In en, this message translates to:
  /// **'Built for a world without plastic cards.'**
  String get footer_slogan;

  /// No description provided for @modal_title.
  ///
  /// In en, this message translates to:
  /// **'App available soon'**
  String get modal_title;

  /// No description provided for @modal_desc.
  ///
  /// In en, this message translates to:
  /// **'We are working hard to bring Zori to you. Stay tuned!'**
  String get modal_desc;

  /// No description provided for @modal_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get modal_close;

  /// No description provided for @auth_loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zori'**
  String get auth_loginTitle;

  /// No description provided for @auth_loginDesc.
  ///
  /// In en, this message translates to:
  /// **'Login or open your account to start paying like a local.'**
  String get auth_loginDesc;

  /// No description provided for @auth_googleBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get auth_googleBtn;

  /// No description provided for @auth_simNew.
  ///
  /// In en, this message translates to:
  /// **'Simulate New User'**
  String get auth_simNew;

  /// No description provided for @auth_simExist.
  ///
  /// In en, this message translates to:
  /// **'Simulate Existing User'**
  String get auth_simExist;

  /// No description provided for @auth_passkeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify with Passkey'**
  String get auth_passkeyTitle;

  /// No description provided for @auth_passkeyWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for passkey...'**
  String get auth_passkeyWait;

  /// No description provided for @auth_passkeyRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get auth_passkeyRetry;

  /// No description provided for @auth_passkeyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get auth_passkeyCancel;

  /// No description provided for @dashboard_balance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get dashboard_balance;

  /// No description provided for @dashboard_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get dashboard_send;

  /// No description provided for @dashboard_receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get dashboard_receive;

  /// No description provided for @dashboard_convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get dashboard_convert;

  /// No description provided for @dashboard_transactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get dashboard_transactions;

  /// No description provided for @dashboard_empty.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions.'**
  String get dashboard_empty;

  /// No description provided for @kyc_title.
  ///
  /// In en, this message translates to:
  /// **'Open your account'**
  String get kyc_title;

  /// No description provided for @kyc_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide your details to open a Zori account in Brazil.'**
  String get kyc_subtitle;

  /// No description provided for @kyc_country.
  ///
  /// In en, this message translates to:
  /// **'Country of Residence'**
  String get kyc_country;

  /// No description provided for @kyc_brazil.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get kyc_brazil;

  /// No description provided for @kyc_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get kyc_fullName;

  /// No description provided for @kyc_motherName.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Full Name'**
  String get kyc_motherName;

  /// No description provided for @kyc_cpf.
  ///
  /// In en, this message translates to:
  /// **'CPF (Brazilian ID)'**
  String get kyc_cpf;

  /// No description provided for @kyc_cpfErrorIncomplete.
  ///
  /// In en, this message translates to:
  /// **'CPF must have 11 digits'**
  String get kyc_cpfErrorIncomplete;

  /// No description provided for @kyc_cpfErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid CPF'**
  String get kyc_cpfErrorInvalid;

  /// No description provided for @kyc_email.
  ///
  /// In en, this message translates to:
  /// **'Email (Google-linked)'**
  String get kyc_email;

  /// No description provided for @kyc_emailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get kyc_emailError;

  /// No description provided for @kyc_phone.
  ///
  /// In en, this message translates to:
  /// **'Mobile Phone'**
  String get kyc_phone;

  /// No description provided for @kyc_uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get kyc_uploadTitle;

  /// No description provided for @kyc_idPdf.
  ///
  /// In en, this message translates to:
  /// **'CNH (PDF)'**
  String get kyc_idPdf;

  /// No description provided for @kyc_or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get kyc_or;

  /// No description provided for @kyc_and.
  ///
  /// In en, this message translates to:
  /// **'AND'**
  String get kyc_and;

  /// No description provided for @kyc_idFront.
  ///
  /// In en, this message translates to:
  /// **'CNH (Front)'**
  String get kyc_idFront;

  /// No description provided for @kyc_idBack.
  ///
  /// In en, this message translates to:
  /// **'CNH (Back)'**
  String get kyc_idBack;

  /// No description provided for @kyc_selfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie holding CNH'**
  String get kyc_selfie;

  /// No description provided for @kyc_proofAddr.
  ///
  /// In en, this message translates to:
  /// **'Proof of Address (Utility Bill)'**
  String get kyc_proofAddr;

  /// No description provided for @kyc_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get kyc_submit;

  /// No description provided for @kyc_successTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Received'**
  String get kyc_successTitle;

  /// No description provided for @kyc_successDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account is in the process of opening.'**
  String get kyc_successDesc;

  /// No description provided for @kyc_successNote.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned to your e-mail and cell phone and reply to the messages you receive. We will need some contracts digitally signed by gov.br which we will share with you shortly.'**
  String get kyc_successNote;

  /// No description provided for @kyc_backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get kyc_backHome;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_back.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get settings_back;

  /// No description provided for @settings_notDefined.
  ///
  /// In en, this message translates to:
  /// **'Not defined'**
  String get settings_notDefined;

  /// No description provided for @settings_personalSection.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get settings_personalSection;

  /// No description provided for @settings_contactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get settings_contactSection;

  /// No description provided for @settings_blockchainSection.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get settings_blockchainSection;

  /// No description provided for @settings_bankAccountsSection.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get settings_bankAccountsSection;

  /// No description provided for @settings_documentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get settings_documentsSection;

  /// No description provided for @settings_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get settings_fullName;

  /// No description provided for @settings_dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get settings_dateOfBirth;

  /// No description provided for @settings_birthCity.
  ///
  /// In en, this message translates to:
  /// **'City of Birth'**
  String get settings_birthCity;

  /// No description provided for @settings_birthCountry.
  ///
  /// In en, this message translates to:
  /// **'Country of Birth'**
  String get settings_birthCountry;

  /// No description provided for @settings_phones.
  ///
  /// In en, this message translates to:
  /// **'Phones'**
  String get settings_phones;

  /// No description provided for @settings_emails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get settings_emails;

  /// No description provided for @settings_loginCredential.
  ///
  /// In en, this message translates to:
  /// **'Login credential'**
  String get settings_loginCredential;

  /// No description provided for @settings_polygonAddress.
  ///
  /// In en, this message translates to:
  /// **'Polygon Address'**
  String get settings_polygonAddress;

  /// No description provided for @settings_copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get settings_copyAddress;

  /// No description provided for @settings_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get settings_copied;

  /// No description provided for @settings_brazilBank.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get settings_brazilBank;

  /// No description provided for @settings_usaBank.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get settings_usaBank;

  /// No description provided for @settings_bankCode.
  ///
  /// In en, this message translates to:
  /// **'Bank Code'**
  String get settings_bankCode;

  /// No description provided for @settings_branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get settings_branch;

  /// No description provided for @settings_accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get settings_accountNumber;

  /// No description provided for @settings_routingNumber.
  ///
  /// In en, this message translates to:
  /// **'Routing Number'**
  String get settings_routingNumber;

  /// No description provided for @settings_brazilDocs.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get settings_brazilDocs;

  /// No description provided for @settings_usaDocs.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get settings_usaDocs;

  /// No description provided for @settings_cpf.
  ///
  /// In en, this message translates to:
  /// **'CPF'**
  String get settings_cpf;

  /// No description provided for @settings_rg.
  ///
  /// In en, this message translates to:
  /// **'RG'**
  String get settings_rg;

  /// No description provided for @settings_rgIssuer.
  ///
  /// In en, this message translates to:
  /// **'RG Issuer'**
  String get settings_rgIssuer;

  /// No description provided for @settings_rgIssuedAt.
  ///
  /// In en, this message translates to:
  /// **'RG Issue Date'**
  String get settings_rgIssuedAt;

  /// No description provided for @settings_ssnLast4.
  ///
  /// In en, this message translates to:
  /// **'SSN (last 4)'**
  String get settings_ssnLast4;

  /// No description provided for @settings_driversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get settings_driversLicense;

  /// No description provided for @settings_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settings_edit;

  /// No description provided for @settings_cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_cancelEdit;

  /// No description provided for @settings_submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get settings_submitForApproval;

  /// No description provided for @settings_noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to submit'**
  String get settings_noChanges;

  /// No description provided for @settings_submittingChanges.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get settings_submittingChanges;

  /// No description provided for @settings_changesSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Changes Submitted'**
  String get settings_changesSubmitted;

  /// No description provided for @settings_changesSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your change request has been sent to the compliance officer for review.'**
  String get settings_changesSubmittedDesc;

  /// No description provided for @settings_editModeHint.
  ///
  /// In en, this message translates to:
  /// **'Fill in blank fields or request changes to existing data.'**
  String get settings_editModeHint;

  /// No description provided for @settings_pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending Changes'**
  String get settings_pendingChanges;

  /// No description provided for @settings_saveOrCancelFirst.
  ///
  /// In en, this message translates to:
  /// **'Please save or cancel \"{section}\" first'**
  String settings_saveOrCancelFirst(Object section);

  /// No description provided for @settings_new.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get settings_new;

  /// No description provided for @settings_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get settings_add;

  /// No description provided for @settings_mobile.
  ///
  /// In en, this message translates to:
  /// **'mobile'**
  String get settings_mobile;

  /// No description provided for @settings_home.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get settings_home;

  /// No description provided for @settings_work.
  ///
  /// In en, this message translates to:
  /// **'work'**
  String get settings_work;

  /// No description provided for @settings_voip.
  ///
  /// In en, this message translates to:
  /// **'voip'**
  String get settings_voip;

  /// No description provided for @settings_personal.
  ///
  /// In en, this message translates to:
  /// **'personal'**
  String get settings_personal;

  /// No description provided for @settings_other.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get settings_other;

  /// No description provided for @settings_phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get settings_phoneRequired;

  /// No description provided for @settings_phoneInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Use ITU format: +55...'**
  String get settings_phoneInvalidFormat;

  /// No description provided for @settings_phoneDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This phone already exists'**
  String get settings_phoneDuplicate;

  /// No description provided for @settings_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get settings_emailRequired;

  /// No description provided for @settings_emailInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get settings_emailInvalidFormat;

  /// No description provided for @settings_emailDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This email already exists'**
  String get settings_emailDuplicate;

  /// No description provided for @settings_addressSection.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settings_addressSection;

  /// No description provided for @settings_addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get settings_addressLine1;

  /// No description provided for @settings_addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get settings_addressLine2;

  /// No description provided for @settings_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get settings_city;

  /// No description provided for @settings_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get settings_state;

  /// No description provided for @settings_postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get settings_postalCode;

  /// No description provided for @settings_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get settings_country;

  /// No description provided for @settings_delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get settings_delete;

  /// No description provided for @settings_newLogin.
  ///
  /// In en, this message translates to:
  /// **'new login'**
  String get settings_newLogin;

  /// No description provided for @settings_setAsLogin.
  ///
  /// In en, this message translates to:
  /// **'Set as login'**
  String get settings_setAsLogin;

  /// No description provided for @settings_cancelSetLogin.
  ///
  /// In en, this message translates to:
  /// **'Cancel set as login'**
  String get settings_cancelSetLogin;

  /// No description provided for @settings_mustSelectNewLoginPhone.
  ///
  /// In en, this message translates to:
  /// **'You must select a new login phone before deleting the current one'**
  String get settings_mustSelectNewLoginPhone;

  /// No description provided for @settings_mustSelectNewLoginEmail.
  ///
  /// In en, this message translates to:
  /// **'You must select a new login email before deleting the current one'**
  String get settings_mustSelectNewLoginEmail;

  /// No description provided for @settings_newLoginPhone.
  ///
  /// In en, this message translates to:
  /// **'New login phone'**
  String get settings_newLoginPhone;

  /// No description provided for @settings_newLoginEmail.
  ///
  /// In en, this message translates to:
  /// **'New login email'**
  String get settings_newLoginEmail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fr',
    'it',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
