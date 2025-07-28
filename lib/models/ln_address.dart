class LNAddress {
  final String id;
  final String username;
  final String walletId;
  final String description;
  final String fullAddress;
  final String? lnurl;
  final bool isActive;
  final int minAmount;
  final int maxAmount;
  final int commentChars;
  final bool zapsEnabled;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LNAddress({
    required this.id,
    required this.username,
    required this.walletId,
    required this.description,
    required this.fullAddress,
    this.lnurl,
    required this.isActive,
    required this.minAmount,
    required this.maxAmount,
    required this.commentChars,
    required this.zapsEnabled,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
  });

  factory LNAddress.fromJson(Map<String, dynamic> json, String serverUrl) {
    final domain = serverUrl.replaceAll('https://', '').replaceAll('http://', '');
    
    return LNAddress(
      id: json['id'],
      username: json['username'] ?? '',
      walletId: json['wallet'] ?? '',
      description: json['description'] ?? '',
      fullAddress: '${json['username'] ?? ''}@$domain',
      lnurl: json['lnurl'],
      isActive: json['success_action'] != null,
      minAmount: _toInt(json['min'], 1),
      maxAmount: _toInt(json['max'], 50000000000),
      commentChars: _toInt(json['comment_chars'], 500),
      zapsEnabled: json['zaps'] ?? true,
      isDefault: false,
      createdAt: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  static int _toInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'wallet': walletId,
      'description': description,
      'min': minAmount,
      'max': maxAmount,
      'comment_chars': commentChars,
      'zaps': zapsEnabled,
      'is_default': isDefault,
      'time': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LNAddress copyWith({
    String? id,
    String? username,
    String? walletId,
    String? description,
    String? fullAddress,
    String? lnurl,
    bool? isActive,
    int? minAmount,
    int? maxAmount,
    int? commentChars,
    bool? zapsEnabled,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LNAddress(
      id: id ?? this.id,
      username: username ?? this.username,
      walletId: walletId ?? this.walletId,
      description: description ?? this.description,
      fullAddress: fullAddress ?? this.fullAddress,
      lnurl: lnurl ?? this.lnurl,
      isActive: isActive ?? this.isActive,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      commentChars: commentChars ?? this.commentChars,
      zapsEnabled: zapsEnabled ?? this.zapsEnabled,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create payload for new LNAddress with LNURLP API
  static Map<String, dynamic> createPayload({
    required String username,
    required String walletId, // Only for logging, not sent to API
    required String description,
    int amount = 0,
    int minAmount = 1,
    int maxAmount = 2100000000,
    int commentChars = 500,
    String? successUrl,
    String? webhookHeaders,
    String? webhookBody,
  }) {
    final payload = <String, dynamic>{
      'description': description,
      'amount': amount,
      'max': maxAmount,
      'min': minAmount,
      'comment_chars': commentChars,
      'username': username,
    };
    
    if (successUrl != null && successUrl.startsWith('https://')) {
      payload['success_url'] = successUrl;
    }
    
    if (webhookHeaders != null) {
      payload['webhook_headers'] = webhookHeaders;
    }
    
    if (webhookBody != null) {
      payload['webhook_body'] = webhookBody;
    }
    
    return payload;
  }

  // Validate username according to LNURLP API
  static bool isValidUsername(String username) {
    if (username.isEmpty || username.length > 210) {
      return false;
    }
    final RegExp regex = RegExp(r'^[a-z0-9\-_.]{1,210}$');
    return regex.hasMatch(username);
  }

  // Get username validation error message
  static String getUsernameError(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length > 210) {
      return 'Maximum 210 characters';
    }
    final RegExp regex = RegExp(r'^[a-z0-9\-_.]{1,210}$');
    if (!regex.hasMatch(username)) {
      return 'Only lowercase letters, numbers, hyphens (-), dots (.) and underscores (_) allowed';
    }
    return '';
  }

  @override
  String toString() {
    return 'LNAddress{id: $id, username: $username, fullAddress: $fullAddress, wallet: $walletId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LNAddress &&
        other.id == id &&
        other.username == username &&
        other.walletId == walletId;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ walletId.hashCode;
}