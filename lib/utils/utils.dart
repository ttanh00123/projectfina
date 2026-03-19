import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taexpense/screens/login_screen.dart';

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

  static double toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is String) {
      value = value.replaceAll('.', '').replaceAll(',', '');
      return double.tryParse(value) ?? 0.0;
    } else if (value is int) {
      return 0.0 + value;
    } else {
      return value;
    }
  }

  static Map<String, String> buildRequestHeader(token) {
    return {
      "Access-Control-Allow-Origin": "*",         // Required for CORS support to work
      "Access-Control-Allow-Credentials": "true", // Required for cookies, authorization headers with HTTPS
      "Access-Control-Allow-Headers": "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    } catch (e) {
      return date; // Return original string if parsing fails
    }
  }

  static String formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute}";
    } catch (e) {
      return dateTime; // Return original string if parsing fails
    }
  }

  static String formatTime(String time) {
    try {
      DateTime parsedTime = DateTime.parse(time);
      return "${parsedTime.hour}:${parsedTime.minute}";
    } catch (e) {
      return time; // Return original string if parsing fails
    }
  }

  static String formatDateTimeToString(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  static String formatDateToString(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  static String formatTimeToString(DateTime time) {
    return "${time.hour}:${time.minute}";
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

  static String moneyFormat(dynamic value) {
    if (value == null) return "";

    return NumberFormat.simpleCurrency(locale: 'vi')
        .format(double.tryParse(value));
  }

  static String moneyFormatFromDouble(double value) {
    return NumberFormat.simpleCurrency(locale: 'vi').format(value);
  }

  static String moneyClearFormat(String value) {
    return value.replaceAll(',', '').replaceAll('.', '');
  }
}