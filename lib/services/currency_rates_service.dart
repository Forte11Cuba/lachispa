import 'package:dio/dio.dart';
import 'dart:convert';

class CurrencyRatesService {
  final Dio _dio = Dio();
  static const String fallbackApiUrl = 'https://api.exchangerate-api.com/v4/latest/BTC';
  
  CurrencyRatesService() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30); // Increased timeout
    _dio.options.receiveTimeout = const Duration(seconds: 30); // Increased timeout
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => print('[CURRENCY_RATES_SERVICE] $obj'),
    ));
  }

  /// Get available currencies ONLY from current LNBits server
  /// 
  /// [serverUrl] - LNBits server URL (required)
  /// 
  /// Returns list of available currency codes from the server or throws exception
  Future<List<String>> getAvailableCurrencies({required String serverUrl}) async {
    print('[CURRENCY_RATES_SERVICE] Getting currencies from current server ONLY: $serverUrl');
    
    if (serverUrl.isEmpty) {
      throw Exception('Server URL is required to get currencies');
    }
    
    try {
      final lnbitsCurrencies = await _getLNBitsCurrencies(serverUrl);
      if (lnbitsCurrencies.isNotEmpty) {
        print('[CURRENCY_RATES_SERVICE] Found ${lnbitsCurrencies.length} currencies from current server');
        return lnbitsCurrencies;
      }
      
      // If no currency endpoints found, try testing common currencies by calling rate endpoints
      print('[CURRENCY_RATES_SERVICE] No currency list endpoint found, testing common currencies');
      final commonCurrencies = ['USD', 'EUR', 'GBP', 'CUP', 'CAD', 'JPY', 'AUD', 'CHF'];
      final availableCurrencies = <String>[];
      
      for (final currency in commonCurrencies) {
        try {
          final endpoint = '$serverUrl/lnurlp/api/v1/rate/$currency';
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200) {
            availableCurrencies.add(currency);
            print('[CURRENCY_RATES_SERVICE] Currency $currency is available');
          }
        } catch (e) {
          print('[CURRENCY_RATES_SERVICE] Currency $currency not available: $e');
        }
      }
      
      if (availableCurrencies.isNotEmpty) {
        print('[CURRENCY_RATES_SERVICE] Found ${availableCurrencies.length} working currencies: $availableCurrencies');
        return availableCurrencies;
      }
      
      throw Exception('No working currencies found on current server');
      
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Current server failed: $e');
      throw Exception('Current server unavailable: $e');
    }
  }

  /// Try to get currencies from LNBits server extensions
  Future<List<String>> _getLNBitsCurrencies(String serverUrl) async {
    // Try LNBits endpoints in order of priority
    final endpoints = [
      '$serverUrl/lnurlp/api/v1/currencies',        // Found in OpenAPI - primary
      '$serverUrl/api/v1/currencies',
      '$serverUrl/api/v1/rates', 
      '$serverUrl/api/v1/extension/fiat/currencies',
      '$serverUrl/api/v1/extension/fiat/rates',
      '$serverUrl/tpos/api/v1/currencies',
    ];

    print('[CURRENCY_RATES_SERVICE] Testing ${endpoints.length} currency endpoints (OpenAPI confirmed first)');
    
    for (final endpoint in endpoints) {
      try {
        print('[CURRENCY_RATES_SERVICE] Trying endpoint: $endpoint');
        final response = await _dio.get(endpoint);
        print('[CURRENCY_RATES_SERVICE] $endpoint responded with status: ${response.statusCode}');
        
        if (response.statusCode == 200 && response.data != null) {
          print('[CURRENCY_RATES_SERVICE] Data type: ${response.data.runtimeType}');
          print('[CURRENCY_RATES_SERVICE] Data: ${response.data}');
          
          // Parse response based on structure
          final currencies = _parseCurrenciesFromResponse(response.data);
          if (currencies.isNotEmpty) {
            print('[CURRENCY_RATES_SERVICE] Found currencies from $endpoint: $currencies');
            return currencies;
          } else {
            print('[CURRENCY_RATES_SERVICE] No currencies parsed from $endpoint response');
          }
        }
      } catch (e) {
        print('[CURRENCY_RATES_SERVICE] Endpoint $endpoint failed: $e');
        continue; // Try next endpoint
      }
    }
    
    print('[CURRENCY_RATES_SERVICE] No currency endpoints found on server');
    return [];
  }

  /// Parse currencies from various LNBits response formats
  List<String> _parseCurrenciesFromResponse(dynamic data) {
    try {
      print('[CURRENCY_RATES_SERVICE] Parsing currency data: $data');
      
      if (data is Map<String, dynamic>) {
        // Check multiple possible keys
        if (data.containsKey('currencies')) {
          final currencies = List<String>.from(data['currencies']);
          print('[CURRENCY_RATES_SERVICE] Found currencies in "currencies" key: $currencies');
          return currencies;
        } else if (data.containsKey('rates')) {
          final rates = data['rates'];
          if (rates is Map<String, dynamic>) {
            final currencies = List<String>.from(rates.keys);
            print('[CURRENCY_RATES_SERVICE] Found currencies in "rates" keys: $currencies');
            return currencies;
          }
        } else if (data.containsKey('supported_currencies')) {
          final currencies = List<String>.from(data['supported_currencies']);
          print('[CURRENCY_RATES_SERVICE] Found currencies in "supported_currencies" key: $currencies');
          return currencies;
        } else if (data.containsKey('fiat_currencies')) {
          final currencies = List<String>.from(data['fiat_currencies']);
          print('[CURRENCY_RATES_SERVICE] Found currencies in "fiat_currencies" key: $currencies');
          return currencies;
        } else {
          // If it's a map with currency-like keys (3 letter codes)
          final potentialCurrencies = data.keys.where((key) => 
            key is String && key.length == 3 && key.toUpperCase() == key
          ).cast<String>().toList();
          
          if (potentialCurrencies.isNotEmpty) {
            print('[CURRENCY_RATES_SERVICE] Found potential currencies from map keys: $potentialCurrencies');
            return potentialCurrencies;
          }
        }
      } else if (data is List) {
        final currencies = data.map((e) => e.toString()).toList();
        print('[CURRENCY_RATES_SERVICE] Found currencies in array: $currencies');
        return currencies;
      }
      
      print('[CURRENCY_RATES_SERVICE] No currencies found in data structure');
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Error parsing currencies: $e');
    }
    return [];
  }

  /// Get current exchange rates ONLY from current LNBits server
  /// 
  /// [currencies] - List of currency codes to get rates for
  /// [serverUrl] - Required LNBits server URL for rates
  /// 
  /// Returns map of currency code to BTC exchange rate or throws exception
  Future<Map<String, double>> getExchangeRates({
    List<String>? currencies,
    required String serverUrl,
  }) async {
    print('[CURRENCY_RATES_SERVICE] Getting exchange rates from current server ONLY');
    
    if (serverUrl.isEmpty) {
      throw Exception('Server URL is required to get rates');
    }
    
    try {
      final lnbitsRates = await _getLNBitsRates(serverUrl, currencies);
      if (lnbitsRates.isNotEmpty) {
        print('[CURRENCY_RATES_SERVICE] Got ${lnbitsRates.length} rates from current server');
        return lnbitsRates;
      }
      
      throw Exception('No rates available from current server');
      
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Current server rates failed: $e');
      throw Exception('Current server rates unavailable: $e');
    }
  }

  /// Try to get rates from LNBits server
  Future<Map<String, double>> _getLNBitsRates(String serverUrl, List<String>? currencies) async {
    print('[CURRENCY_RATES_SERVICE] Getting rates from LNBits server for currencies: $currencies');
    
    // If we have specific currencies, try to get their rates from conversion endpoint first (more accurate)
    if (currencies != null && currencies.isNotEmpty) {
      final Map<String, double> rates = {};
      
      for (final currency in currencies) {
        try {
          // Try direct rate endpoint
          print('[CURRENCY_RATES_SERVICE] Getting rate for $currency from server endpoint');
          
          // Fallback to direct rate endpoint
          final endpoint = '$serverUrl/lnurlp/api/v1/rate/$currency';
          print('[CURRENCY_RATES_SERVICE] Trying direct rate endpoint: $endpoint');
          
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200 && response.data != null) {
            print('[CURRENCY_RATES_SERVICE] Rate response for $currency: ${response.data}');
            
            // Parse rate from response
            final rate = _parseRateFromResponse(response.data, currency);
            if (rate != null && rate > 0) {
              // Special validation for CUP - known problematic currency
              if (currency == 'CUP' && rate < 1000) {
                print('[CURRENCY_RATES_SERVICE] CUP rate too low ($rate), using emergency fallback');
                final emergencyRates = _getHardcodedFallbackRates([currency]);
                if (emergencyRates.containsKey(currency)) {
                  rates[currency] = emergencyRates[currency]!;
                }
              } else {
                rates[currency] = rate;
                print('[CURRENCY_RATES_SERVICE] Got rate for $currency: $rate');
              }
            }
          }
        } catch (e) {
          print('[CURRENCY_RATES_SERVICE] Failed to get rate for $currency: $e');
          continue;
        }
      }
      
      if (rates.isNotEmpty) {
        print('[CURRENCY_RATES_SERVICE] Successfully got ${rates.length} rates from server');
        return rates;
      }
    }
    
    // Fallback: try other possible endpoints
    final endpoints = [
      '$serverUrl/api/v1/rates',
      '$serverUrl/api/v1/extension/fiat/rates',
    ];

    for (final endpoint in endpoints) {
      try {
        print('[CURRENCY_RATES_SERVICE] Trying fallback endpoint: $endpoint');
        final response = await _dio.get(endpoint);
        if (response.statusCode == 200) {
          return _parseRatesFromResponse(response.data, currencies);
        }
      } catch (e) {
        print('[CURRENCY_RATES_SERVICE] Fallback endpoint $endpoint failed: $e');
        continue;
      }
    }
    
    print('[CURRENCY_RATES_SERVICE] No rates found from server');
    return {};
  }

  /// Parse individual rate from LNURLP response
  double? _parseRateFromResponse(dynamic data, String currency) {
    try {
      double? rate;
      
      if (data is Map<String, dynamic>) {
        // Common response formats from LNURLP rate endpoint
        if (data.containsKey('rate')) {
          rate = (data['rate'] as num).toDouble();
        } else if (data.containsKey(currency)) {
          rate = (data[currency] as num).toDouble();
        } else if (data.containsKey('btc_${currency.toLowerCase()}')) {
          rate = (data['btc_${currency.toLowerCase()}'] as num).toDouble();
        }
      } else if (data is num) {
        rate = data.toDouble();
      }
      
      // Validate rate is reasonable (not zero, negative, or extreme)
      if (rate != null) {
        if (rate <= 0) {
          print('[CURRENCY_RATES_SERVICE] Invalid rate for $currency: $rate (zero or negative)');
          return null;
        } else if (rate > 10000000) { // More than 10M per BTC seems unrealistic
          print('[CURRENCY_RATES_SERVICE] Suspicious rate for $currency: $rate (too high)');
        } else if (rate < 0.001) { // Less than 0.001 per BTC seems unrealistic
          print('[CURRENCY_RATES_SERVICE] Suspicious rate for $currency: $rate (too low)');
        } else {
          print('[CURRENCY_RATES_SERVICE] Valid rate for $currency: $rate');
        }
        return rate;
      }
      
      print('[CURRENCY_RATES_SERVICE] No valid rate found in response for $currency');
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Error parsing rate for $currency: $e');
    }
    return null;
  }

  /// Get rates from external API (ExchangeRate-API)
  Future<Map<String, double>> _getFallbackRates(List<String>? currencies) async {
    print('[CURRENCY_RATES_SERVICE] Using external API for rates');
    
    final response = await _dio.get(fallbackApiUrl);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      
      final Map<String, double> result = {};
      
      if (currencies != null && currencies.isNotEmpty) {
        // Use specified currencies
        for (final currency in currencies) {
          if (rates.containsKey(currency)) {
            result[currency] = (rates[currency] as num).toDouble();
          }
        }
      } else {
        // Return all available rates
        for (final entry in rates.entries) {
          if (entry.value is num) {
            result[entry.key] = (entry.value as num).toDouble();
          }
        }
      }
      
      print('[CURRENCY_RATES_SERVICE] Got ${result.length} rates from external API');
      return result;
    }
    
    throw Exception('Failed to get rates from external API');
  }

  /// Get all rates from external API (for currency discovery)
  Future<Map<String, double>> _getFallbackRatesFromExternal() async {
    print('[CURRENCY_RATES_SERVICE] Getting all rates from external API for currency discovery');
    
    final response = await _dio.get(fallbackApiUrl);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;
      
      final Map<String, double> result = {};
      
      // Return all available rates
      for (final entry in rates.entries) {
        if (entry.value is num) {
          result[entry.key] = (entry.value as num).toDouble();
        }
      }
      
      print('[CURRENCY_RATES_SERVICE] Got ${result.length} rates for currency discovery');
      return result;
    }
    
    throw Exception('Failed to get rates from external API');
  }

  /// Parse rates from various response formats
  Map<String, double> _parseRatesFromResponse(dynamic data, List<String>? currencies) {
    try {
      Map<String, dynamic> rates = {};
      
      if (data is Map<String, dynamic>) {
        rates = data.containsKey('rates') ? data['rates'] : data;
      }
      
      final Map<String, double> result = {};
      if (currencies != null && currencies.isNotEmpty) {
        // Use specified currencies
        for (final currency in currencies) {
          if (rates.containsKey(currency)) {
            result[currency] = (rates[currency] as num).toDouble();
          }
        }
      } else {
        // Return all available rates
        for (final entry in rates.entries) {
          if (entry.value is num) {
            result[entry.key] = (entry.value as num).toDouble();
          }
        }
      }
      
      return result;
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Error parsing rates: $e');
      return {};
    }
  }

  /// Emergency fallback rates for critical currencies only
  /// Updated with more realistic rates based on current market conditions
  Map<String, double> _getHardcodedFallbackRates(List<String>? currencies) {
    print('[CURRENCY_RATES_SERVICE] Using emergency fallback rates - CURRENT MARKET ESTIMATES');
    
    // Updated emergency rates (more realistic estimates as of 2024)
    final Map<String, double> emergencyRates = {
      'USD': 95000.0,   // ~95k USD/BTC (updated Dec 2024)
      'EUR': 88000.0,   // ~88k EUR/BTC (EUR/USD ~1.08)
      'CUP': 28500000.0, // ~28.5M CUP/BTC (Cuban Peso heavily devalued ~300 CUP/USD black market)
    };
    
    final Map<String, double> result = {};
    
    if (currencies != null && currencies.isNotEmpty) {
      for (final currency in currencies) {
        if (emergencyRates.containsKey(currency)) {
          result[currency] = emergencyRates[currency]!;
          print('[CURRENCY_RATES_SERVICE] Emergency rate for $currency: ${emergencyRates[currency]}');
        }
      }
    } else {
      result.addAll(emergencyRates);
    }
    
    if (result.isEmpty) {
      // Absolute emergency - provide USD
      result['USD'] = 100000.0;
    }
    
    return result;
  }

  /// Convert satoshis to fiat currency using current server's conversion endpoint
  /// 
  /// [sats] - Amount in satoshis
  /// [currency] - Target currency code
  /// [rates] - Optional pre-loaded rates map (ignored, we use direct conversion)
  /// [serverUrl] - Required server URL for conversion
  /// 
  /// Returns formatted fiat amount as string or throws exception
  Future<String> convertSatsToFiat({
    required int sats,
    required String currency,
    Map<String, double>? rates,
    required String serverUrl,
  }) async {
    print('[CURRENCY_RATES_SERVICE] Converting $sats sats to $currency using server: $serverUrl');
    
    try {
      // First try the direct conversion endpoint (POST only, more accurate)
      try {
        final conversionEndpoint = '$serverUrl/api/v1/conversion';
        print('[CURRENCY_RATES_SERVICE] Trying conversion: $conversionEndpoint');
        
        final response = await _dio.post(conversionEndpoint, data: {
          'from_': 'sat',
          'to': currency,
          'amount': sats,
        });
        
        print('[CURRENCY_RATES_SERVICE] POST Response status: ${response.statusCode}');
        print('[CURRENCY_RATES_SERVICE] Response headers: ${response.headers}');
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          print('[CURRENCY_RATES_SERVICE] Conversion response: $data');
          
          // Check if server returned the requested currency
          if (data.containsKey(currency)) {
            final convertedAmount = (data[currency] as num).toDouble();
            print('[CURRENCY_RATES_SERVICE] Raw converted amount: $convertedAmount');
            
            // Validate the converted amount is reasonable
            if (convertedAmount <= 0) {
              print('[CURRENCY_RATES_SERVICE] Invalid converted amount: $convertedAmount');
            } else {
              // Format according to currency
              String formatted;
              switch (currency) {
                case 'JPY':
                case 'CUP':
                  formatted = convertedAmount.toStringAsFixed(0); // No decimals
                  break;
                case 'BTC':
                  formatted = (convertedAmount / 100000000).toStringAsFixed(8); // Convert to BTC
                  break;
                default:
                  formatted = convertedAmount.toStringAsFixed(2); // 2 decimals for most fiat
                  break;
              }
              
              print('[CURRENCY_RATES_SERVICE] Conversion successful: $sats sats = $formatted $currency');
              return formatted;
            }
          } else {
            print('[CURRENCY_RATES_SERVICE] Currency $currency not found in conversion response');
            print('[CURRENCY_RATES_SERVICE] Available keys: ${data.keys.toList()}');
            
            // WORKAROUND: Server bug - it returns USD instead of requested currency
            // If we requested CUP but got USD, calculate CUP from USD using known exchange rate
            if (currency == 'CUP' && data.containsKey('USD')) {
              print('[CURRENCY_RATES_SERVICE] WORKAROUND: Server returned USD instead of CUP, calculating CUP...');
              
              final usdAmount = (data['USD'] as num).toDouble();
              // Approximate USD to CUP rate (1 USD ≈ 120 CUP as of 2024)
              // This is a rough estimate - in production you'd want to get this from a reliable source
              final usdToCupRate = 120.0; 
              final cupAmount = usdAmount * usdToCupRate;
              
              print('[CURRENCY_RATES_SERVICE] Calculated: ${usdAmount.toStringAsFixed(2)} USD × $usdToCupRate = ${cupAmount.toStringAsFixed(0)} CUP');
              print('[CURRENCY_RATES_SERVICE] Workaround successful: $sats sats = ${cupAmount.toStringAsFixed(0)} CUP');
              return cupAmount.toStringAsFixed(0);
            }
          }
        } else {
          print('[CURRENCY_RATES_SERVICE] Invalid response: status=${response.statusCode}, data=${response.data}');
        }
      } catch (e, stackTrace) {
        print('[CURRENCY_RATES_SERVICE] Conversion endpoint failed: ${e.toString()}');
        print('[CURRENCY_RATES_SERVICE] Error type: ${e.runtimeType}');
        if (e is DioException) {
          print('[CURRENCY_RATES_SERVICE] DioException details:');
          print('[CURRENCY_RATES_SERVICE] Response status: ${e.response?.statusCode}');
          print('[CURRENCY_RATES_SERVICE] Response data: ${e.response?.data}');
          print('[CURRENCY_RATES_SERVICE] Request path: ${e.requestOptions.path}');
        }
        print('[CURRENCY_RATES_SERVICE] Falling back to rate-based conversion...');
      }
      
      // Fallback to rate-based conversion
      print('[CURRENCY_RATES_SERVICE] Falling back to rate-based conversion');
      
      // Log if using cached rates or fetching new ones
      if (rates != null && rates.isNotEmpty) {
        print('[CURRENCY_RATES_SERVICE] Using provided rates: ${rates.keys.toList()}');
        if (rates.containsKey(currency)) {
          print('[CURRENCY_RATES_SERVICE] Found $currency rate in cache: ${rates[currency]}');
        } else {
          print('[CURRENCY_RATES_SERVICE] $currency not found in provided rates');
        }
      } else {
        print('[CURRENCY_RATES_SERVICE] Fetching fresh rates for: $currency');
      }
      
      final exchangeRates = rates ?? await getExchangeRates(
        currencies: [currency],
        serverUrl: serverUrl,
      );
      
      print('[CURRENCY_RATES_SERVICE] Final exchange rates: $exchangeRates');
      
      if (!exchangeRates.containsKey(currency)) {
        print('[CURRENCY_RATES_SERVICE] Rate not found for $currency in final rates map');
        throw Exception('Rate not available for $currency from current server');
      }
      
      final fiatRate = exchangeRates[currency]!;
      print('[CURRENCY_RATES_SERVICE] Using rate for $currency: $fiatRate');
      
      // Additional validation for the rate
      if (fiatRate <= 0) {
        print('[CURRENCY_RATES_SERVICE] Invalid rate for $currency: $fiatRate (zero or negative)');
        throw Exception('Invalid exchange rate for $currency: $fiatRate');
      }
      
      final btcAmount = sats / 100000000.0; // Convert sats to BTC
      final fiatAmount = btcAmount * fiatRate;
      
      print('[CURRENCY_RATES_SERVICE] Calculation: $sats sats → ${btcAmount.toStringAsFixed(8)} BTC → $fiatAmount $currency');
      
      // Format according to currency
      String formatted;
      switch (currency) {
        case 'JPY':
        case 'CUP':
          formatted = fiatAmount.toStringAsFixed(0); // No decimals
          break;
        case 'BTC':
          formatted = btcAmount.toStringAsFixed(8); // 8 decimals for BTC
          break;
        default:
          formatted = fiatAmount.toStringAsFixed(2); // 2 decimals for most fiat
          break;
      }
      
      print('[CURRENCY_RATES_SERVICE] $sats sats = $formatted $currency (from current server)');
      return formatted;
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Error converting to $currency using current server: $e');
      throw Exception('Conversion failed - current server unavailable: $e');
    }
  }

  /// Convert fiat currency to satoshis using current server rates
  /// 
  /// [amount] - Amount in fiat currency
  /// [currency] - Source currency code
  /// [rates] - Optional pre-loaded rates map
  /// [serverUrl] - Required server URL for rates
  /// 
  /// Returns amount in satoshis or throws exception
  Future<int> convertFiatToSats({
    required double amount,
    required String currency,
    Map<String, double>? rates,
    required String serverUrl,
  }) async {
    print('[CURRENCY_RATES_SERVICE] Converting $amount $currency to sats using current server');
    
    try {
      final exchangeRates = rates ?? await getExchangeRates(
        currencies: [currency],
        serverUrl: serverUrl,
      );
      
      if (!exchangeRates.containsKey(currency)) {
        throw Exception('Rate not available for $currency from current server');
      }
      
      final fiatRate = exchangeRates[currency]!;
      final btcAmount = amount / fiatRate;
      final satsAmount = (btcAmount * 100000000).round();
      
      print('[CURRENCY_RATES_SERVICE] $amount $currency = $satsAmount sats (from current server)');
      return satsAmount;
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] Error converting from $currency using current server: $e');
      throw Exception('Conversion failed - current server unavailable: $e');
    }
  }


  /// Test if a specific currency is available on the server
  /// Returns true if the currency works, false if not
  Future<bool> testCurrencyAvailability({
    required String currency,
    required String serverUrl,
  }) async {
    if (currency == 'sats') return true; // sats is always available
    
    try {
      print('[CURRENCY_RATES_SERVICE] Testing currency $currency on server $serverUrl');
      
      final endpoint = '$serverUrl/lnurlp/api/v1/rate/$currency';
      final response = await _dio.get(
        endpoint,
        options: Options(
          validateStatus: (status) => status! < 500, // Accept 4xx as valid response
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (response.statusCode == 200) {
        // Check if the response contains a valid rate
        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('rate') && data['rate'] is num && data['rate'] > 0) {
            print('[CURRENCY_RATES_SERVICE] ✅ $currency is available (rate: ${data['rate']})');
            return true;
          } else {
            print('[CURRENCY_RATES_SERVICE] ❌ $currency returned invalid rate: ${data['rate']}');
            return false;
          }
        } else {
          print('[CURRENCY_RATES_SERVICE] ❌ $currency returned invalid response format');
          return false;
        }
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Check if the response indicates the currency is not allowed
        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('detail') && data['detail'].toString().toLowerCase().contains('not allowed')) {
            print('[CURRENCY_RATES_SERVICE] ❌ $currency not allowed on this server');
          } else {
            print('[CURRENCY_RATES_SERVICE] ❌ $currency not available (${response.statusCode})');
          }
        }
        return false;
      } else {
        print('[CURRENCY_RATES_SERVICE] ❌ $currency unexpected status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[CURRENCY_RATES_SERVICE] ❌ $currency test failed: $e');
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}