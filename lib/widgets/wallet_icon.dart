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
    return Icon(
      _iconMap[iconKey] ?? Icons.account_balance_wallet,
      size: size,
      color: hexToColor(hexColor),
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
}