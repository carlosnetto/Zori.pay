import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/services/auth_service.dart';

void showAuthModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => const _AuthModalOverlay(),
  );
}

class _AuthModalOverlay extends StatefulWidget {
  const _AuthModalOverlay();

  @override
  State<_AuthModalOverlay> createState() => _AuthModalOverlayState();
}

class _AuthModalOverlayState extends State<_AuthModalOverlay> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().initiateGoogleLogin();
      // Browser will redirect — no further action needed
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to initiate login. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(Icons.close, size: 24, color: AppColors.gray500),
                      ),
                    ),
                  ),
                ),
                // Z Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  l10n.auth_loginTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  l10n.auth_loginDesc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Error message
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 13, color: AppColors.red500),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Google Sign-In button
                _GoogleButton(
                  label: _loading ? 'Redirecting...' : l10n.auth_googleBtn,
                  loading: _loading,
                  onTap: _loading ? null : _handleGoogleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GoogleButton({required this.label, this.loading = false, required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.loading
                ? AppColors.gray100
                : (_hovering ? AppColors.gray50 : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gray500),
                )
              else
                const Icon(Icons.login, size: 24, color: AppColors.gray700),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
