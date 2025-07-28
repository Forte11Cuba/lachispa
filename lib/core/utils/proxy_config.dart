import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Utility for configuring automatic proxy support in HTTP clients
class ProxyConfig {
  
  /// Configure automatic proxy support for a Dio client
  static void configureProxy(Dio dio, {bool enableLogging = false}) {
    // Only configure proxy on native platforms (not Web)
    if (kIsWeb) {
      if (enableLogging && kDebugMode) {
        _debugLog('[PROXY_CONFIG] Web platform - using browser proxy automatically');
      }
      return;
    }

    try {
      // Configure HttpClientAdapter for proxy support
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        
        // 1. Automatic system proxy detection
        client.findProxy = (url) {
          try {
            // Use system proxy configuration
            final proxy = HttpClient.findProxyFromEnvironment(url, environment: Platform.environment);
            
            if (enableLogging && proxy != 'DIRECT') {
              _debugLog('[PROXY_CONFIG] Proxy detected for $url: $proxy');
            }
            
            return proxy;
          } catch (e) {
            if (enableLogging) {
              _debugLog('[PROXY_CONFIG] Error detecting proxy for $url: $e');
            }
            return 'DIRECT';
          }
        };
        
        // 2. Configure timeouts to avoid hangs on slow proxies
        client.connectionTimeout = const Duration(seconds: 15);
        client.idleTimeout = const Duration(seconds: 30);
        
        // 3. Configure proxy authentication if available
        client.addProxyCredentials(
          _extractProxyHost(Platform.environment['HTTP_PROXY'] ?? ''),
          _extractProxyPort(Platform.environment['HTTP_PROXY'] ?? ''),
          '',  // realm (usually empty)
          HttpClientBasicCredentials(
            _extractProxyUser(Platform.environment['HTTP_PROXY'] ?? ''),
            _extractProxyPassword(Platform.environment['HTTP_PROXY'] ?? ''),
          ),
        );
        
        // 4. Configure certificate verification
        client.badCertificateCallback = (cert, host, port) {
          // In corporate environments, sometimes it's necessary to accept proxy certificates
          if (enableLogging) {
            _debugLog('[PROXY_CONFIG] Verifying certificate for $host:$port');
          }
          // For security, only accept in debug mode
          return kDebugMode;
        };
        
        if (enableLogging) {
          _logProxyEnvironment();
        }
        
        return client;
      };
      
      if (enableLogging) {
        _debugLog('[PROXY_CONFIG] Proxy support configured successfully');
      }
      
    } catch (e) {
      if (enableLogging) {
        _debugLog('[PROXY_CONFIG] Error configuring proxy: $e');
      }
      // Don't fail if there's an error configuring proxy - use direct connection
    }
  }
  
  /// Configure proxy with specific manual configuration
  static void configureManualProxy(
    Dio dio, 
    String proxyHost, 
    int proxyPort, {
    String? username,
    String? password,
    bool enableLogging = false,
  }) {
    if (kIsWeb) {
      if (enableLogging && kDebugMode) {
        _debugLog('[PROXY_CONFIG] Manual proxy not supported on Web');
      }
      return;
    }

    try {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        
        client.findProxy = (url) {
          final proxy = 'PROXY $proxyHost:$proxyPort';
          if (enableLogging) {
            _debugLog('[PROXY_CONFIG] Using manual proxy: $proxy');
          }
          return proxy;
        };
        
        // Configure credentials if provided
        if (username != null && password != null) {
          client.addProxyCredentials(
            proxyHost,
            proxyPort,
            '',
            HttpClientBasicCredentials(username, password),
          );
        }
        
        client.connectionTimeout = const Duration(seconds: 15);
        client.badCertificateCallback = (cert, host, port) => kDebugMode;
        
        return client;
      };
      
      if (enableLogging) {
        _debugLog('[PROXY_CONFIG] Manual proxy configured: $proxyHost:$proxyPort');
      }
      
    } catch (e) {
      if (enableLogging) {
        _debugLog('[PROXY_CONFIG] Error configuring manual proxy: $e');
      }
    }
  }
  
  /// Check if there's proxy configuration in the system
  static bool hasSystemProxy() {
    if (kIsWeb) return false;
    
    final env = Platform.environment;
    return env.containsKey('HTTP_PROXY') || 
           env.containsKey('HTTPS_PROXY') || 
           env.containsKey('http_proxy') || 
           env.containsKey('https_proxy');
  }
  
  /// Get system proxy information for debugging
  static Map<String, String?> getSystemProxyInfo() {
    if (kIsWeb) return {'platform': 'web'};
    
    final env = Platform.environment;
    return {
      'HTTP_PROXY': env['HTTP_PROXY'],
      'HTTPS_PROXY': env['HTTPS_PROXY'],
      'http_proxy': env['http_proxy'],
      'https_proxy': env['https_proxy'],
      'NO_PROXY': env['NO_PROXY'],
      'no_proxy': env['no_proxy'],
    };
  }
  
  // Private utility methods
  
  static String _extractProxyHost(String proxyUrl) {
    if (proxyUrl.isEmpty) return '';
    try {
      final uri = Uri.parse(proxyUrl.startsWith('http') ? proxyUrl : 'http://$proxyUrl');
      return uri.host;
    } catch (e) {
      return '';
    }
  }
  
  static int _extractProxyPort(String proxyUrl) {
    if (proxyUrl.isEmpty) return 8080;
    try {
      final uri = Uri.parse(proxyUrl.startsWith('http') ? proxyUrl : 'http://$proxyUrl');
      return uri.port;
    } catch (e) {
      return 8080;
    }
  }
  
  static String _extractProxyUser(String proxyUrl) {
    if (proxyUrl.isEmpty) return '';
    try {
      final uri = Uri.parse(proxyUrl.startsWith('http') ? proxyUrl : 'http://$proxyUrl');
      return uri.userInfo.split(':').first;
    } catch (e) {
      return '';
    }
  }
  
  static String _extractProxyPassword(String proxyUrl) {
    if (proxyUrl.isEmpty) return '';
    try {
      final uri = Uri.parse(proxyUrl.startsWith('http') ? proxyUrl : 'http://$proxyUrl');
      final userInfo = uri.userInfo.split(':');
      return userInfo.length > 1 ? userInfo[1] : '';
    } catch (e) {
      return '';
    }
  }
  
  static void _logProxyEnvironment() {
    final proxyInfo = getSystemProxyInfo();
    _debugLog('[PROXY_CONFIG] === System Proxy Configuration ===');
    proxyInfo.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        // Hide passwords in logs
        final safeValue = key.toLowerCase().contains('proxy') 
            ? _obscureProxyCredentials(value)
            : value;
        _debugLog('[PROXY_CONFIG] $key: $safeValue');
      }
    });
    _debugLog('[PROXY_CONFIG] =======================================');
  }
  
  static String _obscureProxyCredentials(String proxyUrl) {
    try {
      final uri = Uri.parse(proxyUrl.startsWith('http') ? proxyUrl : 'http://$proxyUrl');
      if (uri.userInfo.isNotEmpty) {
        return '${uri.scheme}://***:***@${uri.host}:${uri.port}';
      }
      return proxyUrl;
    } catch (e) {
      return proxyUrl;
    }
  }
}