import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RemoteCategorizer {
  RemoteCategorizer({
    required this.endpoint,
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final Duration timeout;
  final http.Client _client;
  final Map<String, int> _cache = {};

  /// Returns a category id from [allowedIds], or null on any failure.
  Future<int?> categorize({
    required String text,
    required bool isIncome,
    required Set<int> allowedIds,
    required String authToken,
    String locale = 'vi',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || allowedIds.isEmpty) return null;

    final key = '${isIncome ? 'in' : 'ex'}|${clean.toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final res = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'text': clean,
              'type': isIncome ? 'income' : 'expense',
              'locale': locale,
              'category_ids': allowedIds.toList(),
            }),
          )
          .timeout(timeout);

      if (res.statusCode != 200) {
        debugPrint('RemoteCategorizer HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final raw = data is Map ? data['category_id'] : null;
      final id =
          raw is num ? raw.toInt() : (raw is String ? int.tryParse(raw) : null);

      if (id == null || !allowedIds.contains(id)) return null; // reject junk
      _cache[key] = id;
      return id;
    } on TimeoutException {
      debugPrint('RemoteCategorizer timed out');
    } catch (e) {
      debugPrint('RemoteCategorizer error: $e');
    }
    return null;
  }
}