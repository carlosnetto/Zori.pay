import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/services/receive_service.dart';

void showReceiveModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => const _ReceiveModalOverlay(),
  );
}

class _ReceiveModalOverlay extends StatefulWidget {
  const _ReceiveModalOverlay();

  @override
  State<_ReceiveModalOverlay> createState() => _ReceiveModalOverlayState();
}

class _ReceiveModalOverlayState extends State<_ReceiveModalOverlay> {
  bool _copied = false;
  bool _loading = true;
  String? _error;
  String _walletAddress = '';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      final response = await ReceiveService().getReceiveAddress();
      if (mounted) {
        setState(() {
          _walletAddress = response.address;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _walletAddress));
    setState(() => _copied = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 24, color: AppColors.gray400),
                      ),
                    ),
                  ),
                ),
                // Title
                const Text(
                  'Receive Funds',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 16),
                // POLYGON badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'POLYGON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppColors.blue600),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: AppColors.red500),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.gray600)),
                      ],
                    ),
                  )
                else ...[
                  // QR Code placeholder
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray100, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 100, color: AppColors.gray900),
                        const SizedBox(height: 8),
                        const Text(
                          'QR Code',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Address with copy
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _handleCopy,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _walletAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _copied ? Icons.check : Icons.copy,
                              size: 20,
                              color: _copied ? AppColors.green600 : AppColors.gray400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_copied) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Address copied!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.green600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Warning
                  const Text(
                    'Only send tokens on the Polygon network to this address',
                    style: TextStyle(fontSize: 12, color: AppColors.gray400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
