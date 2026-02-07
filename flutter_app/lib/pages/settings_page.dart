import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/sections/navbar_section.dart';
import 'package:flutter_app/services/profile_service.dart';
import 'package:flutter_app/services/reference_data_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _EditableSection { personal, documents, contact, address }

class _EditedField {
  final String? originalValue;
  final String newValue;
  final bool wasBlank;
  _EditedField({this.originalValue, required this.newValue, required this.wasBlank});
}

class _PendingContactChanges {
  final List<({String phoneNumber, String phoneType})> newPhones;
  final List<String> deletedPhones;
  final List<({String emailAddress, String emailType})> newEmails;
  final List<String> deletedEmails;
  final String? newLoginPhone;
  final String? newLoginEmail;

  _PendingContactChanges({
    required this.newPhones,
    required this.deletedPhones,
    required this.newEmails,
    required this.deletedEmails,
    this.newLoginPhone,
    this.newLoginEmail,
  });
}

class _SettingsPageState extends State<SettingsPage> {
  ProfileResponse? _profile;
  ReferenceData? _refData;
  bool _loading = true;
  String? _error;
  bool _copied = false;

  // Edit state
  _EditableSection? _editingSection;
  final Map<String, _EditedField> _editedFields = {};
  final Map<String, _EditedField> _pendingChanges = {};
  String? _sectionError;
  String? _editWarning;

  // Contact editing
  final List<({String phoneNumber, String phoneType})> _newPhones = [];
  final Set<String> _deletedPhones = {};
  final List<({String emailAddress, String emailType})> _newEmails = [];
  final Set<String> _deletedEmails = {};
  String _newPhoneNumber = '';
  String _newPhoneType = 'mobile';
  String _newEmailAddress = '';
  String _newEmailType = 'personal';
  String? _phoneError;
  String? _emailError;
  String? _newLoginPhone;
  String? _newLoginEmail;
  _PendingContactChanges? _pendingContactChanges;

