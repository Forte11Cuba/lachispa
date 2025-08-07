import 'package:flutter/foundation.dart';

/// Lightning transaction information
class TransactionInfo {
  final String id;
  final String walletId;
  final int amount; // In millisats
  final String memo;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final String? paymentHash;
  final String? invoice;
  final int? fee;
  final String? description;

  TransactionInfo({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.memo,
    required this.timestamp,
    required this.type,
    required this.status,
    this.paymentHash,
    this.invoice,
    this.fee,
    this.description,
  });

  int get amountSats => amount ~/ 1000;
  String get amountFormatted => '${amountSats.abs()} sats';
  String get displayAmount => type == TransactionType.incoming ? '+$amountFormatted' : '-$amountFormatted';
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isIncoming => type == TransactionType.incoming;
  bool get isOutgoing => type == TransactionType.outgoing;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Create from LNBits JSON
  factory TransactionInfo.fromJson(Map<String, dynamic> json) {
    try {
      final amount = json['amount'] as int;
      final type = amount > 0 ? TransactionType.incoming : TransactionType.outgoing;
      
      DateTime timestamp;
      if (json['time'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000);
      } else if (json['time'] is String) {
        timestamp = DateTime.tryParse(json['time']) ?? DateTime.now();
      } else {
        timestamp = DateTime.now();
      }
      
      // Determinar status
      TransactionStatus status = TransactionStatus.completed;
      
      // Check both 'pending' boolean field and 'status' string field
      if (json['pending'] == true || json['status'] == 'pending') {
        status = TransactionStatus.pending;
      } else if (json['failed'] == true || json['status'] == 'failed') {
        status = TransactionStatus.failed;
      }

      return TransactionInfo(
        id: json['payment_hash']?.toString() ?? json['id']?.toString() ?? '',
        walletId: json['wallet_id']?.toString() ?? '',
        amount: amount,
        memo: json['memo']?.toString() ?? json['description']?.toString() ?? 'No description',
        timestamp: timestamp,
        type: type,
        status: status,
        paymentHash: json['payment_hash']?.toString(),
        invoice: json['bolt11']?.toString(),
        fee: json['fee']?.toInt(),
        description: json['description']?.toString(),
      );
    } catch (e) {
      print('[TRANSACTION_INFO] Error parsing JSON: $e');
      throw Exception('Error parsing transaction: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'amount': amount,
      'memo': memo,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'payment_hash': paymentHash,
      'bolt11': invoice,
      'fee': fee,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'TransactionInfo(id: $id, amount: $amountFormatted, type: $type, status: $status, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum TransactionType {
  incoming,
  outgoing,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}
class TransactionException implements Exception {
  final String message;
  
  TransactionException(this.message);
  
  @override
  String toString() => 'TransactionException: $message';
}

/// Transaction operation result
class TransactionResult {
  final bool success;
  final String? error;
  final List<TransactionInfo>? transactions;
  
  TransactionResult.success(this.transactions) : success = true, error = null;
  TransactionResult.error(this.error) : success = false, transactions = null;
}