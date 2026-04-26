// lib/services/master_data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taexpense/app_constants.dart';

class MasterDataService {

  // ── POST /users/initialize ─────────────────────────────────────────────────

  static Future<void> initialize({
    required String authToken,
    required String locale,
    required String currency,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/users/initialize'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'locale':   locale,
        'currency': currency,
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'Initialize failed (${res.statusCode})');
    }
  }

  // ── GET /master-data/sync ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sync({
    required String authToken,
    String? clientMd5,
    String locale = 'vi',   // thêm
  }) async {
    final uri = Uri.parse('${AppConstants.BASE_URL}/master-data/sync')
        .replace(queryParameters: {
      if (clientMd5 != null) 'client_md5': clientMd5,
      'locale': locale,   // thêm
    });

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Sync failed (${res.statusCode})');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}