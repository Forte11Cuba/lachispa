import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/currency_info.dart';
import '../l10n/generated/app_localizations.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Preview balance for demo
  final int _previewBalance = 50000; // 50k sats
  int _previewCurrencyIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencySettingsProvider>(
      builder: (context, currencyProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1419),
                  Color(0xFF1A1D47),
                  Color(0xFF2D3FE7),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildHeader(context),
                      );
                    },
                  ),
                  
                  // Content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildContent(context, currencyProvider),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.currency_settings_title ?? 'Currency Settings',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.currency_settings_subtitle ?? 'Select your preferred currencies',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CurrencySettingsProvider currencyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available currencies section
          _buildAvailableCurrenciesSection(currencyProvider),
          
          const SizedBox(height: 32),
          
          // Selected currencies section
          _buildSelectedCurrenciesSection(currencyProvider),
          
          const SizedBox(height: 32),
          
          // Preview section
          _buildPreviewSection(currencyProvider),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvailableCurrenciesSection(CurrencySettingsProvider currencyProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public,
                color: Color(0xFF5B73FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.available_currencies ?? 'Available Currencies',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (currencyProvider.isLoadingCurrencies)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B73FF)),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (currencyProvider.availableCurrencies.isEmpty && !currencyProvider.isLoadingCurrencies)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.no_currencies_available ?? 'No currencies available',
                      style: const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: currencyProvider.availableCurrencies.map((currency) {
                final isSelected = currencyProvider.isCurrencySelected(currency);
                final currencyInfo = currencyProvider.getCurrencyInfo(currency);
                
                return _buildCurrencyListItem(
                  currency: currency,
                  currencyInfo: currencyInfo,
                  isSelected: isSelected,
                  onTap: () => _toggleCurrency(currencyProvider, currency),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedCurrenciesSection(CurrencySettingsProvider currencyProvider) {
    final selectedCurrencies = currencyProvider.selectedCurrencies;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFF5B73FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.selected_currencies ?? 'Selected Currencies',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedCurrencies.length + 1}', // +1 for sats
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sats (always first and can't be removed)
          _buildSelectedCurrencyItem(
            currency: 'sats',
            currencyInfo: null, // Special case for sats
            isFirst: true,
            canRemove: false,
            onRemove: null,
          ),
          
          // User selected currencies
          ...selectedCurrencies.asMap().entries.map((entry) {
            final index = entry.key;
            final currency = entry.value;
            final currencyInfo = currencyProvider.getCurrencyInfo(currency);
            return _buildSelectedCurrencyItem(
              currency: currency,
              currencyInfo: currencyInfo,
              isFirst: false,
              canRemove: true,
              onRemove: () => currencyProvider.removeCurrency(currency),
            );
          }).toList(),
          
          if (selectedCurrencies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.select_currencies_hint ?? 'Select currencies from the list above',
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(CurrencySettingsProvider currencyProvider) {
    final displaySequence = currencyProvider.displaySequence;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview,
                color: Color(0xFF5B73FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.preview_title ?? 'Preview',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Preview balance card
          GestureDetector(
            onTap: () => _cyclePreviewCurrency(displaySequence),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.balance_label ?? 'Balance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Main balance
                  FutureBuilder<String>(
                    future: _getPreviewBalance(currencyProvider, displaySequence),
                    builder: (context, snapshot) {
                      final mainBalance = snapshot.data ?? 'Loading...';
                      return Text(
                        mainBalance,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  
                  // Secondary balance (sats when not in sats mode)
                  if (displaySequence.isNotEmpty && 
                      _previewCurrencyIndex > 0 && 
                      _previewCurrencyIndex < displaySequence.length) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_previewBalance sats',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation indicator
          if (displaySequence.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.touch_app,
                  color: Color(0xFF5B73FF),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.tap_to_cycle ?? 'Tap to cycle currencies',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_previewCurrencyIndex + 1}/${displaySequence.length}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF5B73FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencyListItem({
    required String currency,
    required CurrencyInfo? currencyInfo,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final flag = currencyInfo?.flag ?? '💰';
    final name = currencyInfo?.name ?? currency;
    final country = currencyInfo?.country ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF2D3FE7).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF2D3FE7)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Flag and selection indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF2D3FE7).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF2D3FE7)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D3FE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Currency info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currency,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF2D3FE7) : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF2D3FE7).withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              currencyInfo?.symbol ?? currency,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected 
                                    ? const Color(0xFF2D3FE7)
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? const Color(0xFF2D3FE7).withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (country.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          country,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: isSelected 
                                ? const Color(0xFF2D3FE7).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF2D3FE7) : Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCurrencyItem({
    required String currency,
    required CurrencyInfo? currencyInfo,
    required bool isFirst,
    required bool canRemove,
    required VoidCallback? onRemove,
  }) {
    final flag = isFirst ? '⚡' : (currencyInfo?.flag ?? '💰');
    final name = isFirst ? 'Satoshis' : (currencyInfo?.name ?? currency);
    final country = isFirst ? 'Bitcoin Lightning' : (currencyInfo?.country ?? '');
    final symbol = isFirst ? 'sats' : (currencyInfo?.symbol ?? currency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst 
            ? const Color(0xFFFFD700).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst 
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Flag/Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFirst 
                  ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                  : const Color(0xFF2D3FE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                flag,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Currency information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currency.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFirst ? const Color(0xFFFFD700) : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFirst 
                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isFirst 
                              ? const Color(0xFFFFD700)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isFirst 
                        ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (country.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    country,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: isFirst 
                          ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          if (canRemove && onRemove != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFirst 
                      ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.lock,
                color: isFirst 
                    ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  void _toggleCurrency(CurrencySettingsProvider currencyProvider, String currency) {
    if (currency == 'sats') return; // Can't toggle sats
    
    if (currencyProvider.isCurrencySelected(currency)) {
      currencyProvider.removeCurrency(currency);
    } else {
      currencyProvider.addCurrency(currency);
    }
  }

  void _cyclePreviewCurrency(List<String> displaySequence) {
    if (displaySequence.isEmpty) return;
    
    setState(() {
      _previewCurrencyIndex = (_previewCurrencyIndex + 1) % displaySequence.length;
    });
  }

  Future<String> _getPreviewBalance(
    CurrencySettingsProvider currencyProvider, 
    List<String> displaySequence,
  ) async {
    if (displaySequence.isEmpty) return '$_previewBalance sats';
    
    final currentCurrency = displaySequence[_previewCurrencyIndex];
    
    if (currentCurrency == 'sats') {
      return '$_previewBalance sats';
    }
    
    final converted = await currencyProvider.convertSatsToFiat(_previewBalance, currentCurrency);
    final symbol = currencyProvider.getCurrencySymbol(currentCurrency);
    
    if (symbol.startsWith(currentCurrency)) {
      return '$converted $currentCurrency';
    } else {
      return '$symbol$converted';
    }
  }
}