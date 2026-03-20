import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_status_code/http_status_code.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/utils/utils.dart';

Future<PromptResult> sendPrompt(String text, int userId, String token) async {
  final r = await http.post(
    Uri.parse(AppConstants.PROMPT_API),
    headers: Utils.buildRequestHeader(token),
    body: jsonEncode({'text': text, 'user_id': userId}),
  ).timeout(const Duration(seconds: 30));
  if (r.statusCode == StatusCode.OK) {
    return PromptResult.fromJson(jsonDecode(r.body));
  }
  // return Future.error(ApiException(Utils.extractError(r), statusCode: r.statusCode));
  throw ApiException(Utils.extractError(r), statusCode: r.statusCode);
}