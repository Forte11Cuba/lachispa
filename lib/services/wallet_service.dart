import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/wallet_info.dart';
import '../models/transaction_info.dart';
import '../core/utils/proxy_config.dart';
import 'app_info_service.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class WalletService {
  final Dio _dio;
  
  WalletService() : _dio = Dio() {
    _configureDio();
  }

  void _configureDio() {
    // Extended timeouts for proxy connections
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['User-Agent'] = AppInfoService.getUserAgent();
    
    ProxyConfig.configureProxy(_dio, enableLogging: false);
    
    if (ProxyConfig.hasSystemProxy()) {
      _debugLog('[WALLET_SERVICE] Using system proxy configuration');
    }
    
    // Security: only log errors, not request/response bodies
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (obj) => print('[WALLET_SERVICE] $obj'),
      ),
    );
  }

  /// Get user wallets - tries multiple endpoints due to LNBits API variations
  Future<List<WalletInfo>> getUserWallets({
    required String serverUrl,
    required String authToken,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      print('[WALLET_SERVICE] Getting user wallets...');
      print('[WALLET_SERVICE] URL: $baseUrl');
      
      // Try different endpoints to get wallets
      final endpoints = [
        '/api/v1/wallets',
        '/api/v1/wallet',
        '/usermanager/api/v1/wallets',
      ];
      
      for (String endpoint in endpoints) {
        try {
          _debugLog('[WALLET_SERVICE] Trying endpoint: $baseUrl$endpoint');
          
          final response = await _dio.get(
            '$baseUrl$endpoint',
            options: Options(
              headers: {
                'Authorization': 'Bearer $authToken',
                'X-Api-Key': authToken,
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            print('[WALLET_SERVICE] Successful response from $endpoint');
            
            // If response is a direct list
            if (response.data is List) {
              final List<dynamic> walletsData = response.data;
              final wallets = walletsData.map((data) {
                return WalletInfo.fromJson(data as Map<String, dynamic>);
              }).toList();
              print('[WALLET_SERVICE] ${wallets.length} wallets found');
              return wallets;
            }
            
            // If response is an object containing wallets
            if (response.data is Map<String, dynamic>) {
              final Map<String, dynamic> responseData = response.data;
              
              // Look for wallets in different fields
              List<dynamic>? walletsData;
              if (responseData.containsKey('wallets')) {
                walletsData = responseData['wallets'] as List<dynamic>?;
              } else if (responseData.containsKey('data')) {
                walletsData = responseData['data'] as List<dynamic>?;
              } else if (responseData.containsKey('items')) {
                walletsData = responseData['items'] as List<dynamic>?;
              }
              
              // If we found wallets
              if (walletsData != null && walletsData.isNotEmpty) {
                final wallets = walletsData.map((data) {
                  return WalletInfo.fromJson(data as Map<String, dynamic>);
                }).toList();
                print('[WALLET_SERVICE] ${wallets.length} wallets found');
                return wallets;
              }
              
              // If response is a single wallet
              if (responseData.containsKey('id') && responseData.containsKey('name')) {
                final wallet = WalletInfo.fromJson(responseData);
                print('[WALLET_SERVICE] 1 wallet found');
                return [wallet];
              }
            }
          }
        } on DioException catch (e) {
          print('[WALLET_SERVICE] Error at $endpoint: ${e.response?.statusCode}');
          
          // If token works as direct adminKey, try specific endpoint
          if (e.response?.statusCode == 401 && authToken.length > 20) {
            try {
              print('[WALLET_SERVICE] Trying to use authToken as adminKey...');
              final directResponse = await _dio.get(
                '$baseUrl/api/v1/wallet',
                options: Options(
                  headers: {'X-Api-Key': authToken},
                ),
              );
              
              if (directResponse.statusCode == 200 && directResponse.data != null) {
                print('[WALLET_SERVICE] AuthToken works as adminKey');
                final walletData = directResponse.data as Map<String, dynamic>;
                final wallet = WalletInfo.fromJson(walletData);
                print('[WALLET_SERVICE] 1 wallet found using adminKey');
                return [wallet];
              }
            } catch (directError) {
              print('[WALLET_SERVICE] AuthToken does not work as adminKey');
            }
          }
          continue;
        }
      }

      throw WalletException('Could not get wallets from server');
    } on DioException catch (e) {
      print('[WALLET_SERVICE] Error getting wallets: ${e.message}');
      throw WalletException('Error getting wallets: ${_handleDioError(e)}');
    } catch (e) {
      print('[WALLET_SERVICE] Unexpected error: $e');
      throw WalletException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get balance of a specific wallet
  Future<WalletBalance> getWalletBalance({
    required String serverUrl,
    required String walletId,
    required String adminKey,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      print('[WALLET_SERVICE] Getting wallet balance: $walletId');

      final response = await _dio.get(
        '$baseUrl/api/v1/wallet',
        options: Options(
          headers: {'X-Api-Key': adminKey},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final balance = WalletBalance.fromJson(response.data as Map<String, dynamic>);
        print('[WALLET_SERVICE] Balance retrieved: ${balance.balanceFormatted}');
        return balance;
      }

      throw WalletException('Unexpected server response');
    } on DioException catch (e) {
      print('[WALLET_SERVICE] Error getting balance: ${e.message}');
      throw WalletException('Error getting balance: ${_handleDioError(e)}');
    } catch (e) {
      print('[WALLET_SERVICE] Unexpected error: $e');
      throw WalletException('Unexpected error: ${e.toString()}');
    }
  }

  /// Create new wallet (requires special permissions on LNBits instance)
  Future<WalletInfo> createWallet({
    required String serverUrl,
    required String authToken,
    required String walletName,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      print('[WALLET_SERVICE] Creating wallet: $walletName');

      final response = await _dio.post(
        '$baseUrl/usermanager/api/v1/wallets',
        data: {
          'wallet_name': walletName,
        },
        options: Options(
          headers: {
            'X-Api-Key': authToken.replaceFirst('Bearer ', ''),
            'Content-Type': 'application/json',
          },
        ),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) && response.data != null) {
        print('[WALLET_SERVICE] Wallet created successfully: $walletName');
        
        final responseData = response.data as Map<String, dynamic>;
        
        // Different response formats
        if (responseData.containsKey('id')) {
          return WalletInfo.fromJson(responseData);
        } else if (responseData.containsKey('wallet')) {
          return WalletInfo.fromJson(responseData['wallet'] as Map<String, dynamic>);
        } else if (responseData.containsKey('wallets') && 
                   responseData['wallets'] is List && 
                   (responseData['wallets'] as List).isNotEmpty) {
          final walletsData = responseData['wallets'] as List;
          return WalletInfo.fromJson(walletsData.first as Map<String, dynamic>);
        }
        
        throw WalletException('Server response does not contain valid information');
      }

      throw WalletException('Error in server response');
    } on DioException catch (e) {
      print('[WALLET_SERVICE] Error creating wallet: ${e.response?.statusCode}');
      
      if (e.response?.statusCode == 405) {
        throw WalletException('Wallet creation is not available on this instance');
      } else if (e.response?.statusCode == 403) {
        throw WalletException('You do not have permissions to create wallets');
      }
      
      throw WalletException('Error creating wallet: ${_handleDioError(e)}');
    } catch (e) {
      print('[WALLET_SERVICE] Unexpected error: $e');
      throw WalletException('Unexpected error: ${e.toString()}');
    }
  }

  /// Delete wallet (requires special permissions)
  Future<void> deleteWallet({
    required String serverUrl,
    required String walletId,
    required String adminKey,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      final response = await _dio.delete(
        '$baseUrl/api/v1/wallet',
        options: Options(
          headers: {'X-Api-Key': adminKey},
        ),
      );

      if (response.statusCode == 200) {
        print('[WALLET_SERVICE] Wallet deleted successfully');
        return;
      }

      throw WalletException('Error deleting wallet');
    } on DioException catch (e) {
      print('[WALLET_SERVICE] Error deleting wallet: ${e.message}');
      throw WalletException('Error deleting wallet: ${_handleDioError(e)}');
    } catch (e) {
      print('[WALLET_SERVICE] Unexpected error: $e');
      throw WalletException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get transaction history of a wallet
  Future<List<TransactionInfo>> getWalletTransactions({
    required String serverUrl,
    required String walletId,
    required String adminKey,
    int? limit,
    int? offset,
  }) async {
    try {
      String baseUrl = serverUrl;
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'https://$baseUrl';
      }

      print('[WALLET_SERVICE] Getting wallet transactions: $walletId');

      // Possible endpoints to get transactions
      final endpoints = [
        '/api/v1/payments',
        '/api/v1/wallet/payments',
        '/api/v1/transactions',
      ];

      for (final endpoint in endpoints) {
        try {
          final Map<String, dynamic> queryParams = {};
          if (limit != null) queryParams['limit'] = limit.toString();
          if (offset != null) queryParams['offset'] = offset.toString();

          _debugLog('[WALLET_SERVICE] Trying endpoint: $baseUrl$endpoint');

          final response = await _dio.get(
            '$baseUrl$endpoint',
            queryParameters: queryParams,
            options: Options(
              headers: {'X-Api-Key': adminKey},
            ),
          );


          if (response.statusCode == 200 && response.data != null) {
            print('[WALLET_SERVICE] Successful response from $endpoint');
            
            final responseData = response.data;
            List<TransactionInfo> transactions = [];

            if (responseData is List) {
              // Response is a list of transactions
              for (var item in responseData) {
                if (item is Map<String, dynamic>) {
                  try {
                    final transaction = TransactionInfo.fromJson(item);
                    transactions.add(transaction);
                  } catch (e) {
                    print('[WALLET_SERVICE] Error parsing transaction: $e');
                  }
                }
              }
            } else if (responseData is Map<String, dynamic>) {
              // Response contains a list of transactions
              if (responseData.containsKey('payments')) {
                final payments = responseData['payments'] as List?;
                if (payments != null) {
                  for (var item in payments) {
                    if (item is Map<String, dynamic>) {
                      try {
                        final transaction = TransactionInfo.fromJson(item);
                        transactions.add(transaction);
                      } catch (e) {
                        print('[WALLET_SERVICE] Error parsing transaction: $e');
                      }
                    }
                  }
                }
              }
            }

            print('[WALLET_SERVICE] ${transactions.length} transactions found');
            
            // Sort by date (most recent first)
            transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            return transactions;
          }
        } on DioException catch (e) {
          print('[WALLET_SERVICE] Error at $endpoint: ${e.response?.statusCode}');
          continue;
        }
      }

      // If no transactions found, return empty list
      print('[WALLET_SERVICE] No transactions found');
      return [];
      
    } on DioException catch (e) {
      print('[WALLET_SERVICE] Error getting transactions: ${e.message}');
      throw WalletException('Error getting transactions: ${_handleDioError(e)}');
    } catch (e) {
      print('[WALLET_SERVICE] Unexpected error: $e');
      throw WalletException('Unexpected error: ${e.toString()}');
    }
  }

  /// Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout';
      
      case DioExceptionType.connectionError:
        return 'Connection error. Check your internet';
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'Unauthorized - check your token';
        } else if (statusCode == 403) {
          return 'Forbidden - insufficient permissions';
        } else if (statusCode == 404) {
          return 'Resource not found';
        } else if (statusCode == 500) {
          return 'Internal server error';
        } else {
          return 'Server error ($statusCode)';
        }
      
      default:
        return e.message ?? 'Unknown error';
    }
  }
}