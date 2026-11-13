import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_status_code/http_status_code.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/services/settings_service.dart';
import 'package:taexpense/utils/utils.dart';

import 'package:taexpense/services/local_transaction_parser.dart';

Future<PromptResult?> sendPrompt(String text, int userId, String token) async {
  final currency = await SettingsService.getCurrency();
  final languageCode = await SettingsService.getLocale();

  // 1. Local-First Parser (Chạy trực tiếp offline trên thiết bị, tức thì < 5ms)
  final localResult = LocalTransactionParser.parse(
    text,
    defaultCurrency: currency,
    locale: languageCode,
  );
  // if (localResult != null) {
  return localResult;
  // }

  // 2. Fallback sang backend LLM nếu câu phức tạp vượt quá khả năng bóc tách offline
  // try {
  //   final r = await http
  //       .post(
  //         Uri.parse(AppConstants.PROMPT_API),
  //         headers: Utils.buildRequestHeader(token),
  //         body: jsonEncode({
  //           "text": text,
  //           "user_id": userId,
  //           "currency": currency,
  //           "language_code": languageCode,
  //         }),
  //       )
  //       .timeout(const Duration(seconds: 30));
  //   if (r.statusCode == StatusCode.OK) {
  //     return PromptResult.fromJson(jsonDecode(r.body));
  //   }
  //   throw ApiException(Utils.extractError(r), statusCode: r.statusCode);
  // } catch (e) {
  //   // Nếu mất mạng hoặc API lỗi, thử lại fallback cục bộ với best-effort
  //   if (localResult != null) {
  //     return localResult;
  //   }
  //   rethrow;
  // }

// Fake AI response for testing
  // var dummy = '''{
  //       "request_id": "b315b536-4f83-41ac-9bcc-d61db7b198b7",
  //       "user_prompt": "Cafe at Master Hall 8 dollars",
  //       "data": {
  //           "type": "expense",
  //           "amount": 8.0,
  //           "currency": "SGD",
  //           "address": "Cafe at Master Hall",
  //           "date_time": "2026-05-06T00:00:00Z",
  //           "master_category_id": 9,
  //           "content": "Cafe at Master Hall",
  //           "tags": "Personal",
  //           "notes": null
  //       }
  //   }''';
  // return PromptResult.fromJson(jsonDecode(dummy));
}
