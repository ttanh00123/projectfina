import 'package:taexpense/models/wallet_type.dart';

const kWalletTypes = [
  WalletType(nameKey: 'wallet_type.cash',       icon: 'payments',        sortOrder: 1),
  WalletType(nameKey: 'wallet_type.bank',        icon: 'account_balance', sortOrder: 2),
  WalletType(nameKey: 'wallet_type.credit',      icon: 'credit_card',     sortOrder: 3),
  WalletType(nameKey: 'wallet_type.ewallet',     icon: 'phone_android',   sortOrder: 4),
  WalletType(nameKey: 'wallet_type.investment',  icon: 'trending_up',     sortOrder: 5),
  WalletType(nameKey: 'wallet_type.savings',     icon: 'savings',         sortOrder: 6),
];

// Lookup helper
WalletType walletTypeByKey(String key) =>
    kWalletTypes.firstWhere(
      (wt) => wt.nameKey == key,
      orElse: () => kWalletTypes.first,
    );