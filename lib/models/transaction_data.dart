import 'package:taexpense/models/wallet_model.dart';

class TransactionData {
  final String? requestId;
  final int type;
  final double amount;
  final String currency;
  final String? address;
  final WalletModel wallet;
  final String dateTime;
  final int category;
  final String? note;

  const TransactionData({
    this.requestId, required this.type, required this.amount,
    required this.currency, this.address, required this.wallet,
    required this.dateTime, required this.category, this.note,
  });

  factory TransactionData.fromJson(Map<String, dynamic> j) => TransactionData(
    requestId: j['request_id'],
    type: j['type'] ?? 0,
    amount: (j['amount'] as num).toDouble(),
    currency: j['currency'] ?? 'VND',
    address: j['address'],
    wallet: WalletModel.fromJson(j['wallet'] ?? {}),
    dateTime: j['date_time'] ?? DateTime.now().toIso8601String(),
    category: j['category'] ?? 'Other',
    note: j['note'],
  );
}