  // Submit state
  bool _isSubmitting = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ProfileService().getProfile(),
        ReferenceDataService().getReferenceData(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as ProfileResponse;
        _refData = results[1] as ReferenceData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ---- Editing helpers ----

  void _startEditing(_EditableSection section) {
    if (_editingSection != null && _editingSection != section) {
      final l10n = AppLocalizations.of(context)!;
      final name = _sectionName(l10n, _editingSection!);
      setState(() => _editWarning = l10n.settings_saveOrCancelFirst(name));
      return;
    }
    setState(() {
      _editingSection = section;
      _editedFields.clear();
      _sectionError = null;
      _editWarning = null;
      if (section == _EditableSection.contact && _pendingContactChanges != null) {
        _newPhones.addAll(_pendingContactChanges!.newPhones);
        _deletedPhones.addAll(_pendingContactChanges!.deletedPhones);
        _newEmails.addAll(_pendingContactChanges!.newEmails);
        _deletedEmails.addAll(_pendingContactChanges!.deletedEmails);
        _newLoginPhone = _pendingContactChanges!.newLoginPhone;
        _newLoginEmail = _pendingContactChanges!.newLoginEmail;
        _pendingContactChanges = null;
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingSection = null;
      _editedFields.clear();
      _sectionError = null;
      _newPhones.clear();
      _deletedPhones.clear();
      _newEmails.clear();
      _deletedEmails.clear();
      _newPhoneNumber = '';
      _newPhoneType = 'mobile';
      _newEmailAddress = '';
      _newEmailType = 'personal';
      _phoneError = null;
      _emailError = null;
      _newLoginPhone = null;
      _newLoginEmail = null;
    });
  }

  void _saveSection() {
    final l10n = AppLocalizations.of(context)!;

    // Validate contact section
    if (_editingSection == _EditableSection.contact) {
      final loginPhone = _profile?.contact?.phones.where((p) => p.isPrimaryForLogin).firstOrNull?.phoneNumber;
      if (loginPhone != null && _deletedPhones.contains(loginPhone) && _newLoginPhone == null) {
        setState(() => _sectionError = l10n.settings_mustSelectNewLoginPhone);
        return;
      }
      final loginEmail = _profile?.contact?.emails.where((e) => e.isPrimaryForLogin).firstOrNull?.emailAddress;
      if (loginEmail != null && _deletedEmails.contains(loginEmail) && _newLoginEmail == null) {
        setState(() => _sectionError = l10n.settings_mustSelectNewLoginEmail);
        return;
      }
      final hasChanges = _newPhones.isNotEmpty || _deletedPhones.isNotEmpty ||
          _newEmails.isNotEmpty || _deletedEmails.isNotEmpty ||
          _newLoginPhone != null || _newLoginEmail != null;
      if (hasChanges) {
        _pendingContactChanges = _PendingContactChanges(
          newPhones: List.from(_newPhones),
          deletedPhones: _deletedPhones.toList(),
          newEmails: List.from(_newEmails),
          deletedEmails: _deletedEmails.toList(),
          newLoginPhone: _newLoginPhone,
          newLoginEmail: _newLoginEmail,
        );
      }
      _newPhones.clear();
      _deletedPhones.clear();
      _newEmails.clear();
      _deletedEmails.clear();
      _phoneError = null;
      _emailError = null;
      _newLoginPhone = null;
      _newLoginEmail = null;
    }

    // Save field edits to pending
    final actual = <String, _EditedField>{};
    for (final entry in _editedFields.entries) {
      final original = entry.value.originalValue ?? '';
      if (entry.value.newValue != original) {
        actual[entry.key] = entry.value;
      }
    }
    if (actual.isNotEmpty) {
      _pendingChanges.addAll(actual);
    }

    setState(() {
      _editingSection = null;
      _editedFields.clear();
      _sectionError = null;
    });
  }

  void _handleFieldChange(String key, String newValue, String? originalValue) {
    setState(() {
      _editedFields[key] = _EditedField(
        originalValue: originalValue,
        newValue: newValue,
        wasBlank: originalValue == null || originalValue.trim().isEmpty,
      );
      _sectionError = null;
    });
  }

  String _getEditedValue(String key, String? originalValue) {
    if (_editedFields.containsKey(key)) return _editedFields[key]!.newValue;
    if (_pendingChanges.containsKey(key)) return _pendingChanges[key]!.newValue;
    return originalValue ?? '';
  }

  String? _getDisplayValue(String key, String? originalValue) {
    if (_pendingChanges.containsKey(key)) return _pendingChanges[key]!.newValue;
    return originalValue;
  }

  bool _hasPendingChanges() => _pendingChanges.isNotEmpty || _pendingContactChanges != null;

  String _sectionName(AppLocalizations l10n, _EditableSection s) => switch (s) {
    _EditableSection.personal => l10n.settings_personalSection,
    _EditableSection.documents => l10n.settings_documentsSection,
    _EditableSection.contact => l10n.settings_contactSection,
    _EditableSection.address => l10n.settings_addressSection,
  };

  // ---- Phone/Email helpers ----

  bool _validatePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+[1-9]\d{0,2}\d{6,14}$').hasMatch(clean);
  }

  bool _validateEmail(String email) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

  void _addPhone() {
    final l10n = AppLocalizations.of(context)!;
    final clean = _newPhoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.isEmpty) { setState(() => _phoneError = l10n.settings_phoneRequired); return; }
    if (!_validatePhone(clean)) { setState(() => _phoneError = l10n.settings_phoneInvalidFormat); return; }
    final existing = _profile?.contact?.phones ?? [];
    if (existing.any((p) => p.phoneNumber == clean) || _newPhones.any((p) => p.phoneNumber == clean)) {
      setState(() => _phoneError = l10n.settings_phoneDuplicate); return;
    }
    setState(() {
      _newPhones.add((phoneNumber: clean, phoneType: _newPhoneType));
      _newPhoneNumber = '';
      _newPhoneType = 'mobile';
      _phoneError = null;
    });
  }

  void _addEmail() {
    final l10n = AppLocalizations.of(context)!;
    final email = _newEmailAddress.trim().toLowerCase();
    if (email.isEmpty) { setState(() => _emailError = l10n.settings_emailRequired); return; }
    if (!_validateEmail(email)) { setState(() => _emailError = l10n.settings_emailInvalidFormat); return; }
    final existing = _profile?.contact?.emails ?? [];
    if (existing.any((e) => e.emailAddress == email) || _newEmails.any((e) => e.emailAddress == email)) {
      setState(() => _emailError = l10n.settings_emailDuplicate); return;
    }
    setState(() {
      _newEmails.add((emailAddress: email, emailType: _newEmailType));
      _newEmailAddress = '';
      _newEmailType = 'personal';
      _emailError = null;
    });
  }

  // ---- Submit ----

