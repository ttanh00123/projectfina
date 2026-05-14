import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_status_code/http_status_code.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/services/settings_service.dart';
import 'package:taexpense/utils/utils.dart';

Future<PromptResult> sendPrompt(String text, int userId, String token) async {
  final r = await http
      .post(
        Uri.parse(AppConstants.PROMPT_API),
        headers: Utils.buildRequestHeader(token),
        body: jsonEncode({
          "text": text,
          "user_id": userId,
          "currency": await SettingsService.getCurrency(),
          "language_code": await SettingsService.getLocale(),
        }),
      )
      .timeout(const Duration(seconds: 30));
  if (r.statusCode == StatusCode.OK) {
    return PromptResult.fromJson(jsonDecode(r.body));
  }
  // return Future.error(ApiException(Utils.extractError(r), statusCode: r.statusCode));
  throw ApiException(Utils.extractError(r), statusCode: r.statusCode);

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
