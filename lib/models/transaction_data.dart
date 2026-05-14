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
  final int type; // 0 for expense, 1 for income
  final double amount;
  final String currency;
  final String? address;
  final WalletModel? wallet; // Chuyển thành nullable
  final String dateTime;
  final int category;
  final String? note;

  const TransactionData({
    this.requestId,
    required this.type,
    required this.amount,
    required this.currency,
    this.address,
    this.wallet,
    required this.dateTime,
    required this.category,
    this.note,
  });

  /// Factory này dùng để parse dữ liệu từ AI trả về (Nested trong key 'data')
  factory TransactionData.fromJson(Map<String, dynamic> json, {String? requestId}) {
    // AI thường trả về string 'expense' hoặc 'income'
    int typeValue = 0;
    if (json['type'] == 'income') {
      typeValue = 1;
    }

    return TransactionData(
      requestId: requestId,
      type: typeValue,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'VND',
      address: json['address'] ?? json['content'], // Lấy content làm địa chỉ nếu address trống
      wallet: json['wallet'] != null ? WalletModel.fromJson(json['wallet']) : null,
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
      address: value['address'],
      wallet: value['wallet'] != null ? WalletModel.fromJson(value['wallet']) : null,
      dateTime: value['dateTime'] ?? DateTime.now().toIso8601String(),
      category: (value['category'] is int) ? value['category'] : 0,
      note: value['note'],
    );
  }

  /// Helper để copyWith khi người dùng chọn ví sau khi AI đã parse xong
  TransactionData copyWith({WalletModel? wallet}) {
    return TransactionData(
      requestId: requestId,
      type: type,
      amount: amount,
      currency: currency,
      address: address,
      wallet: wallet ?? this.wallet,
      dateTime: dateTime,
      category: category,
      note: note,
    );
  }
}