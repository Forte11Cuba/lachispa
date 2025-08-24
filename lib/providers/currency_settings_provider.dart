import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_rates_service.dart';
import '../models/currency_info.dart';

class CurrencySettingsProvider extends ChangeNotifier {
  final CurrencyRatesService _ratesService = CurrencyRatesService();
  
  // Selected currencies by user (excluding 'sats' which is always included)
  List<String> _selectedCurrencies = ['USD', 'CUP'];
  
  // Available currencies from server/API
  List<String> _availableCurrencies = [];
  
  // Current exchange rates cache
  Map<String, double> _exchangeRates = {};
  
  // Cache timestamp
  DateTime? _lastRatesUpdate;
  
  // Loading states
  bool _isLoadingCurrencies = false;
  bool _isLoadingRates = false;
  
  // Current server URL for rates
  String? _serverUrl;
  
  // SharedPreferences keys
  static const String _selectedCurrenciesKey = 'selected_currencies';
  static const String _exchangeRatesKey = 'exchange_rates_cache';
  static const String _lastUpdateKey = 'last_rates_update';

  // Getters
  List<String> get selectedCurrencies => List<String>.from(_selectedCurrencies);
  List<String> get availableCurrencies => List<String>.from(_availableCurrencies);
  Map<String, double> get exchangeRates => Map<String, double>.from(_exchangeRates);
  bool get isLoadingCurrencies => _isLoadingCurrencies;
  bool get isLoadingRates => _isLoadingRates;
  DateTime? get lastRatesUpdate => _lastRatesUpdate;
  
  /// Get display sequence for currency toggle (sats first, then user selection)
  List<String> get displaySequence => ['sats', ..._selectedCurrencies];
  
  /// Get currency info with flag and full details
  CurrencyInfo? getCurrencyInfo(String currencyCode) {
    return CurrencyInfo.getInfo(currencyCode);
  }
  
  /// Get formatted display name for currency
  String getCurrencyDisplayName(String currencyCode) {
    final info = CurrencyInfo.getInfo(currencyCode);
    return info?.name ?? currencyCode;
  }
  
  /// Get currency symbol
  String getCurrencySymbol(String currencyCode) {
    final info = CurrencyInfo.getInfo(currencyCode);
    return info?.symbol ?? currencyCode;
  }
  
  /// Get currency flag
  String getCurrencyFlag(String currencyCode) {
    final info = CurrencyInfo.getInfo(currencyCode);
    return info?.flag ?? '💰';
  }
  
  /// Get currency country
  String getCurrencyCountry(String currencyCode) {
    final info = CurrencyInfo.getInfo(currencyCode);
    return info?.country ?? currencyCode;
  }

  /// Initialize the provider with server URL and load saved settings
  Future<void> initialize({required String serverUrl}) async {
    print('[CURRENCY_SETTINGS_PROVIDER] Initializing with server: $serverUrl');
    
    if (serverUrl.isEmpty) {
      throw Exception('Server URL is required for currency initialization');
    }
    
    _serverUrl = serverUrl;
    
    // Load saved settings
    await _loadSavedSettings();
    
    // Get available currencies from server/API
    await loadAvailableCurrencies();
    
    // Load exchange rates if we have selected currencies
    if (_selectedCurrencies.isNotEmpty) {
      await loadExchangeRates();
    }
  }

