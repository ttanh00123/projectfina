class TransactionData {
  final String? requestId;
  final String type;
  final double amount;
  final String currency;
  final String? address;
  final String wallet;
  final String dateTime;
  final String category;
  final String? note;

  const TransactionData({
    this.requestId, required this.type, required this.amount,
    required this.currency, this.address, required this.wallet,
    required this.dateTime, required this.category, this.note,
  });

  factory TransactionData.fromJson(Map<String, dynamic> j) => TransactionData(
    requestId: j['request_id'],
    type: j['type'] ?? 'expense',
    amount: (j['amount'] as num).toDouble(),
    currency: j['currency'] ?? 'VND',
    address: j['address'],
    wallet: j['wallet'] ?? 'cash',
    dateTime: j['date_time'] ?? DateTime.now().toIso8601String(),
    category: j['category'] ?? 'Other',
    note: j['note'],
  );
}