  void _handleSubmit() {
    if (!_hasPendingChanges()) return;
    setState(() => _isSubmitting = true);

    final blanks = <String>[];
    final changes = <String>[];
    for (final entry in _pendingChanges.entries) {
      if (entry.value.wasBlank) {
        blanks.add('- ${entry.key}: "${entry.value.newValue}"');
      } else {
        changes.add('- ${entry.key}: "${entry.value.originalValue}" -> "${entry.value.newValue}"');
      }
    }

    final loginEmail = _profile?.contact?.emails.where((e) => e.isPrimaryForLogin).firstOrNull?.emailAddress ??
        _profile?.contact?.emails.firstOrNull?.emailAddress ?? 'Unknown';
    final userName = _getDisplayValue('Full Name', _profile?.personal?.fullName) ?? 'Unknown';

    final buf = StringBuffer('Profile Update Request\n\nUser: $userName\nEmail: $loginEmail\n\n');
    if (blanks.isNotEmpty) buf.writeln('New data to be added:\n${blanks.join('\n')}\n');
    if (changes.isNotEmpty) buf.writeln('Data changes requested:\n${changes.join('\n')}\n');

    if (_pendingContactChanges != null) {
      final pc = _pendingContactChanges!;
      if (pc.newPhones.isNotEmpty) {
        buf.writeln('New phones to add:');
        for (final p in pc.newPhones) { buf.writeln('- ${p.phoneNumber} (${p.phoneType})'); }
        buf.writeln();
      }
      if (pc.deletedPhones.isNotEmpty) {
        buf.writeln('Phones to remove:');
        for (final p in pc.deletedPhones) { buf.writeln('- $p'); }
        buf.writeln();
      }
      if (pc.newEmails.isNotEmpty) {
        buf.writeln('New emails to add:');
        for (final e in pc.newEmails) { buf.writeln('- ${e.emailAddress} (${e.emailType})'); }
        buf.writeln();
      }
      if (pc.deletedEmails.isNotEmpty) {
        buf.writeln('Emails to remove:');
        for (final e in pc.deletedEmails) { buf.writeln('- $e'); }
        buf.writeln();
      }
      if (pc.newLoginPhone != null) buf.writeln('Change login phone to: ${pc.newLoginPhone}\n');
      if (pc.newLoginEmail != null) buf.writeln('Change login email to: ${pc.newLoginEmail}\n');
    }
    buf.write('Please review and update the user\'s profile accordingly.');

    final subject = Uri.encodeComponent('Profile Update Request - $userName');
    final body = Uri.encodeComponent(buf.toString());
    web.window.location.href = 'mailto:mtpsv.psav@gmail.com?subject=$subject&body=$body';

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _pendingChanges.clear();
        _pendingContactChanges = null;
      });
    });
  }

  String _formatCPF(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return cpf;
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _phoneTypeLabel(AppLocalizations l10n, String code) => switch (code) {
    'mobile' => l10n.settings_mobile,
    'home' => l10n.settings_home,
    'work' => l10n.settings_work,
    'voip' => l10n.settings_voip,
    _ => l10n.settings_other,
  };

  String _emailTypeLabel(AppLocalizations l10n, String code) => switch (code) {
    'personal' => l10n.settings_personal,
    'work' => l10n.settings_work,
    _ => l10n.settings_other,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const NavbarSection(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _buildContent(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.red500),
            const SizedBox(height: 12),
            Text('Failed to load profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red600)),
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => viewNotifier.value = AppView.dashboard,
                          child: Row(
                            children: [
                              const Icon(Icons.chevron_left, size: 20, color: AppColors.gray600),
                              const SizedBox(width: 4),
                              Text(l10n.settings_back, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray600)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(l10n.settings_title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.gray900)),
                      const Spacer(),
                      const SizedBox(width: 80),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_editingSection != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.blue200),
                      ),
                      child: Text(l10n.settings_editModeHint, style: const TextStyle(fontSize: 13, color: AppColors.blue600)),
                    ),
                  _buildPersonalSection(l10n),
                  const SizedBox(height: 16),
                  _buildDocumentsSection(l10n),
                  const SizedBox(height: 16),
                  _buildContactSection(l10n),
                  const SizedBox(height: 16),
                  _buildAddressSection(l10n),
                  const SizedBox(height: 16),
                  _buildBlockchainSection(l10n),
                  const SizedBox(height: 16),
                  if (_profile?.accounts?.brazil != null || _profile?.accounts?.usa != null) ...[
                    _buildBankAccountsSection(l10n),
                    const SizedBox(height: 16),
                  ],
                  if (_hasPendingChanges()) _buildPendingSubmit(l10n),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        // Warning modal
        if (_editWarning != null) _buildWarningModal(l10n),
        // Success modal
        if (_showSuccess) _buildSuccessModal(l10n),
      ],
    );
  }

  // ---- Section header ----

  Widget _sectionHeader(String title, _EditableSection section) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900))),
        if (_editingSection == section) ...[
          _iconBtn(Icons.close, AppColors.gray500, () => _cancelEditing(), l10n.settings_cancelEdit),
          const SizedBox(width: 4),
          _iconBtn(Icons.check, AppColors.green600, () => _saveSection(), 'Save'),
        ] else
          _iconBtn(Icons.edit_outlined, _editingSection != null ? AppColors.gray300 : AppColors.gray400, () => _startEditing(section), l10n.settings_edit),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(message: tooltip, child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        )),
      ),
    );
  }

  // ---- Card wrapper ----

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  // ---- Field row ----

  Widget _fieldRow(String label, String fieldKey, String? currentValue, _EditableSection section, {String? placeholder}) {
    final display = _getDisplayValue(fieldKey, currentValue);
    final isEditing = _editingSection == section;
    final isChanged = _pendingChanges.containsKey(fieldKey);
    final isBlank = currentValue == null || currentValue.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500))),
          Expanded(
            flex: 3,
            child: isEditing
                ? TextField(
                    controller: TextEditingController(text: _getEditedValue(fieldKey, currentValue))
                      ..selection = TextSelection.collapsed(offset: _getEditedValue(fieldKey, currentValue).length),
                    onChanged: (v) => _handleFieldChange(fieldKey, v, currentValue),
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: placeholder,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isBlank ? AppColors.blue300 : AppColors.gray300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isBlank ? AppColors.blue300 : AppColors.gray300)),
                      filled: true,
                      fillColor: isBlank ? AppColors.blue50 : Colors.white,
                    ),
                  )
                : Text(
                    display ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: (display == null || display.isEmpty) ? AppColors.gray400 : (isChanged ? AppColors.blue600 : AppColors.gray900),
                      fontWeight: isChanged ? FontWeight.w500 : FontWeight.normal,
                      fontStyle: (display == null || display.isEmpty) ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500))),
          Expanded(
            flex: 3,
            child: Text(
              value ?? '',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: (value == null || value.isEmpty) ? AppColors.gray400 : AppColors.gray900,
                fontStyle: (value == null || value.isEmpty) ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Personal Section ----

  Widget _buildPersonalSection(AppLocalizations l10n) {
    return _card(children: [
      _sectionHeader(l10n.settings_personalSection, _EditableSection.personal),
      if (_sectionError != null && _editingSection == _EditableSection.personal)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
            child: Text(_sectionError!, style: const TextStyle(fontSize: 13, color: AppColors.red600)),
          ),
        ),
      const SizedBox(height: 8),
      _fieldRow(l10n.settings_fullName, 'Full Name', _profile?.personal?.fullName, _EditableSection.personal),
      _buildDateRow(l10n.settings_dateOfBirth, 'Date of Birth', _profile?.personal?.dateOfBirth, _EditableSection.personal),
      _fieldRow(l10n.settings_birthCity, 'Birth City', _profile?.personal?.birthCity, _EditableSection.personal),
      _buildCountryRow(l10n.settings_birthCountry, 'Birth Country', _profile?.personal?.birthCountry, _EditableSection.personal),
    ]);
  }

  Widget _buildDateRow(String label, String fieldKey, String? currentValue, _EditableSection section) {
    final display = _getDisplayValue(fieldKey, currentValue);
    final isEditing = _editingSection == section;
    final isChanged = _pendingChanges.containsKey(fieldKey);
    final isBlank = currentValue == null || currentValue.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500))),
          Expanded(
            flex: 3,
            child: isEditing
                ? Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 180,
                      child: TextField(
                        controller: TextEditingController(text: _getEditedValue(fieldKey, currentValue)),
                        onChanged: (v) => _handleFieldChange(fieldKey, v, currentValue),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isBlank ? AppColors.blue300 : AppColors.gray300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isBlank ? AppColors.blue300 : AppColors.gray300)),
                          filled: true,
                          fillColor: isBlank ? AppColors.blue50 : Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    display ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: (display == null || display.isEmpty) ? AppColors.gray400 : (isChanged ? AppColors.blue600 : AppColors.gray900),
                      fontWeight: isChanged ? FontWeight.w500 : FontWeight.normal,
                      fontStyle: (display == null || display.isEmpty) ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRow(String label, String fieldKey, String? currentValue, _EditableSection section) {
    final display = _getDisplayValue(fieldKey, currentValue);
    final isEditing = _editingSection == section;
    final isChanged = _pendingChanges.containsKey(fieldKey);
    final isBlank = currentValue == null || currentValue.trim().isEmpty;
    final countries = _refData?.countries ?? [];

    String? countryName;
    if (display != null && display.isNotEmpty) {
      final match = countries.where((c) => c.isoCode == display).firstOrNull;
      countryName = match != null ? match.name : display;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500))),
          Expanded(
            flex: 3,
            child: isEditing
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: isBlank ? AppColors.blue300 : AppColors.gray300),
                        borderRadius: BorderRadius.circular(8),
                        color: isBlank ? AppColors.blue50 : Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _getEditedValue(fieldKey, currentValue).isEmpty ? null : _getEditedValue(fieldKey, currentValue),
                          isDense: true,
                          hint: const Text('--', style: TextStyle(fontSize: 13)),
                          style: const TextStyle(fontSize: 13, color: AppColors.gray900),
                          onChanged: (v) => _handleFieldChange(fieldKey, v ?? '', currentValue),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('--')),
                            ...countries.map((c) => DropdownMenuItem(value: c.isoCode, child: Text('${c.isoCode} - ${c.name}', style: const TextStyle(fontSize: 13)))),
                          ],
                        ),
                      ),
                    ),
                  )
                : Text(
                    countryName ?? '',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: (countryName == null || countryName.isEmpty) ? AppColors.gray400 : (isChanged ? AppColors.blue600 : AppColors.gray900),
                      fontWeight: isChanged ? FontWeight.w500 : FontWeight.normal,
                      fontStyle: (countryName == null || countryName.isEmpty) ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---- Documents Section ----

  Widget _buildDocumentsSection(AppLocalizations l10n) {
    final br = _profile?.documents?.brazil;
    final us = _profile?.documents?.usa;
    return _card(children: [
      _sectionHeader(l10n.settings_documentsSection, _EditableSection.documents),
      if (_sectionError != null && _editingSection == _EditableSection.documents)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
            child: Text(_sectionError!, style: const TextStyle(fontSize: 13, color: AppColors.red600)),
          ),
        ),
      const SizedBox(height: 8),
      if (br != null || _editingSection == _EditableSection.documents) ...[
        Row(children: [const Text('\u{1F1E7}\u{1F1F7}', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(l10n.settings_brazilDocs, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700))]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(children: [
            _readOnlyRow(l10n.settings_cpf, br?.cpf != null ? _formatCPF(br!.cpf) : null),
            _fieldRow(l10n.settings_rg, 'RG', br?.rgNumber, _EditableSection.documents),
            _fieldRow(l10n.settings_rgIssuer, 'RG Issuer', br?.rgIssuer, _EditableSection.documents, placeholder: 'SSP/SP'),
            _buildDateRow(l10n.settings_rgIssuedAt, 'RG Issue Date', br?.rgIssuedAt, _EditableSection.documents),
          ]),
        ),
        const Divider(height: 24, color: AppColors.gray100),
      ],
      if (us != null || _editingSection == _EditableSection.documents) ...[
        Row(children: [const Text('\u{1F1FA}\u{1F1F8}', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(l10n.settings_usaDocs, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700))]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(children: [
            _fieldRow(l10n.settings_ssnLast4, 'SSN Last 4', us?.ssnLast4, _EditableSection.documents, placeholder: '0000'),
            _fieldRow(l10n.settings_driversLicense, 'Drivers License', us?.driversLicenseNumber, _EditableSection.documents),
          ]),
        ),
      ],
      if (br == null && us == null && _editingSection != _EditableSection.documents)
        Text(l10n.settings_notDefined, style: const TextStyle(fontSize: 13, color: AppColors.gray400, fontStyle: FontStyle.italic)),
    ]);
  }

  // ---- Contact Section ----

  Widget _buildContactSection(AppLocalizations l10n) {
    final phones = _profile?.contact?.phones ?? [];
    final emails = _profile?.contact?.emails ?? [];
    final isEditing = _editingSection == _EditableSection.contact;
    final phoneTypes = _refData?.phoneTypes ?? [];
    final emailTypes = _refData?.emailTypes ?? [];

    return _card(children: [
      _sectionHeader(l10n.settings_contactSection, _EditableSection.contact),
      if (_sectionError != null && isEditing)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
            child: Text(_sectionError!, style: const TextStyle(fontSize: 13, color: AppColors.red600)),
          ),
        ),
      const SizedBox(height: 8),
      // Phones
      Text(l10n.settings_phones, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500)),
      const SizedBox(height: 6),
      ...phones.map((p) => _buildPhoneRow(l10n, p, isEditing)),
      ..._newPhones.map((p) => _buildNewPhoneRow(l10n, p, isEditing)),
      if (!isEditing && _pendingContactChanges != null)
        ..._pendingContactChanges!.newPhones.map((p) => _pendingItemRow(p.phoneNumber, p.phoneType, l10n.settings_new)),
      if (isEditing) _buildAddPhoneForm(l10n, phoneTypes),
      const SizedBox(height: 16),
      // Emails
      Text(l10n.settings_emails, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500)),
      const SizedBox(height: 6),
      ...emails.map((e) => _buildEmailRow(l10n, e, isEditing)),
      ..._newEmails.map((e) => _buildNewEmailRow(l10n, e, isEditing)),
      if (!isEditing && _pendingContactChanges != null)
        ..._pendingContactChanges!.newEmails.map((e) => _pendingItemRow(e.emailAddress, e.emailType, l10n.settings_new)),
      if (isEditing) _buildAddEmailForm(l10n, emailTypes),
    ]);
  }

  Widget _buildPhoneRow(AppLocalizations l10n, PhoneInfo phone, bool isEditing) {
    final isDeleted = _deletedPhones.contains(phone.phoneNumber);
    final isPendingDelete = _pendingContactChanges?.deletedPhones.contains(phone.phoneNumber) ?? false;
    final isLogin = phone.isPrimaryForLogin;
    final isNewLogin = _newLoginPhone == phone.phoneNumber;
    final isPendingNewLogin = _pendingContactChanges?.newLoginPhone == phone.phoneNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(children: [
              Text(
                phone.phoneNumber,
                style: TextStyle(
                  fontSize: 13,
                  color: isDeleted || isPendingDelete ? AppColors.red500 : (isNewLogin || isPendingNewLogin == true) ? AppColors.green600 : AppColors.gray900,
                  decoration: isDeleted || isPendingDelete ? TextDecoration.lineThrough : null,
                  fontWeight: (isNewLogin || isPendingNewLogin == true) ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (phone.phoneType != null) ...[
                const SizedBox(width: 6),
                Text('(${_phoneTypeLabel(l10n, phone.phoneType!)})', style: TextStyle(fontSize: 11, color: isDeleted || isPendingDelete ? AppColors.red400 : AppColors.gray400)),
              ],
              if ((isNewLogin || isPendingNewLogin == true) && !isLogin) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(4)), child: Text(l10n.settings_newLogin, style: const TextStyle(fontSize: 10, color: AppColors.green600))),
              ],
            ]),
          ),
          if (isLogin && !isNewLogin && _newLoginPhone == null)
            const Tooltip(message: 'Login credential', child: Icon(Icons.vpn_key, size: 16, color: AppColors.blue500)),
          if (isEditing && !isDeleted) ...[
            if (!isLogin)
              _iconBtn(Icons.vpn_key, isNewLogin ? AppColors.green600 : AppColors.gray400, () => setState(() => _newLoginPhone = isNewLogin ? null : phone.phoneNumber), isNewLogin ? l10n.settings_cancelSetLogin : l10n.settings_setAsLogin),
            _iconBtn(Icons.delete_outline, AppColors.red400, () => setState(() {
              if (_deletedPhones.contains(phone.phoneNumber)) { _deletedPhones.remove(phone.phoneNumber); } else { _deletedPhones.add(phone.phoneNumber); }
            }), l10n.settings_delete),
          ],
          if (isEditing && isDeleted)
            _iconBtn(Icons.undo, AppColors.green600, () => setState(() => _deletedPhones.remove(phone.phoneNumber)), 'Undo'),
        ],
      ),
    );
  }

  Widget _buildNewPhoneRow(AppLocalizations l10n, ({String phoneNumber, String phoneType}) phone, bool isEditing) {
    final isNewLogin = _newLoginPhone == phone.phoneNumber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(children: [
              Text(phone.phoneNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isNewLogin ? AppColors.green600 : AppColors.blue600)),
              const SizedBox(width: 6),
              Text('(${_phoneTypeLabel(l10n, phone.phoneType)})', style: TextStyle(fontSize: 11, color: isNewLogin ? const Color(0xFF86EFAC) : AppColors.blue400)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isNewLogin ? AppColors.green100 : AppColors.blue100, borderRadius: BorderRadius.circular(4)),
                child: Text(isNewLogin ? l10n.settings_newLogin : l10n.settings_new, style: TextStyle(fontSize: 10, color: isNewLogin ? AppColors.green600 : AppColors.blue600)),
              ),
            ]),
          ),
          if (isEditing) ...[
            _iconBtn(Icons.vpn_key, isNewLogin ? AppColors.green600 : AppColors.gray400, () => setState(() => _newLoginPhone = isNewLogin ? null : phone.phoneNumber), isNewLogin ? l10n.settings_cancelSetLogin : l10n.settings_setAsLogin),
            _iconBtn(Icons.close, AppColors.red400, () => setState(() => _newPhones.remove(phone)), 'Remove'),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailRow(AppLocalizations l10n, EmailInfo email, bool isEditing) {
    final isDeleted = _deletedEmails.contains(email.emailAddress);
    final isPendingDelete = _pendingContactChanges?.deletedEmails.contains(email.emailAddress) ?? false;
    final isLogin = email.isPrimaryForLogin;
    final isNewLogin = _newLoginEmail == email.emailAddress;
    final isPendingNewLogin = _pendingContactChanges?.newLoginEmail == email.emailAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(
                  email.emailAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDeleted || isPendingDelete ? AppColors.red500 : (isNewLogin || isPendingNewLogin == true) ? AppColors.green600 : AppColors.gray900,
                    decoration: isDeleted || isPendingDelete ? TextDecoration.lineThrough : null,
                    fontWeight: (isNewLogin || isPendingNewLogin == true) ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (email.emailType != null) ...[
                const SizedBox(width: 6),
                Text('(${_emailTypeLabel(l10n, email.emailType!)})', style: TextStyle(fontSize: 11, color: isDeleted || isPendingDelete ? AppColors.red400 : AppColors.gray400)),
              ],
              if ((isNewLogin || isPendingNewLogin == true) && !isLogin) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(4)), child: Text(l10n.settings_newLogin, style: const TextStyle(fontSize: 10, color: AppColors.green600))),
              ],
            ]),
          ),
          if (isLogin && !isNewLogin && _newLoginEmail == null)
            const Tooltip(message: 'Login credential', child: Icon(Icons.vpn_key, size: 16, color: AppColors.blue500)),
          if (isEditing && !isDeleted) ...[
            if (!isLogin)
              _iconBtn(Icons.vpn_key, isNewLogin ? AppColors.green600 : AppColors.gray400, () => setState(() => _newLoginEmail = isNewLogin ? null : email.emailAddress), isNewLogin ? l10n.settings_cancelSetLogin : l10n.settings_setAsLogin),
            _iconBtn(Icons.delete_outline, AppColors.red400, () => setState(() {
              if (_deletedEmails.contains(email.emailAddress)) { _deletedEmails.remove(email.emailAddress); } else { _deletedEmails.add(email.emailAddress); }
            }), l10n.settings_delete),
          ],
          if (isEditing && isDeleted)
            _iconBtn(Icons.undo, AppColors.green600, () => setState(() => _deletedEmails.remove(email.emailAddress)), 'Undo'),
        ],
      ),
    );
  }

  Widget _buildNewEmailRow(AppLocalizations l10n, ({String emailAddress, String emailType}) email, bool isEditing) {
    final isNewLogin = _newLoginEmail == email.emailAddress;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(children: [
              Flexible(child: Text(email.emailAddress, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isNewLogin ? AppColors.green600 : AppColors.blue600))),
              const SizedBox(width: 6),
              Text('(${_emailTypeLabel(l10n, email.emailType)})', style: TextStyle(fontSize: 11, color: isNewLogin ? const Color(0xFF86EFAC) : AppColors.blue400)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isNewLogin ? AppColors.green100 : AppColors.blue100, borderRadius: BorderRadius.circular(4)),
                child: Text(isNewLogin ? l10n.settings_newLogin : l10n.settings_new, style: TextStyle(fontSize: 10, color: isNewLogin ? AppColors.green600 : AppColors.blue600)),
              ),
            ]),
          ),
          if (isEditing) ...[
            _iconBtn(Icons.vpn_key, isNewLogin ? AppColors.green600 : AppColors.gray400, () => setState(() => _newLoginEmail = isNewLogin ? null : email.emailAddress), isNewLogin ? l10n.settings_cancelSetLogin : l10n.settings_setAsLogin),
            _iconBtn(Icons.close, AppColors.red400, () => setState(() => _newEmails.remove(email)), 'Remove'),
          ],
        ],
      ),
    );
  }

  Widget _pendingItemRow(String value, String type, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.blue600)),
        const SizedBox(width: 6),
        Text('($type)', style: const TextStyle(fontSize: 11, color: AppColors.blue400)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(4)),
          child: Text(badge, style: const TextStyle(fontSize: 10, color: AppColors.blue600)),
        ),
      ]),
    );
  }

  Widget _buildAddPhoneForm(AppLocalizations l10n, List<PhoneType> phoneTypes) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => _newPhoneNumber = v,
                controller: TextEditingController(text: _newPhoneNumber),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: '+5511999999999',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  filled: true, fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.gray300), borderRadius: BorderRadius.circular(8), color: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _newPhoneType,
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                  onChanged: (v) => setState(() => _newPhoneType = v!),
                  items: phoneTypes.map((pt) => DropdownMenuItem(value: pt.code, child: Text(_phoneTypeLabel(l10n, pt.code)))).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _addPhone,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.settings_add, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
          if (_phoneError != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(_phoneError!, style: const TextStyle(fontSize: 11, color: AppColors.red500))),
        ],
      ),
    );
  }

  Widget _buildAddEmailForm(AppLocalizations l10n, List<EmailType> emailTypes) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => _newEmailAddress = v,
                controller: TextEditingController(text: _newEmailAddress),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'email@example.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)),
                  filled: true, fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.gray300), borderRadius: BorderRadius.circular(8), color: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _newEmailType,
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                  onChanged: (v) => setState(() => _newEmailType = v!),
                  items: emailTypes.map((et) => DropdownMenuItem(value: et.code, child: Text(_emailTypeLabel(l10n, et.code)))).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _addEmail,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.settings_add, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
          if (_emailError != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(_emailError!, style: const TextStyle(fontSize: 11, color: AppColors.red500))),
        ],
      ),
    );
  }

  // ---- Address Section ----

  Widget _buildAddressSection(AppLocalizations l10n) {
    return _card(children: [
      _sectionHeader(l10n.settings_addressSection, _EditableSection.address),
      if (_sectionError != null && _editingSection == _EditableSection.address)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
            child: Text(_sectionError!, style: const TextStyle(fontSize: 13, color: AppColors.red600)),
          ),
        ),
      const SizedBox(height: 8),
      _fieldRow(l10n.settings_addressLine1, 'Address Line 1', _profile?.address?.line1, _EditableSection.address),
      _fieldRow(l10n.settings_addressLine2, 'Address Line 2', _profile?.address?.line2, _EditableSection.address),
      _fieldRow(l10n.settings_city, 'City', _profile?.address?.city, _EditableSection.address),
      _fieldRow(l10n.settings_state, 'State', _profile?.address?.state, _EditableSection.address),
      _fieldRow(l10n.settings_postalCode, 'Postal Code', _profile?.address?.postalCode, _EditableSection.address),
      _buildCountryRow(l10n.settings_country, 'Address Country', _profile?.address?.country, _EditableSection.address),
    ]);
  }

  // ---- Blockchain Section ----

  Widget _buildBlockchainSection(AppLocalizations l10n) {
    final addr = _profile?.blockchain?.polygonAddress;
    return _card(children: [
      Text(l10n.settings_blockchainSection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900)),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(l10n.settings_polygonAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500))),
            Expanded(
              flex: 3,
              child: addr != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(child: SelectableText(addr, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.gray900), textAlign: TextAlign.end)),
                        const SizedBox(width: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _copyToClipboard(addr),
                            child: Tooltip(
                              message: _copied ? l10n.settings_copied : l10n.settings_copyAddress,
                              child: Icon(_copied ? Icons.check : Icons.copy, size: 16, color: _copied ? AppColors.green600 : AppColors.gray400),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(l10n.settings_notDefined, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, color: AppColors.gray400, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    ]);
  }

  // ---- Bank Accounts Section ----

  Widget _buildBankAccountsSection(AppLocalizations l10n) {
    final br = _profile?.accounts?.brazil;
    final us = _profile?.accounts?.usa;
    return _card(children: [
      Text(l10n.settings_bankAccountsSection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray900)),
      const SizedBox(height: 12),
      if (br != null) ...[
        Row(children: [const Text('\u{1F1E7}\u{1F1F7}', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(l10n.settings_brazilBank, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700))]),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: Column(children: [
          if (br.bankCode != null) _readOnlyRow(l10n.settings_bankCode, br.bankCode),
          if (br.branchNumber != null) _readOnlyRow(l10n.settings_branch, br.branchNumber),
          if (br.accountNumber != null) _readOnlyRow(l10n.settings_accountNumber, br.accountNumber),
        ])),
        if (us != null) const Divider(height: 24, color: AppColors.gray100),
      ],
      if (us != null) ...[
        Row(children: [const Text('\u{1F1FA}\u{1F1F8}', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text(l10n.settings_usaBank, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700))]),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: Column(children: [
          _readOnlyRow(l10n.settings_routingNumber, us.routingNumber),
          _readOnlyRow(l10n.settings_accountNumber, us.accountNumber),
        ])),
      ],
    ]);
  }

  // ---- Pending changes + Submit ----

  Widget _buildPendingSubmit(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings_pendingChanges, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
              const SizedBox(height: 8),
              for (final entry in _pendingChanges.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('${entry.key}: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1D4ED8))),
                      Expanded(
                        child: Text(
                          entry.value.wasBlank ? '"${entry.value.newValue}"' : '"${entry.value.originalValue}" \u2192 "${entry.value.newValue}"',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8)),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_pendingContactChanges != null) ...[
                for (final p in _pendingContactChanges!.newPhones)
                  _pendingSummaryRow('${l10n.settings_phones} (${l10n.settings_new})', '${p.phoneNumber} (${p.phoneType})', AppColors.blue600),
                for (final p in _pendingContactChanges!.deletedPhones)
                  _pendingSummaryRow('${l10n.settings_phones} (${l10n.settings_delete})', p, AppColors.red600, strikeThrough: true),
                for (final e in _pendingContactChanges!.newEmails)
                  _pendingSummaryRow('${l10n.settings_emails} (${l10n.settings_new})', '${e.emailAddress} (${e.emailType})', AppColors.blue600),
                for (final e in _pendingContactChanges!.deletedEmails)
                  _pendingSummaryRow('${l10n.settings_emails} (${l10n.settings_delete})', e, AppColors.red600, strikeThrough: true),
                if (_pendingContactChanges!.newLoginPhone != null)
                  _pendingSummaryRow(l10n.settings_newLoginPhone, _pendingContactChanges!.newLoginPhone!, AppColors.green600),
                if (_pendingContactChanges!.newLoginEmail != null)
                  _pendingSummaryRow(l10n.settings_newLoginEmail, _pendingContactChanges!.newLoginEmail!, AppColors.green600),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isSubmitting ? null : _handleSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isSubmitting ? AppColors.gray200 : AppColors.blue600,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                _isSubmitting ? l10n.settings_submittingChanges : l10n.settings_submitForApproval,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _isSubmitting ? AppColors.gray400 : Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingSummaryRow(String label, String value, Color color, {bool strikeThrough = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: color, decoration: strikeThrough ? TextDecoration.lineThrough : null), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  // ---- Modals ----

  Widget _buildWarningModal(AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.amber600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_editWarning!, style: const TextStyle(fontSize: 14, color: AppColors.gray700))),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _editWarning = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.amber500, borderRadius: BorderRadius.circular(100)),
                        alignment: Alignment.center,
                        child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessModal(AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: AppColors.green600, size: 32),
                ),
                const SizedBox(height: 16),
                Text(l10n.settings_changesSubmitted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.gray900)),
                const SizedBox(height: 8),
                Text(l10n.settings_changesSubmittedDesc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                const SizedBox(height: 24),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _showSuccess = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(100)),
                      child: const Text('OK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
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
