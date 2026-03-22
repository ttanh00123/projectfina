// lib/utils/wallet_type_l10n.dart

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension WalletTypeL10n on AppLocalizations {
  String translateKey(String key) {
    switch (key) {
      case 'wallet_type.cash':       return walletTypeCash;
      case 'wallet_type.bank':       return walletTypeBank;
      case 'wallet_type.credit':     return walletTypeCredit;
      case 'wallet_type.ewallet':    return walletTypeEwallet;
      case 'wallet_type.investment': return walletTypeInvestment;
      case 'wallet_type.savings':    return walletTypeSavings;
      default:                       return key;
    }
  }
}