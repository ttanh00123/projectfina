// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:taexpense/models/user_model.dart';

class AppConstants {
  static UserModel? LOGIN_USER;
  static String? API_TOKEN;
  
  static const String BASE_URL = "http://api.conaudio.vn:8000";

  //AUTH
  static const String LOGIN_API = "$BASE_URL/auth/login";
  static const String LOGIN_BY_TOKEN_API = "$BASE_URL/auth/login/token";
  static const String SIGNUP_API = "$BASE_URL/auth/signup";
  static const String LOGOUT_API = '$BASE_URL/auth/logout';
  static const String UPDATE_FMC_TOKEN_API = '$BASE_URL/users/update/{}';
  
  //TRANSACTIONS
  static const String TRANSACTION_LIST_API = "$BASE_URL/transactions/";
  static const String TRANSACTION_TYPES_API = "$BASE_URL/transaction-types/";
  static const String CATEGORIES_API = "$BASE_URL/categories/";

  //PROMPT
  static const String PROMPT_API = "$BASE_URL/transaction/prompt";
  
}

const kCurrencies = ['VND','SGD','USD','EUR','GBP','JPY','AUD','CAD','THB','MYR'];

const kCurrencySymbols = {
  'VND': '₫', 'SGD': 'S\$', 'USD': '\$', 'EUR': '€',
  'GBP': '£', 'JPY': '¥',  'AUD': 'A\$','CAD': 'C\$',
  'THB': '฿', 'MYR': 'RM',
};

const kCountries = {
  'VN': '🇻🇳 Vietnam',
  'SG': '🇸🇬 Singapore',
  'US': '🇺🇸 United States',
};

const kDefaultCurrency = {
  'VN': 'VND', 'SG': 'SGD', 'US': 'USD',
};

const kCategories = [
  'Food & Drinks', 'Shopping', 'Transport', 'Entertainment',
  'Health', 'Education', 'Housing', 'Utilities',
  'Salary', 'Business', 'Investment', 'Transfer', 'Other',
];

const kWallets = ['Cash', 'Bank', 'VISA', 'Mastercard', 'MoMo', 'ZaloPay', 'Other'];
