import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/sections/navbar_section.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/services/api_client.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _submitted = false;
  bool _loading = false;
  String? _submitError;
  String? _polygonAddress;

  final _fullNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _cpfError;
  String? _emailError;

  // File data from real picker
  _PickedFile? _cnhPdf;
  _PickedFile? _cnhFront;
  _PickedFile? _cnhBack;
  _PickedFile? _selfie;
  _PickedFile? _proofAddr;

  @override
  void dispose() {
    _fullNameController.dispose();
    _motherNameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // CPF formatting: 000.000.000-00
  String _formatCPF(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(limited[i]);
    }
    return buf.toString();
  }

  String _getDigitsOnly(String cpf) => cpf.replaceAll(RegExp(r'[^\d]'), '');

  // CPF checksum validation
  bool _validateCPF(String cpf) {
    final digits = _getDigitsOnly(cpf);
    if (digits.length != 11) return false;

    // Check for all same digits
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    // First check digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int remainder = (sum * 10) % 11;
    if (remainder == 10) remainder = 0;
    if (remainder != int.parse(digits[9])) return false;

    // Second check digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder == 10) remainder = 0;
    if (remainder != int.parse(digits[10])) return false;

    return true;
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void _handleCpfChanged(String value) {
    final formatted = _formatCPF(value);
    if (formatted != _cpfController.text) {
      _cpfController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_cpfError != null) setState(() => _cpfError = null);
  }

  void _handleCpfBlur() {
    final l10n = AppLocalizations.of(context)!;
    final digits = _getDigitsOnly(_cpfController.text);
    if (digits.isNotEmpty && digits.length < 11) {
      setState(() => _cpfError = l10n.kyc_cpfErrorIncomplete);
    } else if (digits.length == 11 && !_validateCPF(_cpfController.text)) {
      setState(() => _cpfError = l10n.kyc_cpfErrorInvalid);
    }
  }

  void _handleEmailBlur() {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isNotEmpty && !_validateEmail(_emailController.text)) {
      setState(() => _emailError = l10n.kyc_emailError);
    }
  }

  Future<_PickedFile?> _pickFile(String accept) async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = accept;
    input.click();

    // Wait for file selection
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.length == 0) return null;

    final file = files.item(0)!;
    final bytes = await _readFileAsBytes(file);
    if (bytes == null) return null;

    return _PickedFile(name: file.name, bytes: bytes);
  }

  Future<Uint8List?> _readFileAsBytes(web.File file) async {
    final reader = web.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    if (reader.readyState != web.FileReader.DONE) return null;
    final result = reader.result;
    if (result == null) return null;
    return (result as JSArrayBuffer).toDart.asUint8List();
  }

  Future<void> _handlePickFile(String field, String accept) async {
    final file = await _pickFile(accept);
    if (file == null) return;
    setState(() {
      switch (field) {
        case 'cnh_pdf':
          _cnhPdf = file;
        case 'cnh_front':
          _cnhFront = file;
        case 'cnh_back':
          _cnhBack = file;
        case 'selfie':
          _selfie = file;
        case 'proof_of_address':
          _proofAddr = file;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate CPF
    if (!_validateCPF(_cpfController.text)) {
      setState(() => _cpfError = l10n.kyc_cpfErrorInvalid);
      return;
    }

    // Validate email
    if (!_validateEmail(_emailController.text)) {
      setState(() => _emailError = l10n.kyc_emailError);
      return;
    }

    setState(() {
      _loading = true;
      _submitError = null;
    });

    try {
      final api = ApiClient();
      final fields = <String, String>{
        'full_name': _fullNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'cpf': _getDigitsOnly(_cpfController.text),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final files = <String, http.MultipartFile>{};
      if (_cnhPdf != null) {
        files['cnh_pdf'] = http.MultipartFile.fromBytes(
          'cnh_pdf', _cnhPdf!.bytes,
          filename: _cnhPdf!.name,
        );
      }
      if (_cnhFront != null) {
        files['cnh_front'] = http.MultipartFile.fromBytes(
          'cnh_front', _cnhFront!.bytes,
          filename: _cnhFront!.name,
        );
      }
      if (_cnhBack != null) {
        files['cnh_back'] = http.MultipartFile.fromBytes(
          'cnh_back', _cnhBack!.bytes,
          filename: _cnhBack!.name,
        );
      }
      if (_selfie != null) {
        files['selfie'] = http.MultipartFile.fromBytes(
          'selfie', _selfie!.bytes,
          filename: _selfie!.name,
        );
      }
      if (_proofAddr != null) {
        files['proof_of_address'] = http.MultipartFile.fromBytes(
          'proof_of_address', _proofAddr!.bytes,
          filename: _proofAddr!.name,
        );
      }

      final response = await api.postMultipart(
        '/kyc/open-account-br',
        fields: fields,
        files: files,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
          _polygonAddress = response['polygon_address'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 64),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                      child: _submitted
                          ? _buildSuccessState(l10n)
                          : _buildForm(l10n),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavbarSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(AppLocalizations l10n) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 448),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.green100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 40, color: AppColors.green600),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.kyc_successTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.kyc_successDesc,
              style: const TextStyle(fontSize: 18, color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            if (_polygonAddress != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Polygon Address',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _polygonAddress!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Note box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue100),
              ),
              child: Text(
                l10n.kyc_successNote,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E40AF), // blue-800
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _SubmitButton(
              label: l10n.kyc_backHome,
              color: AppColors.gray900,
              hoverColor: Colors.black,
              onTap: () => viewNotifier.value = AppView.dashboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          l10n.kyc_title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.kyc_subtitle,
          style: const TextStyle(fontSize: 16, color: AppColors.gray600),
        ),
        const SizedBox(height: 32),

        // Country selector (disabled)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.kyc_country,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Text(
                  '\u{1F1E7}\u{1F1F7}  ${l10n.kyc_brazil}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Full Name
        _FormField(
          label: l10n.kyc_fullName,
          controller: _fullNameController,
        ),
        const SizedBox(height: 16),

        // Mother's Name
        _FormField(
          label: l10n.kyc_motherName,
          controller: _motherNameController,
        ),
        const SizedBox(height: 16),

        // CPF
        _FormField(
          label: l10n.kyc_cpf,
          controller: _cpfController,
          placeholder: '000.000.000-00',
          error: _cpfError,
          onChanged: _handleCpfChanged,
          onBlur: _handleCpfBlur,
        ),
        const SizedBox(height: 16),

        // Email + Phone (side by side on desktop)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormField(
                  label: l10n.kyc_email,
                  controller: _emailController,
                  error: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  onBlur: _handleEmailBlur,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FormField(
                  label: l10n.kyc_phone,
                  controller: _phoneController,
                  placeholder: '+5511999999999',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          )
        else ...[
          _FormField(
            label: l10n.kyc_email,
            controller: _emailController,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            onBlur: _handleEmailBlur,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: l10n.kyc_phone,
            controller: _phoneController,
            placeholder: '+5511999999999',
            keyboardType: TextInputType.phone,
          ),
        ],
        const SizedBox(height: 32),

        // Documents section
        Text(
          l10n.kyc_uploadTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 24),

        // CNH section: PDF OR Front/Back
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _UploadBox(
                    icon: Icons.description_outlined,
                    label: l10n.kyc_idPdf,
                    fileName: _cnhPdf?.name,
                    onTap: () => _handlePickFile('cnh_pdf', '.pdf'),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        l10n.kyc_or,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _UploadBox(
                          icon: Icons.photo_camera_outlined,
                          label: l10n.kyc_idFront,
                          fileName: _cnhFront?.name,
                          compact: true,
                          onTap: () => _handlePickFile('cnh_front', 'image/*'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UploadBox(
                          icon: Icons.photo_camera_outlined,
                          label: l10n.kyc_idBack,
                          fileName: _cnhBack?.name,
                          compact: true,
                          onTap: () => _handlePickFile('cnh_back', 'image/*'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          _UploadBox(
            icon: Icons.description_outlined,
            label: l10n.kyc_idPdf,
            fileName: _cnhPdf?.name,
            onTap: () => _handlePickFile('cnh_pdf', '.pdf'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.kyc_or,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _UploadBox(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.kyc_idFront,
                  fileName: _cnhFront?.name,
                  compact: true,
                  onTap: () => _handlePickFile('cnh_front', 'image/*'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UploadBox(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.kyc_idBack,
                  fileName: _cnhBack?.name,
                  compact: true,
                  onTap: () => _handlePickFile('cnh_back', 'image/*'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),

        // Selfie AND Proof of Address
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _UploadBox(
                    icon: Icons.face_outlined,
                    label: l10n.kyc_selfie,
                    fileName: _selfie?.name,
                    onTap: () => _handlePickFile('selfie', 'image/*'),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        l10n.kyc_and,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _UploadBox(
                    icon: Icons.home_outlined,
                    label: l10n.kyc_proofAddr,
                    fileName: _proofAddr?.name,
                    onTap: () => _handlePickFile('proof_of_address', '.pdf,image/*'),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _UploadBox(
            icon: Icons.face_outlined,
            label: l10n.kyc_selfie,
            fileName: _selfie?.name,
            onTap: () => _handlePickFile('selfie', 'image/*'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.kyc_and,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ),
          _UploadBox(
            icon: Icons.home_outlined,
            label: l10n.kyc_proofAddr,
            fileName: _proofAddr?.name,
            onTap: () => _handlePickFile('proof_of_address', '.pdf,image/*'),
          ),
        ],
        const SizedBox(height: 32),

        // Error message
        if (_submitError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              _submitError!,
              style: const TextStyle(fontSize: 13, color: AppColors.red500),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Submit button
        _SubmitButton(
          label: _loading ? 'Processing...' : l10n.kyc_submit,
          color: AppColors.blue600,
          hoverColor: const Color(0xFF1D4ED8),
          loading: _loading,
          onTap: _loading ? null : _handleSubmit,
        ),
      ],
    );
  }
}

class _PickedFile {
  final String name;
  final Uint8List bytes;
  const _PickedFile({required this.name, required this.bytes});
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBlur;

  const _FormField({
    required this.label,
    required this.controller,
    this.placeholder,
    this.error,
    this.keyboardType,
    this.onChanged,
    this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
            onBlur?.call();
          },
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: AppColors.gray400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? AppColors.red500 : AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? AppColors.red500 : AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.red500 : AppColors.blue600,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error, size: 16, color: AppColors.red500),
              const SizedBox(width: 4),
              Text(
                error!,
                style: const TextStyle(fontSize: 13, color: AppColors.red500),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _UploadBox extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? fileName;
  final bool compact;
  final VoidCallback onTap;

  const _UploadBox({
    required this.icon,
    required this.label,
    required this.fileName,
    this.compact = false,
    required this.onTap,
  });

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.compact ? 12 : 24),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.gray50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.fileName != null ? AppColors.green600 : AppColors.gray200,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.fileName != null ? Icons.check_circle : widget.icon,
                size: widget.compact ? 20 : 32,
                color: widget.fileName != null
                    ? AppColors.green600
                    : (_hovering ? AppColors.blue600 : AppColors.gray400),
              ),
              SizedBox(height: widget.compact ? 4 : 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: _hovering ? AppColors.gray900 : AppColors.gray600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.fileName != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.fileName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.green600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color hoverColor;
  final bool loading;
  final VoidCallback? onTap;

  const _SubmitButton({
    required this.label,
    required this.color,
    required this.hoverColor,
    this.loading = false,
    required this.onTap,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.loading
                ? AppColors.gray400
                : (_hovering ? widget.hoverColor : widget.color),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!widget.loading)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
