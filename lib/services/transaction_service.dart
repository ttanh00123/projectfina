// lib/services/transaction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:taexpense/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ── Headers ───────────────────────────────────────────────────────────────────

Map<String, String> _authHeaders(String token) {
  final locale = Intl.getCurrentLocale();
  final lang = locale.split('_')[0];

  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept-Language': lang,
  };
}

String _extractError(http.Response r) {
  try {
    final body = jsonDecode(r.body);
    return body['detail'] as String? ?? 'Lỗi không xác định';
  } catch (_) {
    return 'Lỗi ${r.statusCode}';
  }
}

// ── Save transaction ──────────────────────────────────────────────────────────

Future<Map<String, dynamic>> saveTransaction(
  Map<String, dynamic> data,
  String token,
) async {
  final r = await http.post(
    Uri.parse('${AppConstants.BASE_URL}/transactions'),
    headers: _authHeaders(token),
    body: jsonEncode(data),
  ).timeout(const Duration(seconds: 15));

  if (r.statusCode == 201 || r.statusCode == 200) {
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
  throw ApiException(_extractError(r), statusCode: r.statusCode);
}

// ── Get transactions ──────────────────────────────────────────────────────────
// lib/services/transaction_service.dart
Future<List<Map<String, dynamic>>> getTransactions(
  String token, {
  int limit  = 50,
  int offset = 0,
  int? type,
  int? walletId,
  int? categoryId,
  String? fromDate,
  String? toDate,
}) async {
  final params = {
    'limit':  '$limit',
    'offset': '$offset',
    if (type       != null) 'type':        '$type',
    if (walletId   != null) 'wallet_id':   '$walletId',
    if (categoryId != null) 'category_id': '$categoryId',
    if (fromDate   != null) 'from_date':   fromDate,
    if (toDate     != null) 'to_date':     toDate,
  };

  final r = await http.get(
    Uri.parse('${AppConstants.BASE_URL}/transactions')
        .replace(queryParameters: params),
    headers: _authHeaders(token),
  ).timeout(const Duration(seconds: 15));

  if (r.statusCode == 200) {
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }
  throw ApiException(_extractError(r), statusCode: r.statusCode);
}

// ── Update transaction ────────────────────────────────────────────────────────

Future<Map<String, dynamic>> updateTransaction(
  int id,
  Map<String, dynamic> data,
  String token,
) async {
  final r = await http.put(
    Uri.parse('${AppConstants.BASE_URL}/transactions/$id'),
    headers: _authHeaders(token),
    body: jsonEncode(data),
  ).timeout(const Duration(seconds: 15));

  if (r.statusCode == 200) {
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
  throw ApiException(_extractError(r), statusCode: r.statusCode);
}

// ── Delete transaction ────────────────────────────────────────────────────────

Future<void> deleteTransaction(int id, String token) async {
  final r = await http.delete(
    Uri.parse('${AppConstants.BASE_URL}/transactions/$id'),
    headers: _authHeaders(token),
  ).timeout(const Duration(seconds: 15));

  if (r.statusCode != 200 && r.statusCode != 204) {
    throw ApiException(_extractError(r), statusCode: r.statusCode);
  }
}