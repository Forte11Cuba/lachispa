import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ln_address.dart';
import '../services/ln_address_service.dart';
import '../services/lightning_address_resolver.dart';

class LNAddressProvider extends ChangeNotifier {
  final LNAddressService _lnAddressService;
  final LightningAddressResolver _lightningResolver;
  String _serverUrl = '';

  List<LNAddress> _allAddresses = [];
  List<LNAddress> _currentWalletAddresses = [];
  String? _currentWalletId;
  bool _isLoading = false;
  String? _error;
  bool _isCreating = false;
  bool _isDeleting = false;
  
  /// Cache for resolved Lightning Addresses
  final Map<String, String> _lightningCache = {};
  
  /// Cache for isDefault states (walletId -> addressId)
  final Map<String, String> _defaultAddressCache = {};
  
  /// Flag to ensure cache is fully loaded before operations
  bool _cacheLoadCompleted = false;

  LNAddressProvider(this._lnAddressService) 
    : _lightningResolver = LightningAddressResolver() {
    _loadDefaultAddressCache();
  }

  /// Configure current server to determine available features
  void setServerUrl(String serverUrl) {
    if (_serverUrl != serverUrl) {
      _serverUrl = serverUrl;
      _clearServerCache();
      // Update the underlying service URL to ensure consistency
      _lnAddressService.updateBaseUrl(serverUrl);
      print('[LN_ADDRESS_PROVIDER] Server configured: $serverUrl');
    }
  }
  
  /// Smart cache with timestamp for capability checks
  DateTime? _lastCapabilityCheck;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  void _clearServerCache() {
    _cachedCapabilities = null;
    _lastCapabilityCheck = null;
    print('[LN_ADDRESS_PROVIDER] 🧹 Server cache cleared');
  }
  
  bool get _shouldRefreshCapabilities {
    if (_cachedCapabilities == null) return true;
    if (_lastCapabilityCheck == null) return true;
    
    final elapsed = DateTime.now().difference(_lastCapabilityCheck!);
    return elapsed > _cacheValidDuration;
  }
  
  /// Force capability recheck when user reports issues
  void forceCapabilityRecheck() {
    print('[LN_ADDRESS_PROVIDER] 🔄 Forcing new capability verification...');
    _clearServerCache();
  }

