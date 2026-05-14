// lib/widgets/wallet_icon.dart

import 'package:flutter/material.dart';

class WalletIcon extends StatelessWidget {
  final String iconKey;   // "credit_card"
  final String hexColor;  // "#1D9E75"
  final double size;

  const WalletIcon({
    required this.iconKey,
    required this.hexColor,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          _iconMap[iconKey] ?? Icons.account_balance_wallet,
          size: size,
          color: hexToColor(hexColor),
        ),
        // Text(
        //   _nameMap[iconKey] ?? iconKey.replaceAll('_', ' ').toUpperCase(),
        //   style: TextStyle(fontSize: 10, color: hexToColor(hexColor)),
        //   textAlign: TextAlign.center,
        // ),
      ],
    );
  }

  static Color hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static const _iconMap = {
    'payments':           Icons.payments,
    'account_balance':    Icons.account_balance,
    'credit_card':        Icons.credit_card,
    'phone_android':      Icons.phone_android,
    'savings':            Icons.savings,
    'trending_up':        Icons.trending_up,
  };


// WalletType(nameKey: 'wallet_type.cash',       icon: 'payments',        sortOrder: 1),
//   WalletType(nameKey: 'wallet_type.bank',        icon: 'account_balance', sortOrder: 2),
//   WalletType(nameKey: 'wallet_type.credit',      icon: 'credit_card',     sortOrder: 3),
//   WalletType(nameKey: 'wallet_type.ewallet',     icon: 'phone_android',   sortOrder: 4),
//   WalletType(nameKey: 'wallet_type.investment',  icon: 'trending_up',     sortOrder: 5),
//   WalletType(nameKey: 'wallet_type.savings',     icon: 'savings',         sortOrder: 6),
  static const _nameMap = {
    'payments':           'Cash',
    'account_balance':    'Bank Account',
    'credit_card':        'Credit Card',
    'phone_android':      'eWallet',
    'savings':            'Savings',
    'trending_up':        'Investment',
  };
}