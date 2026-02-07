import 'package:flutter/material.dart';
import 'package:flutter_app/generated/l10n/app_localizations.dart';
import 'package:flutter_app/mock_data.dart';
import 'package:flutter_app/sections/navbar_section.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_app/widgets/send_modal.dart';
import 'package:flutter_app/widgets/receive_modal.dart';
import 'package:flutter_app/services/balance_service.dart';
import 'package:flutter_app/services/transaction_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _activeIndex = 0;
  bool _refreshing = false;
  bool _loadingBalances = true;
  bool _loadingTransactions = true;
  String? _balanceError;
  String? _transactionError;

  List<CurrencyInfo> _balances = [];
  String _walletAddress = '';
  List<Transaction> _transactions = [];

  CurrencyInfo? get _activeCurrency =>
      _balances.isNotEmpty ? _balances[_activeIndex] : null;

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  Future<void> _fetchBalances() async {
    setState(() {
      _loadingBalances = true;
      _balanceError = null;
    });
    try {
      final response = await BalanceService().getBalances();
      _walletAddress = response.address;
      final balances = response.balances.map((b) {
        final meta = currencyMeta[b.currencyCode];
        return CurrencyInfo(
          code: b.currencyCode,
          name: meta?.name ?? b.currencyCode,
          balance: b.formattedBalance,
          color: meta?.color ?? AppColors.gray500,
          icon: meta?.icon ?? Icons.token,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _balances = balances;
          _loadingBalances = false;
          _activeIndex = 0;
        });
        _fetchTransactions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBalances = false;
          _balanceError = e.toString();
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    final currency = _activeCurrency;
    if (currency == null) return;
    setState(() {
      _loadingTransactions = true;
      _transactionError = null;
    });
    try {
      final response = await TransactionService().getTransactions(
        currency.code,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _transactions = response.transactions;
          _loadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTransactions = false;
          _transactionError = e.toString();
        });
      }
    }
  }

  void _handleRefresh() {
    setState(() => _refreshing = true);
    _fetchBalances().then((_) {
      if (mounted) setState(() => _refreshing = false);
    });
  }

  void _handleCurrencyChange(int index) {
    setState(() => _activeIndex = index);
    _fetchTransactions();
  }

  String _truncateAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final days = diff.inDays;
    if (days < 7) return '${days}d ago';
    return '${date.month}/${date.day}/${date.year}';
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
                    constraints: const BoxConstraints(maxWidth: 512),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                      child: _loadingBalances
                          ? _buildLoadingState()
                          : _balanceError != null
                              ? _buildErrorState(_balanceError!)
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCurrencySelector(),
                                    const SizedBox(height: 32),
                                    _buildBalanceCard(l10n),
                                    const SizedBox(height: 40),
                                    _buildTransactionsList(l10n),
                                  ],
                                ),
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

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator(color: AppColors.blue600)),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red500),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: AppColors.gray600)),
            const SizedBox(height: 16),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _fetchBalances,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_balances.length, (index) {
          final currency = _balances[index];
          final isActive = index == _activeIndex;
          return Padding(
            padding: EdgeInsets.only(right: index < _balances.length - 1 ? 12 : 0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _handleCurrencyChange(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 80,
                  height: 80,
                  transform: Matrix4.identity()..scaleByDouble(isActive ? 1.05 : 1.0, isActive ? 1.05 : 1.0, 1.0, 1.0),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? currency.color : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? Colors.transparent : AppColors.gray100,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: currency.color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currency.icon,
                          size: 18,
                          color: isActive ? currency.color : AppColors.gray400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.code,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.white : AppColors.gray400,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations l10n) {
    final currency = _activeCurrency!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: currency.color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: currency.color.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle
          Positioned(
            top: -48,
            right: -24,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: currency icon + name + refresh
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(currency.icon, size: 18, color: currency.color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currency.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    _RefreshButton(
                      refreshing: _refreshing,
                      onTap: _handleRefresh,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Balance
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: currency.balance,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: '  ${currency.code}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Send / Receive buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.arrow_upward,
                      label: l10n.dashboard_send,
                      onTap: () => showSendModal(
                        context,
                        currencyCode: currency.code,
                        currencyName: currency.name,
                        balance: currency.balance,
                      ),
                    ),
                    const SizedBox(width: 64),
                    _ActionButton(
                      icon: Icons.arrow_downward,
                      label: l10n.dashboard_receive,
                      onTap: () => showReceiveModal(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AppLocalizations l10n) {
    final currency = _activeCurrency!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.dashboard_transactions,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                currency.code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray400,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loadingTransactions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.blue600)),
          )
        else if (_transactionError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(_transactionError!, style: const TextStyle(color: AppColors.gray500)),
          )
        else if (_transactions.isEmpty)
          _buildEmptyState(l10n)
        else
          ..._transactions.map((tx) => _buildTransactionCard(tx)),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: AppColors.gray50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: AppColors.gray100,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 48,
            color: AppColors.gray400.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dashboard_empty,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.gray400,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    final isSent = tx.from.toLowerCase() == _walletAddress.toLowerCase();
    final displayAddress = isSent ? tx.to : tx.from;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Direction indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSent
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isSent ? '\u2191' : '\u2193',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSent ? AppColors.red500 : AppColors.green600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent ? 'Sent' : 'Received',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        _truncateAddress(displayAddress),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isSent ? '-' : '+'}${tx.formattedValue}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isSent ? AppColors.red500 : AppColors.green600,
                      ),
                    ),
                    Text(
                      tx.currencyCode,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(tx.timestamp),
                  style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                ),
                Text(
                  '${_truncateAddress(tx.hash)} \u2197',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final bool refreshing;
  final VoidCallback onTap;
  const _RefreshButton({required this.refreshing, required this.onTap});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(_RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing && !oldWidget.refreshing) {
      _controller.repeat();
    } else if (!widget.refreshing && oldWidget.refreshing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.refreshing ? null : widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: child,
              );
            },
            child: const Icon(Icons.refresh, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _hovering
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
