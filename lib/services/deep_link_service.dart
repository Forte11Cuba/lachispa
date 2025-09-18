import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Callback to handle incoming links
  Function(Uri)? _onLinkReceived;

  /// Initialize deep link handling
  Future<void> initialize({Function(Uri)? onLinkReceived}) async {
    _onLinkReceived = onLinkReceived;
    
    // Handle app launch from deep link (when app is closed)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('[DEEP_LINK] Error getting initial link: $e');
    }

    // Handle app resume from deep link (when app is running/paused)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri);
      },
      onError: (err) {
        print('[DEEP_LINK] Error listening to link stream: $err');
      },
    );
  }

  /// Handle incoming deep link
  void _handleIncomingLink(Uri uri) {
    print('[DEEP_LINK] Received link: $uri');
    
    // Validate if it's a supported scheme
    if (_isSupportedScheme(uri.scheme)) {
      _onLinkReceived?.call(uri);
    } else {
      print('[DEEP_LINK] Unsupported scheme: ${uri.scheme}');
    }
  }

  /// Check if the URI scheme is supported by LaChispa
  bool _isSupportedScheme(String scheme) {
    const supportedSchemes = [
      'bitcoin',
      'lightning', 
      'lnurl',
      'lnurlw',
      'lnurlp',
      'lnurlc',
      'lachispa'
    ];
    return supportedSchemes.contains(scheme.toLowerCase());
  }

  /// Parse Bitcoin URI and extract amount, label, message, etc.
  Map<String, String> parseBitcoinUri(Uri uri) {
    final Map<String, String> params = {};
    
    // Extract address from path
    if (uri.path.isNotEmpty) {
      params['address'] = uri.path;
    }
    
    // Extract query parameters (amount, label, message, etc.)
    uri.queryParameters.forEach((key, value) {
      params[key] = value;
    });
    
    return params;
  }

  /// Parse Lightning invoice/LNURL
  String parseLightningUri(Uri uri) {
    // For lightning: scheme, the invoice is usually in the path
    if (uri.scheme.toLowerCase() == 'lightning') {
      return uri.toString().replaceFirst('lightning:', '');
    }
    
    // For LNURL schemes, return the full URI
    return uri.toString();
  }

  /// Set callback for handling links
  void setOnLinkReceived(Function(Uri) callback) {
    _onLinkReceived = callback;
  }

  /// Store pending payment data for after login
  Future<void> storePendingPayment(String paymentData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_payment_data', paymentData);
      print('[DEEP_LINK] Stored pending payment data: $paymentData');
    } catch (e) {
      print('[DEEP_LINK] Error storing pending payment: $e');
    }
  }

  /// Retrieve and clear pending payment data
  Future<String?> getPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentData = prefs.getString('pending_payment_data');
      print('[DEEP_LINK] Checking pending payment data: $paymentData');
      if (paymentData != null) {
        await prefs.remove('pending_payment_data');
        print('[DEEP_LINK] Retrieved and cleared pending payment data: $paymentData');
      } else {
        print('[DEEP_LINK] No pending payment data found');
      }
      return paymentData;
    } catch (e) {
      print('[DEEP_LINK] Error retrieving pending payment: $e');
      return null;
    }
  }

  /// Check if there's pending payment data
  Future<bool> hasPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('pending_payment_data');
    } catch (e) {
      print('[DEEP_LINK] Error checking pending payment: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}