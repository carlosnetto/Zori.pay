import 'package:flutter/material.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/services/send_service.dart';

void showSendModal(
  BuildContext context, {
  required String currencyCode,
  required String currencyName,
  required String balance,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => _SendModalOverlay(
      currencyCode: currencyCode,
      currencyName: currencyName,
      balance: balance,
    ),
  );
}

enum _SendStep { input, confirm, sending, success }

class _SendModalOverlay extends StatefulWidget {
  final String currencyCode;
  final String currencyName;
  final String balance;

  const _SendModalOverlay({
    required this.currencyCode,
    required this.currencyName,
    required this.balance,
  });

  @override
  State<_SendModalOverlay> createState() => _SendModalOverlayState();
}

class _SendModalOverlayState extends State<_SendModalOverlay> {
  _SendStep _step = _SendStep.input;
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;
  bool _estimating = false;
  EstimateResponse? _estimate;
  String _txHash = '';

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _truncateAddress(String address) {
    if (address.length < 18) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  Future<void> _handleContinue() async {
    final address = _addressController.text.trim();
    final amount = _amountController.text.trim();

    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
      setState(() => _error = 'Please enter a valid Polygon address (0x...)');
      return;
    }

    final amountNum = double.tryParse(amount);
    if (amountNum == null || amountNum <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    final balanceNum = double.tryParse(widget.balance.replaceAll(',', ''));
    if (balanceNum != null && amountNum > balanceNum) {
      setState(() => _error = 'Insufficient balance');
      return;
    }

    setState(() {
      _error = null;
      _estimating = true;
    });

    try {
      final estimate = await SendService().estimateTransaction(
        toAddress: address,
        amount: amount,
        currencyCode: widget.currencyCode,
      );
      if (mounted) {
        setState(() {
          _estimate = estimate;
          _estimating = false;
          _step = _SendStep.confirm;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimating = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _handleSend() async {
    setState(() => _step = _SendStep.sending);
    try {
      final response = await SendService().sendTransaction(
        toAddress: _addressController.text.trim(),
        amount: _amountController.text.trim(),
        currencyCode: widget.currencyCode,
      );
      if (mounted) {
        setState(() {
          _txHash = response.transactionHash;
          _step = _SendStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = _SendStep.confirm;
          _error = e.toString();
        });
      }
    }
  }

  void _handleSendMax() {
    if (_estimate != null) {
      _amountController.text = _estimate!.maxAmountFormatted;
    } else {
      _amountController.text = widget.balance.replaceAll(',', '');
    }
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
            child: switch (_step) {
              _SendStep.input => _buildInputStep(),
              _SendStep.confirm => _buildConfirmStep(),
              _SendStep.sending => _buildSendingStep(),
              _SendStep.success => _buildSuccessStep(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: _CloseButton(onTap: () => Navigator.pop(context)),
        ),
        Text(
          'Send ${widget.currencyCode}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.gray900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
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
        // Available balance
        const Text(
          'Available balance',
          style: TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
        Text(
          '${widget.balance} ${widget.currencyCode}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 24),
        // Destination address
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Destination address for ${widget.currencyName}',
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '0x...',
            hintStyle: const TextStyle(color: AppColors.gray400),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        // Amount
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            'Amount to send',
            style: TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: AppColors.gray400),
            suffixText: widget.currencyCode,
            suffixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.gray400,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.blue600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _handleSendMax,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Send max',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Error
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
        // Continue button
        _PrimaryButton(
          label: _estimating ? 'Estimating...' : 'Continue',
          loading: _estimating,
          onTap: _estimating ? null : _handleContinue,
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: _CloseButton(onTap: () => Navigator.pop(context)),
        ),
        const Text(
          'Confirm Transaction',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.gray900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Summary box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('You are sending', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
              const SizedBox(height: 4),
              Text(
                '${_amountController.text} ${widget.currencyCode}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.gray200),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'To address',
                value: _addressController.text,
                isMono: true,
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.gray200),
              const SizedBox(height: 12),
              const _SummaryRow(label: 'Network', value: 'Polygon', valueColor: AppColors.purple600),
              const SizedBox(height: 12),
              const Divider(color: AppColors.gray200),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Estimated fee',
                value: _estimate != null
                    ? '${_estimate!.estimatedFeeFormatted} POL'
                    : '...',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Error
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
        ] else ...[
          // Warning
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEF08A)),
            ),
            child: const Text(
              'Please verify the address carefully. Transactions cannot be reversed.',
              style: TextStyle(fontSize: 12, color: Color(0xFFA16207)),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Buttons
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Back',
                onTap: () => setState(() {
                  _step = _SendStep.input;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(
                label: 'Send',
                icon: Icons.arrow_upward,
                onTap: _handleSend,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSendingStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.blue600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sending Transaction',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we process your transaction...',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _CloseButton(onTap: () => Navigator.pop(context)),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.green100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 32, color: AppColors.green600),
          ),
          const SizedBox(height: 16),
          const Text(
            'Transaction Sent!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${_amountController.text} ${widget.currencyCode} has been sent successfully.',
            style: const TextStyle(fontSize: 14, color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Tx hash
          const Text(
            'Transaction Hash',
            style: TextStyle(fontSize: 11, color: AppColors.gray400),
          ),
          const SizedBox(height: 4),
          Text(
            '${_truncateAddress(_txHash)} \u2197',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.blue600,
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Done',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 24, color: AppColors.gray400),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.icon, this.loading = false, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
                : (_hovering ? const Color(0xFF1D4ED8) : AppColors.blue600),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
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

class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.gray200 : AppColors.gray100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.gray900,
            fontFamily: isMono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
