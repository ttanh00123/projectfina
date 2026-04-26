// lib/models/wallet.dart
import 'package:taexpense/constants/wallet_types.dart';
import 'package:taexpense/models/wallet_type.dart';

class WalletModel {
  final int id;
  final int userid;
  final String name;
  final WalletType walletType;
  final String currency;
  final double balance;
  final String? accountNumber;
  final String? bankName;
  final double? creditLimit;
  final int status;
  final int sortOrder;
  final String color;
  final int? dueDay;
  final DateTime createdAt;

  const WalletModel({
    required this.id,
    required this.userid,
    required this.name,
    required this.walletType,
    required this.currency,
    required this.balance,
    this.accountNumber,
    this.bankName,
    this.creditLimit,
    required this.status,
    required this.sortOrder,
    required this.color,
    this.dueDay,
    required this.createdAt,
  });

  // --- Computed properties ---

  bool get isActive => status == 1;

  bool get isCreditCard => walletType.nameKey == 'wallet_type.credit';

  // Với credit card: available = limit - (-balance) = limit + balance
  double? get availableCredit =>
      isCreditCard && creditLimit != null ? creditLimit! + balance : null;

  // Hiển thị balance theo loại ví:
  // credit card thường âm (đang nợ), các loại khác dương
  double get displayBalance => balance;

  // --- Serialization ---

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as int,
        userid: json['userid'] as int,
        name: json['name'] as String,
        walletType: walletTypeByKey(json['wallet_type'] as String),
        currency: json['currency'] as String? ?? 'VND',
        balance: double.parse(json['balance'].toString()),
        accountNumber: json['account_number'] as String?,
        bankName: json['bank_name'] as String?,
        creditLimit: json['credit_limit'] != null
            ? double.parse(json['credit_limit'].toString())
            : null,
        status: json['status'] as int? ?? 1,
        sortOrder: json['sort_order'] as int? ?? 0,
        color: json['color'] as String? ?? '#1D9E75',
        dueDay: json['due_day'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userid': userid,
        'name': name,
        'wallet_type': walletType.nameKey,
        'currency': currency,
        'balance': balance,
        'account_number': accountNumber,
        'bank_name': bankName,
        'credit_limit': creditLimit,
        'status': status,
        'sort_order': sortOrder,
        'color': color,
        'created_at': createdAt.toIso8601String(),
      };

  // toJson chỉ gửi các field user có thể thay đổi khi create/update
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'wallet_type': walletType.nameKey,
        'currency': currency,
        'account_number': accountNumber,
        'bank_name': bankName,
        'credit_limit': creditLimit,
        'sort_order': sortOrder,
        'color': color,
        'due_day': dueDay,
      };

  // copyWith — dùng khi update local state mà không mutate object gốc
  WalletModel copyWith({
    int? id,
    int? userid,
    String? name,
    WalletType? walletType,
    String? currency,
    double? balance,
    String? accountNumber,
    String? bankName,
    double? creditLimit,
    int? status,
    int? sortOrder,
    String? color,
    int? dueDay,
    DateTime? createdAt,
  }) =>
      WalletModel(
        id: id ?? this.id,
        userid: userid ?? this.userid,
        name: name ?? this.name,
        walletType: walletType ?? this.walletType,
        currency: currency ?? this.currency,
        balance: balance ?? this.balance,
        accountNumber: accountNumber ?? this.accountNumber,
        bankName: bankName ?? this.bankName,
        creditLimit: creditLimit ?? this.creditLimit,
        status: status ?? this.status,
        sortOrder: sortOrder ?? this.sortOrder,
        color: color ?? this.color,
        dueDay: dueDay ?? this.dueDay,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is WalletModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Wallet(id: $id, name: $name, balance: $balance)';
}
