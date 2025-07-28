import 'package:flutter/foundation.dart';
import 'lightning_address_service.dart';

/// Conditional logging for development
void _debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
}

/// Service dedicated exclusively to resolving existing Lightning Addresses
/// Uses the LightningAddressService that works on all LNBits servers
class LightningAddressResolver {
  final LightningAddressService _lightningService;
  
  // Cache for server capabilities
  static final Map<String, bool> _serverCapabilityCache = {};
  
  LightningAddressResolver() : _lightningService = LightningAddressService();

  /// Check if Lightning Address resolution is available
  /// This method does NOT check pay link management, only resolution
  Future<bool> isLightningAddressSupported(String serverUrl) async {
    try {
      // Check cache first
      if (_serverCapabilityCache.containsKey(serverUrl)) {
        final cached = _serverCapabilityCache[serverUrl]!;
        _debugLog('[LIGHTNING_RESOLVER] Using cached result for $serverUrl: $cached');
        return cached;
      }
      
      _debugLog('[LIGHTNING_RESOLVER] Checking Lightning Address support on: $serverUrl');
      
      // Extract server domain
      final domain = serverUrl.replaceAll('https://', '').replaceAll('http://', '');
      bool isSupported = false;
      
      // Optimized verification for known servers
      if (domain.contains('lnbits.btclake.org')) {
        // BTC Lake - we know it supports resolution
        _debugLog('[LIGHTNING_RESOLVER] ✅ BTC Lake: Support confirmed (known)');
        isSupported = true;
      } else if (domain.contains('lachispa.me')) {
        // LaChispa - we know it supports resolution  
        _debugLog('[LIGHTNING_RESOLVER] ✅ LaChispa: Support confirmed (known)');
        isSupported = true;
      } else {
        // Unknown server - assume support (most LNBits support it)
        _debugLog('[LIGHTNING_RESOLVER] ⚠️ Unknown server, assuming basic support');
        isSupported = true;
      }
      
      // Save in cache
      _serverCapabilityCache[serverUrl] = isSupported;
      return isSupported;
    } catch (e) {
      _debugLog('[LIGHTNING_RESOLVER] Error verifying support: $e');
      // In case of error, assume it does NOT support
      _serverCapabilityCache[serverUrl] = false;
      return false;
    }
  }

  /// Resolve a specific Lightning Address
  Future<Map<String, dynamic>?> resolveLightningAddress(String lightningAddress, {String? authToken}) async {
    try {
      _debugLog('[LIGHTNING_RESOLVER] Resolving: $lightningAddress');
      
      final metadata = await _lightningService.resolveLightningAddress(
        lightningAddress,
        authToken: authToken,
      );
      
      _debugLog('[LIGHTNING_RESOLVER] ✅ Lightning Address resolved successfully');
      return metadata;
    } catch (e) {
      _debugLog('[LIGHTNING_RESOLVER] ❌ Error resolving Lightning Address: $e');
      return null;
    }
  }

  /// Generate invoice from Lightning Address
  Future<String?> generateInvoiceFromLightningAddress({
    required String lightningAddress,
    required int amountSats,
    String? comment,
    String? authToken,
  }) async {
    try {
      _debugLog('[LIGHTNING_RESOLVER] Generating invoice for: $lightningAddress');
      _debugLog('[LIGHTNING_RESOLVER] Amount: $amountSats sats');
      
      final bolt11 = await _lightningService.processLightningAddressPayment(
        lightningAddress: lightningAddress,
        amountSats: amountSats,
        comment: comment,
        authToken: authToken,
      );
      
      _debugLog('[LIGHTNING_RESOLVER] ✅ Invoice generated successfully');
      return bolt11;
    } catch (e) {
      _debugLog('[LIGHTNING_RESOLVER] ❌ Error generating invoice: $e');
      return null;
    }
  }

  /// Verify that a Lightning Address is valid and responds
  Future<bool> validateLightningAddress(String lightningAddress) async {
    try {
      final metadata = await resolveLightningAddress(lightningAddress);
      return metadata != null && 
             metadata.containsKey('callback') && 
             metadata.containsKey('minSendable') && 
             metadata.containsKey('maxSendable');
    } catch (e) {
      _debugLog('[LIGHTNING_RESOLVER] Invalid Lightning Address: $e');
      return false;
    }
  }

  void dispose() {
    _lightningService.dispose();
  }
}