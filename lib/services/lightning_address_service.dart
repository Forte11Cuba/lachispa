import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/proxy_config.dart';
import 'app_info_service.dart';

/// Conditional logging for development
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class LightningAddressService {
  final Dio _dio;

  LightningAddressService() : _dio = Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
    
    // Configure automatic proxy support
    ProxyConfig.configureProxy(_dio, enableLogging: false);
    
    // Log proxy information if available
    if (ProxyConfig.hasSystemProxy()) {
      _debugLog('[LN_ADDRESS_SERVICE] Using system proxy configuration');
    }
    
    // Interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
      error: true,
      logPrint: (obj) => _debugLog('[LIGHTNING_ADDRESS_SERVICE] $obj'),
    ));
  }

  /// Resolves a Lightning Address (user@domain.com) to LNURL-pay metadata
  /// 
  /// [lightningAddress] - Lightning Address to resolve (e.g., satoshi@lnbits.com)
  /// [authToken] - Optional authentication token for servers that require it
  /// 
  /// Returns a Map with LNURL-pay metadata:
  /// - callback: URL to generate invoice
  /// - minSendable: Minimum amount in millisats
  /// - maxSendable: Maximum amount in millisats
  /// - metadata: Recipient metadata
  /// - tag: Always "payRequest" for LNURL-pay
  Future<Map<String, dynamic>> resolveLightningAddress(String lightningAddress, {String? authToken}) async {
    try {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Resolving Lightning Address: $lightningAddress');
      
      // Validate Lightning Address format
      if (!_isValidLightningAddress(lightningAddress)) {
        throw Exception('Invalid Lightning Address format');
      }
      
      // Separate user and domain
      final parts = lightningAddress.split('@');
      final username = parts[0];
      final domain = parts[1];
      
      // Try multiple Lightning Address resolution formats
      final urls = [
        'https://$domain/lnurlp/api/v1/well-known/$username', // LNBits format (BTC Lake works)
        'https://$domain/.well-known/lnurlpay/$username',  // LUD-16 standard
        'https://$domain/.well-known/lnaddress/$username', // Alternative format
        'https://$domain/.well-known/lightning/$username',    // Legacy format
      ];
      
      Map<String, dynamic>? data;
      String? successUrl;
      
      for (final url in urls) {
        try {
          _debugLog('[LIGHTNING_ADDRESS_SERVICE] Trying URL: $url');
          
          // Prepare headers with authentication if available
          final options = Options();
          if (authToken != null && authToken.isNotEmpty) {
            options.headers = {
              'Authorization': 'Bearer $authToken',
              'X-API-KEY': authToken,  // Some LNBits servers use this header
            };
            _debugLog('[LIGHTNING_ADDRESS_SERVICE] Using authentication');
          }
          
          final response = await _dio.get(url, options: options);
          
          if (response.statusCode == 200 && response.data is Map) {
            final responseData = response.data as Map<String, dynamic>;
            
            // Check if it's a valid LNURL-pay response
            if (_isValidLNURLPayResponse(responseData)) {
              data = responseData;
              successUrl = url;
              _debugLog('[LIGHTNING_ADDRESS_SERVICE] ✅ Successful resolution with: $url');
              break;
            } else {
              _debugLog('[LIGHTNING_ADDRESS_SERVICE] ❌ Invalid response from: $url');
            }
          }
        } catch (e) {
          _debugLog('[LIGHTNING_ADDRESS_SERVICE] ❌ Error with $url: ${e.toString().substring(0, 100)}...');
          continue; // Try next URL
        }
      }
      
      if (data == null || successUrl == null) {
        throw Exception('Lightning Address not found in any standard format');
      }
      
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Metadata obtained from $successUrl: $data');
      
      return data;
    } on DioException catch (e) {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] DioException: ${e.type}');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Error: ${e.message}');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('Lightning Address not found. Verify that $lightningAddress exists.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid Lightning Address: ${e.response?.data}');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Timeout connecting to server. Check your connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout receiving response from server.');
      } else {
        throw Exception('Connection error resolving Lightning Address: ${e.message}');
      }
    } catch (e) {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Error general: $e');
      throw Exception('Unexpected error resolving Lightning Address: $e');
    }
  }

  /// Generates a Lightning invoice using the LNURL-pay callback
  /// 
  /// [callbackUrl] - Callback URL obtained from resolveLightningAddress
  /// [amountMsat] - Amount in millisatoshis
  /// [comment] - Optional comment
  /// 
  /// Returns a Map with:
  /// - pr: The Lightning invoice (BOLT11)
  /// - successAction: Action to perform after payment (optional)
  Future<Map<String, dynamic>> generateInvoiceFromCallback({
    required String callbackUrl,
    required int amountMsat,
    String? comment,
  }) async {
    try {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Generating invoice from callback');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] URL: $callbackUrl');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Amount: $amountMsat msat');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Comment: ${comment ?? "none"}');
      
      // Build parameters for the callback
      final params = <String, String>{
        'amount': amountMsat.toString(),
      };
      
      // Add comment if present
      if (comment != null && comment.isNotEmpty) {
        params['comment'] = comment;
      }
      
      // Make GET request to callback with parameters
      final response = await _dio.get(
        callbackUrl,
        queryParameters: params,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        _debugLog('[LIGHTNING_ADDRESS_SERVICE] Invoice generated: ${data['pr']?.substring(0, 20)}...');
        
        // Validate that the response contains an invoice
        if (!_isValidInvoiceResponse(data)) {
          throw Exception('Invalid invoice response from server');
        }
        
        return data;
      } else {
        throw Exception('Server error generating invoice: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] DioException generando invoice: ${e.type}');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Error: ${e.message}');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid parameters: ${e.response?.data}');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Amount outside allowed range');
      } else {
        throw Exception('Error generating invoice: ${e.message}');
      }
    } catch (e) {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Error general generando invoice: $e');
      throw Exception('Unexpected error generating invoice: $e');
    }
  }

  /// Processes a complete payment to Lightning Address
  /// 
  /// [lightningAddress] - Target Lightning Address
  /// [amountSats] - Amount in satoshis
  /// [comment] - Optional comment
  /// [authToken] - Optional authentication token
  /// 
  /// Returns the generated BOLT11 invoice ready to pay
  Future<String> processLightningAddressPayment({
    required String lightningAddress,
    required int amountSats,
    String? comment,
    String? authToken,
  }) async {
    try {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Processing payment to Lightning Address: $lightningAddress');
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Amount: $amountSats sats');
      
      // Step 1: Resolve Lightning Address to LNURL-pay metadata
      final metadata = await resolveLightningAddress(lightningAddress, authToken: authToken);
      
      // Step 2: Validate that amount is within allowed range
      final minSendable = metadata['minSendable'] as int;
      final maxSendable = metadata['maxSendable'] as int;
      final amountMsat = amountSats * 1000; // Convert sats to msats
      
      if (amountMsat < minSendable) {
        throw Exception('Minimum amount: ${minSendable ~/ 1000} sats');
      }
      
      if (amountMsat > maxSendable) {
        throw Exception('Maximum amount: ${maxSendable ~/ 1000} sats');
      }
      
      // Step 3: Validate comment length if present
      if (comment != null && comment.isNotEmpty) {
        final commentChars = metadata['commentAllowed'] as int? ?? 0;
        if (comment.length > commentChars) {
          throw Exception('Comment maximum: $commentChars characters');
        }
      }
      
      // Step 4: Generate invoice using the callback
      final callbackUrl = metadata['callback'] as String;
      final invoiceData = await generateInvoiceFromCallback(
        callbackUrl: callbackUrl,
        amountMsat: amountMsat,
        comment: comment,
      );
      
      // Step 5: Extract the BOLT11 invoice
      final bolt11 = invoiceData['pr'] as String;
      
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Invoice generated successfully');
      return bolt11;
    } catch (e) {
      _debugLog('[LIGHTNING_ADDRESS_SERVICE] Error procesando pago: $e');
      rethrow; // Re-throw the error for calling code to handle
    }
  }

  /// Validates Lightning Address format
  bool _isValidLightningAddress(String address) {
    // Must have exactly one @ and valid format
    final parts = address.split('@');
    if (parts.length != 2) return false;
    
    final username = parts[0];
    final domain = parts[1];
    
    // Username cannot be empty and must have valid characters
    if (username.isEmpty || username.length > 64) return false;
    
    // Domain must be a valid domain
    if (domain.isEmpty || !domain.contains('.')) return false;
    
    return true;
  }

  /// Validates that a response is a valid LNURL-pay
  bool _isValidLNURLPayResponse(Map<String, dynamic> data) {
    return data.containsKey('callback') &&
           data.containsKey('minSendable') &&
           data.containsKey('maxSendable') &&
           data.containsKey('tag') &&
           data['tag'] == 'payRequest';
  }

  /// Validates that a response contains a valid invoice
  bool _isValidInvoiceResponse(Map<String, dynamic> data) {
    return data.containsKey('pr') && 
           data['pr'] is String && 
           (data['pr'] as String).toLowerCase().startsWith('ln');
  }

  void dispose() {
    _dio.close();
  }
}