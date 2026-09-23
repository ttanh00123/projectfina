import 'package:taexpense/models/wallet_model.dart';

// class TransactionData {
//   final String? requestId;
//   final int type;
//   final double amount;
//   final String currency;
//   final String? address;
//   final WalletModel wallet;
//   final String dateTime;
//   final int category;
//   final String? note;

//   const TransactionData({
//     this.requestId, required this.type, required this.amount,
//     required this.currency, this.address, required this.wallet,
//     required this.dateTime, required this.category, this.note,
//   });

//   factory TransactionData.fromJson(Map<String, dynamic> j) => TransactionData(
//     requestId: j['request_id'],
//     type: j['type'] == 'expense' ? 0 : 1,
//     amount: (j['amount'] as num).toDouble(),
//     currency: j['currency'] ?? 'VND',
//     address: j['address'],
//     wallet: WalletModel.fromJson(j['wallet'] ?? {}),
//     dateTime: j['date_time'] ?? DateTime.now().toIso8601String(),
//     category: j['master_category_id'] ?? 0,
//     note: j['note'],
//   );

//   static fromMap(Map<String, dynamic> value) {
//     return TransactionData(
//       requestId: value['requestId'],
//       type: value['type'] ?? 0,
//       amount: (value['amount'] as num).toDouble(),
//       currency: value['currency'] ?? 'VND',
//       address: value['address'],
//       wallet: WalletModel.fromJson(value['wallet'] ?? {}),
//       dateTime: value['dateTime'] ?? DateTime.now().toIso8601String(),
//       category: value['category'] ?? 'Other',
//       note: value['note'],
//     );
//   }
// }

class TransactionData {
  final String? requestId;
  final int type; // 0 for expense, 1 for income, 2 for transfer
  final double amount;
  final String currency;
  final String? content;
  final WalletModel? wallet; // Chuyển thành nullable (source wallet)
  final WalletModel? toWallet; // Destination wallet for transfer
  final double? receiveAmount;
  final String dateTime;
  final int category;
  final String? note;

  const TransactionData({
    this.requestId,
    required this.type,
    required this.amount,
    required this.currency,
    this.content,
    this.wallet,
    this.toWallet,
    this.receiveAmount,
    required this.dateTime,
    required this.category,
    this.note,
  });

  /// Factory này dùng để parse dữ liệu từ AI trả về (Nested trong key 'data')
  factory TransactionData.fromJson(Map<String, dynamic> json, {String? requestId}) {
    // AI thường trả về string 'expense', 'income' hoặc 'transfer'
    int typeValue = 0;
    if (json['type'] == 'income') {
      typeValue = 1;
    } else if (json['type'] == 'transfer') {
      typeValue = 2;
    } else if (json['type'] is int) {
      typeValue = json['type'];
    }

    return TransactionData(
      requestId: requestId,
      type: typeValue,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'VND',
      content: json['content'],
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
      toWallet: json['to_wallet'] != null ? WalletModel.fromJson(json['to_wallet']) : null,
      receiveAmount: (json['receive_amount'] as num?)?.toDouble(),
      dateTime: json['date_time'] ?? DateTime.now().toIso8601String(),
      category: json['master_category_id'] ?? 0,
      note: json['notes'] ?? json['note'], // AI hay trả về 'notes' có chữ 's'
    );
  }

  /// Map thông thường dùng cho local database hoặc state nội bộ
  static fromMap(Map<String, dynamic> value) {
    return TransactionData(
      requestId: value['requestId'],
      type: value['type'] ?? 0,
      amount: (value['amount'] as num?)?.toDouble() ?? 0.0,
      currency: value['currency'] ?? 'VND',
      content: value['address'] ?? value['content'],
      wallet: value['wallet'] != null ? WalletModel.fromJson(value['wallet']) : null,
      toWallet: value['toWallet'] != null ? WalletModel.fromJson(value['toWallet']) : null,
      receiveAmount: (value['receiveAmount'] as num?)?.toDouble(),
      dateTime: value['dateTime'] ?? DateTime.now().toIso8601String(),
      category: (value['category'] is int) ? value['category'] : 0,
      note: value['note'],
    );
  }

  /// Helper để copyWith khi người dùng chọn ví sau khi AI đã parse xong
  TransactionData copyWith({
    WalletModel? wallet,
    WalletModel? toWallet,
    double? receiveAmount,
  }) {
    return TransactionData(
      requestId: requestId,
      type: type,
      amount: amount,
      currency: currency,
      content: content,
      wallet: wallet ?? this.wallet,
      toWallet: toWallet ?? this.toWallet,
      receiveAmount: receiveAmount ?? this.receiveAmount,
      dateTime: dateTime,
      category: category,
      note: note,
    );
  }
}