  /// Load available currencies from current server only
  Future<void> loadAvailableCurrencies() async {
    if (_isLoadingCurrencies || _serverUrl == null || _serverUrl!.isEmpty) return;
    
    _isLoadingCurrencies = true;
    notifyListeners();
    
    try {
      print('[CURRENCY_SETTINGS_PROVIDER] Loading currencies from current server only');
      _availableCurrencies = await _ratesService.getAvailableCurrencies(
        serverUrl: _serverUrl!,
      );
      
      print('[CURRENCY_SETTINGS_PROVIDER] SUCCESS: ${_availableCurrencies.length} currencies from current server');
      
      // Ensure selected currencies are still available
      _validateSelectedCurrencies();
      
      // Test if rates are actually working by trying to get exchange rates
      if (_availableCurrencies.isNotEmpty) {
        try {
          final testRates = await _ratesService.getExchangeRates(
            currencies: _availableCurrencies.take(3).toList(), // Test first 3 currencies
            serverUrl: _serverUrl!,
          );
          
          if (testRates.isEmpty) {
            print('[CURRENCY_SETTINGS_PROVIDER] WARNING: Server has currencies but no rates available');
            // Keep currencies list but rates will fail later
          } else {
            print('[CURRENCY_SETTINGS_PROVIDER] SUCCESS: Server rates are working (${testRates.length} rates tested)');
          }
        } catch (e) {
          print('[CURRENCY_SETTINGS_PROVIDER] WARNING: Server currencies available but rates failing: $e');
          // Keep currencies list - individual rate failures will be handled in UI
        }
      }
      
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] FAILED: Current server unavailable - $e');
      // Clear available currencies - user will only see sats
      _availableCurrencies = [];
      // Keep user preferences saved for when server comes back
    } finally {
      _isLoadingCurrencies = false;
      notifyListeners();
    }
  }

  /// Load exchange rates for selected currencies from current server only
  Future<void> loadExchangeRates({bool forceRefresh = false}) async {
    if (_isLoadingRates || _serverUrl == null || _serverUrl!.isEmpty) return;
    
    // Check if we need to refresh (5 minutes cache)
    if (!forceRefresh && _lastRatesUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastRatesUpdate!);
      if (timeSinceUpdate.inMinutes < 5) {
        print('[CURRENCY_SETTINGS_PROVIDER] Using cached rates (${timeSinceUpdate.inMinutes}min old)');
        return;
      }
    }
    
    _isLoadingRates = true;
    notifyListeners();
    
    try {
      print('[CURRENCY_SETTINGS_PROVIDER] Loading rates from current server only for ${_selectedCurrencies.length} currencies');
      
      _exchangeRates = await _ratesService.getExchangeRates(
        currencies: _selectedCurrencies,
        serverUrl: _serverUrl!,
      );
      
      _lastRatesUpdate = DateTime.now();
      
      print('[CURRENCY_SETTINGS_PROVIDER] SUCCESS: ${_exchangeRates.length} rates from current server');
      
      // Save rates to cache
      await _saveRatesToCache();
      
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] FAILED: Current server rates unavailable - $e');
      
      // Try to load from cache if available
      await _loadRatesFromCache();
      
    } finally {
      _isLoadingRates = false;
      notifyListeners();
    }
  }

  /// Set selected currencies and save to preferences
  Future<void> setSelectedCurrencies(List<String> currencies) async {
    print('[CURRENCY_SETTINGS_PROVIDER] Setting selected currencies: $currencies');
    
    // Filter out 'sats' and ensure all currencies are available
    final validCurrencies = currencies
        .where((currency) => currency != 'sats' && _availableCurrencies.contains(currency))
        .toList();
    
    if (validCurrencies.isEmpty) {
      print('[CURRENCY_SETTINGS_PROVIDER] No valid currencies selected, keeping defaults');
      return;
    }
    
    _selectedCurrencies = validCurrencies;
    
    // Save to preferences
    await _saveSelectedCurrencies();
    
    // Refresh exchange rates
    await loadExchangeRates(forceRefresh: true);
    
    notifyListeners();
  }

  /// Add a currency to selection
  Future<void> addCurrency(String currencyCode) async {
    if (!_availableCurrencies.contains(currencyCode) || 
        _selectedCurrencies.contains(currencyCode) ||
        currencyCode == 'sats') {
      return;
    }
    
    final newList = [..._selectedCurrencies, currencyCode];
    await setSelectedCurrencies(newList);
  }

  /// Remove a currency from selection
  Future<void> removeCurrency(String currencyCode) async {
    if (!_selectedCurrencies.contains(currencyCode)) {
      return;
    }
    
    final newList = _selectedCurrencies.where((c) => c != currencyCode).toList();
    
    // Ensure we always have at least one currency
    if (newList.isEmpty) {
      newList.add('USD');
    }
    
    await setSelectedCurrencies(newList);
  }

  /// Reorder selected currencies
  Future<void> reorderCurrencies(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _selectedCurrencies.length ||
        newIndex < 0 || newIndex >= _selectedCurrencies.length) {
      return;
    }
    
    final newList = List<String>.from(_selectedCurrencies);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    
    await setSelectedCurrencies(newList);
  }

  /// Check if a currency is selected
  bool isCurrencySelected(String currencyCode) {
    return currencyCode == 'sats' || _selectedCurrencies.contains(currencyCode);
  }

  /// Get conversion rate for a currency
  double? getRateForCurrency(String currencyCode) {
    return _exchangeRates[currencyCode];
  }

  /// Convert satoshis to fiat currency using current server rates
  Future<String> convertSatsToFiat(int sats, String currencyCode) async {
    print('[CURRENCY_SETTINGS_PROVIDER] convertSatsToFiat called: $sats sats to $currencyCode');
    
    if (currencyCode == 'sats') {
      print('[CURRENCY_SETTINGS_PROVIDER] Returning sats directly');
      return '$sats';
    }
    
    if (_serverUrl == null || _serverUrl!.isEmpty) {
      print('[CURRENCY_SETTINGS_PROVIDER] No server URL - cannot convert');
      print('[CURRENCY_SETTINGS_PROVIDER] Server URL: ${_serverUrl ?? 'null'}');
      return '--';
    }
    
    print('[CURRENCY_SETTINGS_PROVIDER] Server URL: $_serverUrl');
    print('[CURRENCY_SETTINGS_PROVIDER] Available rates: ${_exchangeRates.keys.toList()}');
    
    try {
      print('[CURRENCY_SETTINGS_PROVIDER] Starting conversion...');
      
      // Add timeout to prevent infinite loading
      final result = await _ratesService.convertSatsToFiat(
        sats: sats,
        currency: currencyCode,
        rates: _exchangeRates,
        serverUrl: _serverUrl!,
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          print('[CURRENCY_SETTINGS_PROVIDER] Conversion timeout for $currencyCode');
          return '--';
        },
      );
      
      print('[CURRENCY_SETTINGS_PROVIDER] Conversion result: $result');
      return result;
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Current server conversion failed: $e');
      return '--';
    }
  }

  /// Convert fiat to satoshis using current server rates
  Future<int> convertFiatToSats(double amount, String currencyCode) async {
    if (currencyCode == 'sats') {
      return amount.round();
    }
    
    if (_serverUrl == null || _serverUrl!.isEmpty) {
      throw Exception('No server URL - cannot convert');
    }
    
    try {
      return await _ratesService.convertFiatToSats(
        amount: amount,
        currency: currencyCode,
        rates: _exchangeRates,
        serverUrl: _serverUrl!,
      );
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Current server conversion failed: $e');
      throw Exception('Current server unavailable for conversion');
    }
  }

  /// Update server URL and refresh data
  Future<void> updateServerUrl(String? serverUrl) async {
    if (_serverUrl == serverUrl) return;
    
    print('[CURRENCY_SETTINGS_PROVIDER] Updating server URL: ${serverUrl ?? 'none'}');
    _serverUrl = serverUrl;
    
    // Clear cache and reload
    _exchangeRates.clear();
    _availableCurrencies.clear();
    _lastRatesUpdate = null;
    
    await loadAvailableCurrencies();
    await loadExchangeRates(forceRefresh: true);
  }

  /// Validate selected currencies against available ones
  void _validateSelectedCurrencies() {
    if (_availableCurrencies.isEmpty) return;
    
    final validCurrencies = _selectedCurrencies
        .where((currency) => _availableCurrencies.contains(currency))
        .toList();
    
    // If no valid currencies, use defaults
    if (validCurrencies.isEmpty) {
      validCurrencies.addAll(['USD', 'EUR'].where((c) => _availableCurrencies.contains(c)));
      
      // If still empty, use first available
      if (validCurrencies.isEmpty && _availableCurrencies.isNotEmpty) {
        validCurrencies.add(_availableCurrencies.first);
      }
    }
    
    if (validCurrencies.length != _selectedCurrencies.length) {
      print('[CURRENCY_SETTINGS_PROVIDER] Validated currencies: ${validCurrencies.length}/${_selectedCurrencies.length}');
      _selectedCurrencies = validCurrencies;
      _saveSelectedCurrencies();
    }
  }

  /// Load saved settings from SharedPreferences
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load selected currencies
      final savedCurrencies = prefs.getStringList(_selectedCurrenciesKey);
      if (savedCurrencies != null && savedCurrencies.isNotEmpty) {
        _selectedCurrencies = savedCurrencies;
        print('[CURRENCY_SETTINGS_PROVIDER] Loaded saved currencies: $_selectedCurrencies');
      }
      
      // Load cached rates
      await _loadRatesFromCache();
      
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Error loading saved settings: $e');
    }
  }

  /// Save selected currencies to SharedPreferences
  Future<void> _saveSelectedCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_selectedCurrenciesKey, _selectedCurrencies);
      print('[CURRENCY_SETTINGS_PROVIDER] Saved selected currencies: $_selectedCurrencies');
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Error saving selected currencies: $e');
    }
  }

  /// Save exchange rates to cache
  Future<void> _saveRatesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert rates to JSON string
      final ratesJson = _exchangeRates.map((key, value) => MapEntry(key, value.toString()));
      final ratesString = ratesJson.entries.map((e) => '${e.key}:${e.value}').join(',');
      
      await prefs.setString(_exchangeRatesKey, ratesString);
      await prefs.setString(_lastUpdateKey, _lastRatesUpdate?.millisecondsSinceEpoch.toString() ?? '');
      
      print('[CURRENCY_SETTINGS_PROVIDER] Saved ${_exchangeRates.length} rates to cache');
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Error saving rates cache: $e');
    }
  }

  /// Load exchange rates from cache
  Future<void> _loadRatesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final ratesString = prefs.getString(_exchangeRatesKey);
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      
      if (ratesString != null && ratesString.isNotEmpty) {
        final rates = <String, double>{};
        
        for (final pair in ratesString.split(',')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            rates[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
          }
        }
        
        if (rates.isNotEmpty) {
          _exchangeRates = rates;
          print('[CURRENCY_SETTINGS_PROVIDER] Loaded ${rates.length} rates from cache');
        }
      }
      
      if (lastUpdateString != null && lastUpdateString.isNotEmpty) {
        final timestamp = int.tryParse(lastUpdateString);
        if (timestamp != null) {
          _lastRatesUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
      
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Error loading rates cache: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_exchangeRatesKey);
      await prefs.remove(_lastUpdateKey);
      
      _exchangeRates.clear();
      _lastRatesUpdate = null;
      
      print('[CURRENCY_SETTINGS_PROVIDER] Cleared cache');
      notifyListeners();
    } catch (e) {
      print('[CURRENCY_SETTINGS_PROVIDER] Error clearing cache: $e');
    }
  }

  @override
  void dispose() {
    _ratesService.dispose();
    super.dispose();
  }
}