  /// Load default address cache from SharedPreferences
  Future<void> _loadDefaultAddressCache() async {
    if (_cacheLoadCompleted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('default_address_'));
      
      for (final key in keys) {
        final walletId = key.replaceFirst('default_address_', '');
        final addressId = prefs.getString(key);
        if (addressId != null) {
          _defaultAddressCache[walletId] = addressId;
        }
      }
      
      _cacheLoadCompleted = true;
      print('[LN_ADDRESS_PROVIDER] Default address cache loaded: ${_defaultAddressCache.length} wallets');
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error loading cache: $e');
    }
  }

  /// Ensure cache is fully loaded before proceeding
  Future<void> _ensureCacheLoaded() async {
    if (!_cacheLoadCompleted) {
      print('[LN_ADDRESS_PROVIDER] 🔄 Waiting for complete cache loading...');
      await _loadDefaultAddressCache();
    }
  }

  /// Save default address for a specific wallet
  Future<void> _saveDefaultAddress(String walletId, String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_address_$walletId', addressId);
      _defaultAddressCache[walletId] = addressId;
      print('[LN_ADDRESS_PROVIDER] Default address saved: $addressId for wallet $walletId');
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error saving default address: $e');
    }
  }

  List<LNAddress> get allAddresses => _allAddresses;
  List<LNAddress> get currentWalletAddresses => _currentWalletAddresses;
  String? get currentWalletId => _currentWalletId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCreating => _isCreating;
  bool get isDeleting => _isDeleting;
  bool get hasAddresses => _currentWalletAddresses.isNotEmpty;
  
  /// Dynamic server capability check for Lightning Address management
  bool get supportsManagement => _cachedCapabilities?['payLinkManagement'] ?? true;
  
  /// Informative message for servers that don't support management
  String? get serverLimitationMessage {
    if (!supportsManagement) {
      final serverName = _getServerDisplayName();
      return '$serverName does not allow managing Lightning Addresses from the app.\n\n'
             'To create Lightning Addresses:\n'
             '• Go to the server web interface\n'
             '• Access the LNURLp extension\n'
             '• Create your Lightning Address\n\n'
             'Chispa can resolve existing Lightning Addresses.';
    }
    return null;
  }
  
  String _getServerDisplayName() {
    if (_serverUrl.contains('btclake.org')) return 'BTC Lake';
    if (_serverUrl.contains('lachispa.me')) return 'LaChispa';
    return 'This server';
  }
  
  /// Get default address for current wallet with fallback to first available
  LNAddress? get defaultAddress {
    final defaultAddr = _currentWalletAddresses.where((addr) => addr.isDefault).firstOrNull;
    if (defaultAddr != null) return defaultAddr;
    
    return _currentWalletAddresses.isNotEmpty ? _currentWalletAddresses.first : null;
  }
  
  /// Get default address for any wallet ID
  LNAddress? getDefaultAddressForWallet(String walletId) {
    final walletAddresses = _allAddresses.where((addr) => addr.walletId == walletId).toList();
    final defaultAddr = walletAddresses.where((addr) => addr.isDefault).firstOrNull;
    if (defaultAddr != null) return defaultAddr;
    
    return walletAddresses.isNotEmpty ? walletAddresses.first : null;
  }

  /// Handle automatic LN Address switching when wallet changes
  Future<void> onWalletChanged(String newWalletId) async {
    if (_currentWalletId == newWalletId) return;
    
    print('[LN_ADDRESS_PROVIDER] Cambio de wallet detectado: $_currentWalletId -> $newWalletId');
    
    await _ensureCacheLoaded();
    
    await setCurrentWallet(newWalletId);
    
    final defaultAddr = getDefaultAddressForWallet(newWalletId);
    
    if (defaultAddr != null) {
      print('[LN_ADDRESS_PROVIDER] LN Address por defecto encontrada: ${defaultAddr.fullAddress} (isDefault: ${defaultAddr.isDefault})');
    } else {
      print('[LN_ADDRESS_PROVIDER] No hay LN Address por defecto para wallet: $newWalletId');
    }
    
    notifyListeners();
  }

  void setAuthHeaders(String invoiceKey, String adminKey) {
    _lnAddressService.setAuthHeaders(invoiceKey, adminKey);
  }

  void setWalletAuth(String adminKey) {
    _lnAddressService.setWalletAuthHeaders(adminKey);
  }

  /// Check server capabilities through actual API testing
  Future<Map<String, bool>> checkServerCapabilities() async {
    final capabilities = {
      'payLinkManagement': false,  // Create/manage pay links
      'lightningResolution': false, // Resolve existing Lightning Addresses
    };

    try {
      print('[LN_ADDRESS_PROVIDER] 🔍 Verifying REAL server capabilities: $_serverUrl');
      
      print('[LN_ADDRESS_PROVIDER] 🧪 Testing pay link management...');
      try {
        capabilities['payLinkManagement'] = await _lnAddressService.checkExtensionAvailability();
        print('[LN_ADDRESS_PROVIDER] ✅ Pay Link Management: ${capabilities['payLinkManagement']}');
      } catch (e) {
        print('[LN_ADDRESS_PROVIDER] ❌ Pay Link Management failed: $e');
        capabilities['payLinkManagement'] = false;
      }
      
      print('[LN_ADDRESS_PROVIDER] 🧪 Testing Lightning Address resolution...');
      try {
        capabilities['lightningResolution'] = await _lightningResolver.isLightningAddressSupported(_serverUrl);
        print('[LN_ADDRESS_PROVIDER] ✅ Lightning Resolution: ${capabilities['lightningResolution']}');
      } catch (e) {
        print('[LN_ADDRESS_PROVIDER] ❌ Lightning Resolution failed: $e');
        capabilities['lightningResolution'] = false;
      }
      
      final serverName = _getServerDisplayName();
      print('[LN_ADDRESS_PROVIDER] 📊 $serverName - PayLinks: ${capabilities['payLinkManagement']}, Resolution: ${capabilities['lightningResolution']}');
      
      return capabilities;
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] ❌ Error verificando capacidades: $e');
      return capabilities;
    }
  }

  /// Cached capabilities to avoid repeated checks
  Map<String, bool>? _cachedCapabilities;
  
  /// Load all Lightning Addresses with smart caching and capability detection
  Future<void> loadAllAddresses() async {
    if (_isLoading) {
      print('[LN_ADDRESS_PROVIDER] Already loading - preventing duplicate');
      return;
    }
    
    _setLoading(true);
    _error = null;

    try {
      print('[LN_ADDRESS_PROVIDER] Verifying server capabilities...');
      
      Map<String, bool> capabilities;
      if (_shouldRefreshCapabilities) {
        print('[LN_ADDRESS_PROVIDER] 🔄 Cache expired, verifying capabilities...');
        capabilities = await checkServerCapabilities();
        _cachedCapabilities = capabilities;
        _lastCapabilityCheck = DateTime.now();
      } else {
        print('[LN_ADDRESS_PROVIDER] ⚡ Using cached capabilities');
        capabilities = _cachedCapabilities!;
      }
      
      if (!capabilities['payLinkManagement']! && !capabilities['lightningResolution']!) {
        _error = 'This server does not support Lightning Addresses. Contact the administrator.';
        print('[LN_ADDRESS_PROVIDER] ❌ Server without Lightning Address support');
        notifyListeners();
        return;
      }
      
      if (!capabilities['payLinkManagement']!) {
        _error = null;
        _allAddresses = [];
        _currentWalletAddresses = [];
        
        final serverName = _getServerDisplayName();
        print('[LN_ADDRESS_PROVIDER] ⚡ $serverName: Support only for Lightning Address resolution');
        print('[LN_ADDRESS_PROVIDER] 💡 To create Lightning Addresses, use the server web interface');
        
        notifyListeners();
        return;
      }
      
      print('[LN_ADDRESS_PROVIDER] ✅ Server supports full management - loading pay links...');
      
      await _ensureCacheLoaded();
      
      _allAddresses = await _lnAddressService.getLNAddresses();
      
      if (_currentWalletId != null) {
        _filterAddressesForWallet(_currentWalletId!);
      }
      
      print('[LN_ADDRESS_PROVIDER] ${_allAddresses.length} Lightning Addresses loaded');
      notifyListeners();
    } catch (e) {
      final serverName = _getServerDisplayName();
      if (e.toString().contains('401')) {
        _error = 'Authentication error in $serverName.\n\n'
                'Possible solutions:\n'
                '• Verify your credentials\n'
                '• Logout and login again\n'
                '• Contact administrator if it persists';
      } else if (e.toString().contains('404')) {
        _error = 'LNURLP extension not found in $serverName.\n\n'
                'The server does not have the extension installed or\n'
                'it is in a different path. Contact the administrator.';
      } else if (e.toString().contains('403')) {
        _error = 'No permissions for Lightning Addresses in $serverName.\n\n'
                'Your account does not have sufficient permissions.\n'
                'Contact the administrator to enable access.';
      } else if (e.toString().contains('500')) {
        _error = 'Internal server error $serverName.\n\n'
                'The LNURLP extension has problems.\n'
                'Try later or contact the administrator.';
      } else if (e.toString().contains('CORS') || e.toString().contains('XMLHttpRequest')) {
        _error = 'Web policy error in $serverName.\n\n'
                'The server blocks requests from browsers.\n'
                'Try using the mobile app instead.';
      } else {
        _error = 'Unexpected error in $serverName:\n${e.toString()}';
        print('[LN_ADDRESS_PROVIDER] 💡 Consider using forceCapabilityRecheck() to retry');
      }
      print('[LN_ADDRESS_PROVIDER] Error loading: $_error');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Set current wallet and filter addresses
  Future<void> setCurrentWallet(String walletId) async {
    print('[LN_ADDRESS_PROVIDER] Cambiando a wallet: $walletId');
    _currentWalletId = walletId;
    
    await _ensureCacheLoaded();
    
    _filterAddressesForWallet(walletId, notify: false);
  }

  /// Filter addresses for wallet and apply isDefault state from cache
  void _filterAddressesForWallet(String walletId, {bool notify = true}) {
    final defaultAddressId = _defaultAddressCache[walletId];
    
    _currentWalletAddresses = _allAddresses
        .where((address) => address.walletId == walletId)
        .map((address) {
          final shouldBeDefault = defaultAddressId == address.id;
          return address.copyWith(isDefault: shouldBeDefault);
        })
        .toList();
    
    if (_currentWalletAddresses.isNotEmpty && defaultAddressId == null) {
      print('[LN_ADDRESS_PROVIDER] 🎯 Auto-assigning first address as default');
      final firstAddress = _currentWalletAddresses.first;
      _saveDefaultAddress(walletId, firstAddress.id).then((_) {
          _filterAddressesForWallet(walletId, notify: true);
      });
    }
    
    print('[LN_ADDRESS_PROVIDER] ${_currentWalletAddresses.length} addresses for wallet $walletId');
    print('[LN_ADDRESS_PROVIDER] Default address from cache: $defaultAddressId');
    
    for (final addr in _currentWalletAddresses) {
      print('[LN_ADDRESS_PROVIDER] - ${addr.fullAddress}: isDefault=${addr.isDefault}');
    }
    
    if (notify) notifyListeners();
  }

  /// Create new Lightning Address with validation
  Future<bool> createLNAddress({
    required String username,
    required String walletId,
    String? description,
    bool zapsEnabled = true,
  }) async {
    _setCreating(true);
    _error = null;

    try {
      print('[LN_ADDRESS_PROVIDER] Creating Lightning Address: $username');
      
      if (!LNAddress.isValidUsername(username)) {
        _error = LNAddress.getUsernameError(username);
        notifyListeners();
        return false;
      }

      final isAvailable = await _lnAddressService.isUsernameAvailable(username, walletId);
      if (!isAvailable) {
        _error = 'Username already exists in this wallet';
        notifyListeners();
        return false;
      }

      final newAddress = await _lnAddressService.createLNAddress(
        username: username,
        walletId: walletId,
        description: description,
        zapsEnabled: zapsEnabled,
      );

      _allAddresses.add(newAddress);
      
      if (walletId == _currentWalletId) {
        _currentWalletAddresses.add(newAddress);
      }

      print('[LN_ADDRESS_PROVIDER] Lightning Address created: ${newAddress.fullAddress}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('[LN_ADDRESS_PROVIDER] Error creando: $_error');
      notifyListeners();
      return false;
    } finally {
      _setCreating(false);
    }
  }

  /// Delete Lightning Address and update local state
  Future<bool> deleteLNAddress(String id) async {
    _setDeleting(true);
    _error = null;

    try {
      print('[LN_ADDRESS_PROVIDER] Deleting Lightning Address: $id');
      
      final success = await _lnAddressService.deleteLNAddress(id);
      
      if (success) {
        _allAddresses.removeWhere((address) => address.id == id);
        _currentWalletAddresses.removeWhere((address) => address.id == id);
        
        print('[LN_ADDRESS_PROVIDER] Lightning Address deleted successfully');
        notifyListeners();
        return true;
      } else {
        _error = 'Error deleting Lightning Address';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('[LN_ADDRESS_PROVIDER] Error deleting: $_error');
      notifyListeners();
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  /// Check username availability for wallet
  Future<bool> checkUsernameAvailability(String username, String walletId) async {
    try {
      if (!LNAddress.isValidUsername(username)) {
        return false;
      }
      
      return await _lnAddressService.isUsernameAvailable(username, walletId);
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error verificando username: $e');
      return false;
    }
  }

  /// Get specific address by ID
  LNAddress? getAddressById(String id) {
    try {
      return _allAddresses.firstWhere((address) => address.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search addresses by username
  List<LNAddress> getAddressesByUsername(String username) {
    return _allAddresses
        .where((address) => 
            address.username.toLowerCase().contains(username.toLowerCase()))
        .toList();
  }

  /// Resolve Lightning Address with caching for QR/sharing
  Future<Map<String, dynamic>?> resolveLightningAddress(String lightningAddress, {String? authToken}) async {
    try {
      print('[LN_ADDRESS_PROVIDER] Resolving Lightning Address: $lightningAddress');
      
      final metadata = await _lightningResolver.resolveLightningAddress(
        lightningAddress, 
        authToken: authToken,
      );
      
      if (metadata != null) {
        print('[LN_ADDRESS_PROVIDER] ✅ Lightning Address resolved successfully');
        print('[LN_ADDRESS_PROVIDER] Callback: ${metadata['callback']}');
        print('[LN_ADDRESS_PROVIDER] MinSendable: ${metadata['minSendable']} msat');
        print('[LN_ADDRESS_PROVIDER] MaxSendable: ${metadata['maxSendable']} msat');
      } else {
        print('[LN_ADDRESS_PROVIDER] ❌ Could not resolve Lightning Address');
      }
      
      return metadata;
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error resolving Lightning Address: $e');
      _error = 'Error resolving Lightning Address: $e';
      notifyListeners();
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
      print('[LN_ADDRESS_PROVIDER] Generating invoice for: $lightningAddress');
      print('[LN_ADDRESS_PROVIDER] Amount: $amountSats sats');
      
      final bolt11 = await _lightningResolver.generateInvoiceFromLightningAddress(
        lightningAddress: lightningAddress,
        amountSats: amountSats,
        comment: comment,
        authToken: authToken,
      );
      
      if (bolt11 != null) {
        print('[LN_ADDRESS_PROVIDER] ✅ Invoice generated successfully');
      } else {
        print('[LN_ADDRESS_PROVIDER] ❌ Could not generate invoice');
        _error = 'Could not generate invoice for Lightning Address';
        notifyListeners();
      }
      
      return bolt11;
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error generating invoice: $e');
      _error = 'Error generating invoice: $e';
      notifyListeners();
      return null;
    }
  }

  /// Validate Lightning Address functionality
  Future<bool> validateLightningAddress(String lightningAddress) async {
    try {
      return await _lightningResolver.validateLightningAddress(lightningAddress);
    } catch (e) {
      print('[LN_ADDRESS_PROVIDER] Error validating Lightning Address: $e');
      return false;
    }
  }

  /// Refresh all addresses
  Future<void> refresh() async {
    await loadAllAddresses();
  }
  
  /// Debug method to manually test server capabilities
  Future<Map<String, dynamic>> debugServerCapabilities() async {
    final result = {
      'server': _serverUrl,
      'serverName': _getServerDisplayName(),
      'timestamp': DateTime.now().toIso8601String(),
      'cached': !_shouldRefreshCapabilities,
      'capabilities': <String, bool>{},
      'errors': <String>[],
    };
    
    try {
      final originalCache = _cachedCapabilities;
      final originalTime = _lastCapabilityCheck;
      
      _clearServerCache();
      final capabilities = await checkServerCapabilities();
      
      result['capabilities'] = capabilities;
      result['success'] = true;
      
      if (originalCache != null && originalTime != null) {
        _cachedCapabilities = originalCache;
        _lastCapabilityCheck = originalTime;
      }
      
    } catch (e) {
      result['success'] = false;
      result['errors'] = [e.toString()];
    }
    
    return result;
  }

  /// Mark address as default for its wallet
  Future<bool> setAsDefault(String addressId) async {
    try {
      print('[LN_ADDRESS_PROVIDER] Marcando como default: $addressId');
      
      final address = _allAddresses.firstWhere((addr) => addr.id == addressId);
      final walletId = address.walletId;
      
      await _saveDefaultAddress(walletId, addressId);
      
      _filterAddressesForWallet(walletId);
      
      print('[LN_ADDRESS_PROVIDER] Lightning Address marked as default: ${address.fullAddress}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error marking as default: $e';
      print('[LN_ADDRESS_PROVIDER] Error marking as default: $_error');
      notifyListeners();
      return false;
    }
  }

  /// Clear current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear Lightning Address resolution cache
  void clearLightningCache() {
    _lightningCache.clear();
    print('[LN_ADDRESS_PROVIDER] Lightning Address cache cleared');
  }

  /// Clear all provider state
  void clear() {
    _allAddresses.clear();
    _currentWalletAddresses.clear();
    _currentWalletId = null;
    _error = null;
    _isLoading = false;
    _isCreating = false;
    _isDeleting = false;
    _lightningCache.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setDeleting(bool deleting) {
    _isDeleting = deleting;
    notifyListeners();
  }

  /// Useful statistics
  int get totalAddressesCount => _allAddresses.length;
  int get currentWalletAddressesCount => _currentWalletAddresses.length;
  
  Map<String, int> get addressesPerWallet {
    final Map<String, int> counts = {};
    for (final address in _allAddresses) {
      counts[address.walletId] = (counts[address.walletId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  void dispose() {
    clear();
    _lightningResolver.dispose();
    super.dispose();
  }
}