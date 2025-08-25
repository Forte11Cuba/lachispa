import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';
import '../models/transaction_info.dart';
import '../l10n/generated/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _staggerController;
  late Animation<double> _glowAnimation;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;
  
  List<TransactionInfo> _transactions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  TransactionFilter _currentFilter = TransactionFilter.all;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    
    // Load transactions after first frame to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  void _setupAnimations() {
    // Glow animation for title effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Staggered animation controller for entrance effects
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Header animation timing
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
    ));

    // List animation timing
    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _staggerController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final walletProvider = context.read<WalletProvider>();
      final walletService = context.read<WalletService>();

      if (!authProvider.isLoggedIn || walletProvider.primaryWallet == null) {
        throw Exception('No active session or primary wallet');
      }

      print('=== DEBUG TRANSACTION RESPONSE ===');
      print('Server URL: ${authProvider.currentServer}');
      print('Wallet ID: ${walletProvider.primaryWallet!.id}');
      
      final transactions = await walletService.getWalletTransactions(
        serverUrl: authProvider.currentServer ?? '',
        walletId: walletProvider.primaryWallet!.id,
        adminKey: walletProvider.primaryWallet!.adminKey,
        limit: 50,
      );

      print('=== PARSED TRANSACTIONS DEBUG ===');
      print('Total transactions: ${transactions.length}');
      
      for (int i = 0; i < transactions.length && i < 3; i++) {
        final tx = transactions[i];
        print('--- Transaction $i ---');
        print('Amount: ${tx.amount} msat (${tx.amountSats} sats)');
        print('Memo: ${tx.memo}');
        print('Type: ${tx.type}');
        print('Status: ${tx.status}');
        print('Wallet Fiat: ${tx.fiatAmount} ${tx.fiatCurrency} (rate: ${tx.fiatRate})');
        print('Original Fiat: ${tx.originalFiatAmount} ${tx.originalFiatCurrency} (rate: ${tx.originalFiatRate})');
        print('Display: ${tx.displayAmount}');
        print('JSON toString: ${tx.toString()}');
      }
      print('=== END DEBUG ===');

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('=== ERROR LOADING TRANSACTIONS ===');
      print('Error: $e');
      print('=== END ERROR ===');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<TransactionInfo> get _filteredTransactions {
    switch (_currentFilter) {
      case TransactionFilter.incoming:
        return _transactions.where((tx) => tx.isIncoming).toList();
      case TransactionFilter.outgoing:
        return _transactions.where((tx) => tx.isOutgoing).toList();
      case TransactionFilter.all:
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1D47),
              Color(0xFF2D3FE7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(_headerAnimation),
                    child: FadeTransition(
                      opacity: _headerAnimation,
                      child: _buildHeader(),
                    ),
                  );
                },
              ),
              
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(_headerAnimation),
                    child: FadeTransition(
                      opacity: _headerAnimation,
                      child: _buildFilters(),
                    ),
                  );
                },
              ),
              
              Expanded(
                child: AnimatedBuilder(
                  animation: _listAnimation,
                  builder: (context, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_listAnimation),
                      child: FadeTransition(
                        opacity: _listAnimation,
                        child: _buildTransactionsList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D3FE7).withValues(alpha: _glowAnimation.value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.history_title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF2D3FE7).withValues(alpha: _glowAnimation.value * 0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _loadTransactions,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TransactionFilter.values.map((filter) {
                  final isSelected = _currentFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildFilterChip(filter, isSelected),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TransactionFilter filter, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2D3FE7)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 16,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _getFilterLabel(filter),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return Icons.list;
      case TransactionFilter.incoming:
        return Icons.arrow_downward;
      case TransactionFilter.outgoing:
        return Icons.arrow_upward;
    }
  }

  String _getFilterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return AppLocalizations.of(context)!.history_title;
      case TransactionFilter.incoming:
        return AppLocalizations.of(context)!.received_label;
      case TransactionFilter.outgoing:
        return AppLocalizations.of(context)!.sent_label;
    }
  }

  /// Determine appropriate icon for transaction based on status and type
  IconData _getTransactionIcon(TransactionInfo transaction) {
    // Show pending icon for pending transactions regardless of type
    if (transaction.isPending) {
      return Icons.access_time;
    }
    
    // Show error icon for failed transactions
    if (transaction.isFailed) {
      return Icons.error_outline;
    }
    
    // Show arrow based on direction for completed transactions
    if (transaction.isIncoming) {
      return Icons.arrow_downward_rounded;
    } else {
      return Icons.arrow_upward_rounded;
    }
  }

  /// Get transaction status label based on status and type
  String _getTransactionStatusLabel(TransactionInfo transaction) {
    if (transaction.isPending) {
      return AppLocalizations.of(context)!.pending_label;
    }
    
    if (transaction.isFailed) {
      return AppLocalizations.of(context)!.failed_label;
    }
    
    // For completed transactions, show direction
    return transaction.isIncoming 
        ? AppLocalizations.of(context)!.received_label 
        : AppLocalizations.of(context)!.sent_label;
  }

  /// Get transaction status for details modal
  String _getTransactionStatus(TransactionInfo transaction) {
    if (transaction.isPending) {
      return AppLocalizations.of(context)!.pending_label;
    }
    
    if (transaction.isFailed) {
      return AppLocalizations.of(context)!.failed_label;
    }
    
    return AppLocalizations.of(context)!.valid_status;
  }

  /// Determine appropriate color for transaction based on status and type
  Color _getTransactionIconColor(TransactionInfo transaction) {
    // Show orange color for pending transactions regardless of type
    if (transaction.isPending) {
      return Colors.orange;
    }
    
    // Show red color for failed transactions
    if (transaction.isFailed) {
      return Colors.red;
    }
    
    // Show color based on direction for completed transactions
    if (transaction.isIncoming) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3FE7)),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loading_transactions_text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loading_transactions_error_prefix,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3FE7),
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.connect_button),
            ),
          ],
        ),
      );
    }

    final filteredTransactions = _filteredTransactions;

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.no_transactions_text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.no_transactions_description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: const Color(0xFF2D3FE7),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return _buildTransactionCard(transaction, index);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionInfo transaction, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTransactionIconColor(transaction).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransactionIcon(transaction),
                  color: _getTransactionIconColor(transaction),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.memo.isEmpty ? AppLocalizations.of(context)!.no_description_text : transaction.memo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      transaction.formattedDate,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (transaction.isPending) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.pending_label,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Amount column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.displayAmount.split('\n').first, // Show sats amount
                    style: TextStyle(
                      color: _getTransactionIconColor(transaction),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (transaction.fiatAmount != null && transaction.fiatCurrency != null)
                    Text(
                      '${transaction.type == TransactionType.incoming ? '+' : '-'}${transaction.fiatAmount!.toStringAsFixed(2)} ${transaction.fiatCurrency}',
                      style: TextStyle(
                        color: _getTransactionIconColor(transaction).withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (transaction.originalFiatAmount != null && transaction.originalFiatCurrency != null)
                    Text(
                      '${transaction.originalFiatAmount!.toStringAsFixed(2)} ${transaction.originalFiatCurrency}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionInfo transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D47),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTransactionIconColor(transaction).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction),
                    color: _getTransactionIconColor(transaction),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionStatusLabel(transaction),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.displayAmount.split('\n').first, // Show sats amount
                            style: TextStyle(
                              color: _getTransactionIconColor(transaction),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (transaction.fiatAmount != null && transaction.fiatCurrency != null)
                            Text(
                              '${transaction.type == TransactionType.incoming ? '+' : '-'}${transaction.fiatAmount!.toStringAsFixed(2)} ${transaction.fiatCurrency}',
                              style: TextStyle(
                                color: _getTransactionIconColor(transaction).withValues(alpha: 0.8),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (transaction.originalFiatAmount != null && transaction.originalFiatCurrency != null)
                            Text(
                              '${transaction.originalFiatAmount!.toStringAsFixed(2)} ${transaction.originalFiatCurrency}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildDetailRow('Date', transaction.formattedDate),
            _buildDetailRow('Description', transaction.memo.isEmpty ? AppLocalizations.of(context)!.no_description_text : transaction.memo),
            if (transaction.originalFiatAmount != null && transaction.originalFiatCurrency != null) ...[
              _buildDetailRow('Original Amount', '${transaction.originalFiatAmount!.toStringAsFixed(2)} ${transaction.originalFiatCurrency}'),
              if (transaction.originalFiatRate != null)
                _buildDetailRow('Original Rate', '${transaction.originalFiatRate!.toStringAsFixed(4)} sats/${transaction.originalFiatCurrency}'),
            ],
            if (transaction.fiatAmount != null && transaction.fiatCurrency != null) ...[
              _buildDetailRow('Wallet Amount', '${transaction.fiatAmount!.toStringAsFixed(2)} ${transaction.fiatCurrency}'),
              if (transaction.fiatRate != null)
                _buildDetailRow('Wallet Rate', '${transaction.fiatRate!.toStringAsFixed(2)} sats/${transaction.fiatCurrency}'),
            ],
            if (transaction.paymentHash != null)
              _buildDetailRow('Hash', transaction.paymentHash!, copyable: true),
            if (transaction.fee != null)
              _buildDetailRow('Fee', '${transaction.fee} msat'),
            _buildDetailRow(AppLocalizations.of(context)!.invoice_status_label, _getTransactionStatus(transaction)),
            
            const SizedBox(height: 16),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3FE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.cancel_button),
              ),
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: copyable ? () {
                // TODO: Implement clipboard copy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.address_copied_message)),
                );
              } : null,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: copyable ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionFilter {
  all,
  incoming,
  outgoing,
}