import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:taexpense/screens/login_screen.dart';
import 'package:taexpense/services/settings_service.dart';
import 'package:taexpense/utils/app_config.dart';

class Utils {
  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is String) {
      return int.tryParse(value) ?? 0;
    } else if (value is double) {
      return value.toInt();
    } else {
      return int.tryParse(value.toString()) ?? 0;
    }
  }

  // static double toDouble(dynamic value) {
  //   if (value == null) return 0;

  //   if (value is String) {
  //     value = value.replaceAll('.', '').replaceAll(',', '');
  //     return double.tryParse(value) ?? 0.0;
  //   } else if (value is int) {
  //     return 0.0 + value;
  //   } else {
  //     return value;
  //   }
  // }

  static Map<String, String> buildRequestHeader(token) {
    return {
      "Access-Control-Allow-Origin": "*", // Required for CORS support to work
      "Access-Control-Allow-Credentials":
          "true", // Required for cookies, authorization headers with HTTPS
      "Access-Control-Allow-Headers":
          "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// =========================================================
  /// PARSE SERVER UTC -> LOCAL DATETIME
  /// =========================================================
  static DateTime? parseServerDateTime(dynamic value) {
    try {
      if (value == null) return null;

      String str = value.toString().trim();

      if (str.isEmpty) return null;

      /// Nếu backend thiếu timezone thì auto UTC
      if (!str.endsWith('Z') &&
          !str.contains('+') &&
          !str.contains(RegExp(r'-\d{2}:\d{2}$'))) {
        str = '${str}Z';
      }

      return DateTime.parse(str).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// =========================================================
  /// FORMAT DATETIME
  /// =========================================================
  static String formattedDateTime(
    DateTime? dt, {
    String? format,
  }) {
    if (dt == null) return '';

    try {
      return DateFormat(
        format ?? AppConfig.dateTimeFormat,
      ).format(dt);
    } catch (e) {
      return '';
    }
  }

  /// =========================================================
  /// RAW JSON DATETIME -> FORMATTED STRING
  /// =========================================================
  ///
  /// Input:
  /// 2026-05-23T10:00:00Z
  ///
  /// Output:
  /// 23-05-2026 17:00:00
  ///
  static String formattedServerDateTime(
    dynamic value, {
    String? format,
  }) {
    try {
      final dt = parseServerDateTime(value);

      if (dt == null) return '';

      return formattedDateTime(
        dt,
        format: format,
      );
    } catch (e) {
      return '';
    }
  }

  /// =========================================================
  /// DATETIME -> UTC ISO STRING
  /// =========================================================
  static String? toServerUtcString(DateTime? dt) {
    if (dt == null) return null;

    try {
      return dt.toUtc().toIso8601String();
    } catch (e) {
      return null;
    }
  }

  /// =========================================================
  /// USER STRING -> DATETIME
  /// =========================================================
  static DateTime? parseUserDateTime(
    String? value, {
    String? format,
  }) {
    try {
      if (value == null || value.trim().isEmpty) {
        return null;
      }

      return DateFormat(
        format ?? AppConfig.dateTimeFormat,
      ).parse(value);
    } catch (e) {
      return null;
    }
  }

  /// =========================================================
  /// USER STRING -> UTC ISO STRING
  /// =========================================================
  static String? userInputToServerUtcString(
    String? value, {
    String? format,
  }) {
    try {
      final dt = parseUserDateTime(
        value,
        format: format,
      );

      if (dt == null) return null;

      return dt.toUtc().toIso8601String();
    } catch (e) {
      return null;
    }
  }

  static void showLoginRequireDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              // title: const Text('Đăng nhập'),
              content: const Wrap(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.account_circle_rounded,
                        size: 48,
                      ),
                    ),
                  ),
                  Text('Bạn cần đăng nhập để sử dụng chức năng này'),
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                    },
                    child: const Text('Bỏ qua')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Đăng nhập')),
              ],
              // elevation: 24,
            ),
        barrierDismissible: false);
  }

  static void showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thông báo"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  // static String moneyFormat(dynamic value) {
  //   if (value == null) return "";

  //   return NumberFormat.simpleCurrency(locale: 'vi')
  //       .format(double.tryParse(value));
  // }

  // static String moneyFormatFromDouble(double value) {
  //   return NumberFormat.simpleCurrency(locale: 'vi').format(value);
  // }

  // static String moneyClearFormat(String value) {
  //   return value.replaceAll(',', '').replaceAll('.', '');
  // }

  static String extractError(http.Response r) {
    try {
      return (jsonDecode(r.body)['detail'] as String?) ??
          'Error ${r.statusCode}';
    } catch (_) {
      return 'Error ${r.statusCode}';
    }
  }

  /// 1. Sửa hàm toDouble (Tránh việc replace bừa bãi làm sai lệch số thập phân)
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// 2. Hàm Parse chuỗi tiền tệ từ TextField dựa trên Locale hiện tại
  /// Ví dụ: 'vi' nhập "3.080.000" -> 3080000.0 | 'en' nhập "3,080,000" -> 3080000.0
  static double moneyParse(String text) {
    if (text.trim().isEmpty) return 0.0;
    try {
      final localeStr = AppConfig.currentLocale;
      final numberFormat = NumberFormat('#,##0.##', localeStr);
      return numberFormat.parse(text).toDouble();
    } catch (e) {
      // Nếu parse theo locale lỗi, quay về dùng double.tryParse cơ bản
      return double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }
  }

  /// 3. Cập nhật moneyFormat (Chấp nhận cả String/Double và tự động nhận diện Currency + Locale)
  /// Kết quả: 'vi' -> "3.080.000 VND", 'en' -> "VND3,080,000"
  /// Định dạng tiền tệ ĐỒNG BỘ - Trả về String ngay lập tức
  static String moneyFormatFromDouble(double value) {
    final locale = AppConfig.currentLocale;
    final currency = AppConfig.currentCurrency;

    int decimalDigits = 0;
    if (currency.toUpperCase() == 'USD') {
      decimalDigits = 2;
    } else if (currency.toUpperCase() == 'VND') {
      decimalDigits = 0;
    } else {
      decimalDigits = value % 1 == 0 ? 0 : 2;
    }

    // Xác định pattern để ép NumberFormat phải chèn khoảng trắng giữa ký hiệu (¤) và số (#)
    // ¤ #,##0 có nghĩa là: [Ký hiệu tiền tệ] [Khoảng trắng] [Cấu trúc số]
    // #,##0 ¤ có nghĩa là: [Cấu trúc số] [Khoảng trắng] [Ký hiệu tiền tệ]
    String pattern = '¤ #,##0';
    if (locale == 'vi') {
      pattern = '#,##0 ¤'; // Người Việt mình thích nhìn kiểu "1.000 VND" hơn
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currency,
      decimalDigits: decimalDigits,
      customPattern: pattern, // Áp dụng pattern có khoảng trắng ở đây
    );

    return formatter.format(value);
  }

  /// Định dạng từ dynamic value (String/num) cũng ở dạng đồng bộ
  static String moneyFormat(dynamic value) {
    if (value == null) return "";
    double? amount;
    if (value is String) {
      amount = double.tryParse(value);
    } else if (value is num) {
      amount = value.toDouble();
    }
    if (amount == null) return "";
    return moneyFormatFromDouble(amount);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
