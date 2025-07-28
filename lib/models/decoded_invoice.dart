class DecodedInvoice {
  final BigInt amount; // in millisatoshis
  final String description;
  final String paymentHash;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String destination;
  final String originalInvoice;
  
  DecodedInvoice({
    required this.amount,
    required this.description,
    required this.paymentHash,
    required this.createdAt,
    this.expiresAt,
    required this.destination,
    required this.originalInvoice,
  });
  
  factory DecodedInvoice.fromJson(Map<String, dynamic> json, String bolt11) {
    final timestamp = json['timestamp'] ?? json['date'] ?? 0;
    final expiry = json['expiry'] ?? json['expires_at'];
    
    return DecodedInvoice(
      amount: _parseAmount(json),
      description: json['description'] ?? json['memo'] ?? '',
      paymentHash: json['payment_hash'] ?? json['hash'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
      expiresAt: expiry != null 
        ? DateTime.fromMillisecondsSinceEpoch((timestamp + expiry) * 1000)
        : null,
      destination: json['destination'] ?? json['payee'] ?? '',
      originalInvoice: bolt11,
    );
  }
  
  static BigInt _parseAmount(Map<String, dynamic> json) {
    if (json.containsKey('amount_msat')) {
      final value = json['amount_msat'];
      return BigInt.from(value is int ? value : int.tryParse(value.toString()) ?? 0);
    }
    if (json.containsKey('msatoshi')) {
      final value = json['msatoshi'];
      return BigInt.from(value is int ? value : int.tryParse(value.toString()) ?? 0);
    }
    if (json.containsKey('amount')) {
      final amount = json['amount'];
      final amountInt = amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
      if (amountInt < 1000000) {
        return BigInt.from(amountInt * 1000);
      }
      return BigInt.from(amountInt);
    }
    return BigInt.zero;
  }
  
  int get amountSats => (amount ~/ BigInt.from(1000)).toInt();
  String get formattedAmount => '$amountSats sats';
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  Duration? get timeToExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return null;
    return expiresAt!.difference(now);
  }
  
  String get formattedExpiry {
    if (expiresAt == null) return 'No expiration';
    if (isExpired) return 'Expired';
    
    final timeLeft = timeToExpiry!;
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m remaining';
    } else if (timeLeft.inMinutes > 0) {
      return '${timeLeft.inMinutes}m remaining';
    } else {
      return '${timeLeft.inSeconds}s remaining';
    }
  }
  
  String get shortDescription {
    if (description.isEmpty) return 'No description';
    return description.length > 50 
        ? '${description.substring(0, 50)}...'
        : description;
  }
  
  String get shortPaymentHash {
    if (paymentHash.isEmpty) return '';
    return paymentHash.length > 16
        ? '${paymentHash.substring(0, 8)}...${paymentHash.substring(paymentHash.length - 8)}'
        : paymentHash;
  }
}