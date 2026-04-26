// lib/services/master_data_store.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // bỏ crypto
import 'package:taexpense/models/category.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/services/master_data_service.dart';

class MasterDataStore {
  static const _keyJson     = 'master_data_json';
  static const _keyMd5      = 'master_data_md5';
  static const _keyRecentTags = 'recent_tags';   // thêm

  List<WalletModel> wallets    = [];
  List<Category>    categories = [];
  List<String>      recentTags = [];  // thêm — dùng cho TagsInputField
  String?           _cachedMd5;

  static final MasterDataStore _instance = MasterDataStore._();
  factory MasterDataStore() => _instance;
  MasterDataStore._();

  // ── Load từ Prefs → parse thành Object ────────────────────────────────────

  Future<void> loadFromCache() async {
    final prefs   = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyJson);
    _cachedMd5    = prefs.getString(_keyMd5);
    if (jsonStr != null) {
      _parseAndStore(jsonDecode(jsonStr) as Map<String, dynamic>);
    }
    // Load recent tags
    final tagsJson = prefs.getString(_keyRecentTags);
    if (tagsJson != null) {
      recentTags = (jsonDecode(tagsJson) as List).cast<String>();
    }
  }

  void _parseAndStore(Map<String, dynamic> data) {
    wallets = (data['wallets'] as List)
        .map((j) => WalletModel.fromJson(j as Map<String, dynamic>))
        .toList();
    categories = (data['categories'] as List)
        .map((j) => Category.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Sync với server ────────────────────────────────────────────────────────

  Future<bool> sync(String authToken, {String locale = 'vi'}) async {
    final result = await MasterDataService.sync(
      authToken: authToken,
      clientMd5: _cachedMd5,
      locale:    locale,   // thêm
    );

    if (!(result['changed'] as bool? ?? false)) return false;

    _parseAndStore(result['data'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyJson, jsonEncode(result['data']));
    await prefs.setString(_keyMd5,  result['md5'] as String);
    _cachedMd5 = result['md5'] as String;

    return true;
  }

  // ── Recent tags — cập nhật sau mỗi lần lưu transaction ───────────────────

  Future<void> addRecentTags(List<String> tags) async {
    if (tags.isEmpty) return;
    // Merge, dedup, giữ tối đa 30 tags gần nhất
    final merged = [...tags, ...recentTags]
        .toSet()
        .take(30)
        .toList();
    recentTags = merged;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentTags, jsonEncode(recentTags));
  }

  // ── Clear (logout) ─────────────────────────────────────────────────────────

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyJson);
    await prefs.remove(_keyMd5);
    await prefs.remove(_keyRecentTags);
    wallets    = [];
    categories = [];
    recentTags = [];
    _cachedMd5 = null;
  }

  // ── Lookup helpers (AI resolver) ───────────────────────────────────────────

  WalletModel? resolveWallet(String hint) {
    final h = hint.toLowerCase();
    return wallets
        .where((w) => w.name.toLowerCase().contains(h)
                   || h.contains(w.name.toLowerCase()))
        .firstOrNull;
  }

  Category? resolveCategory(String hint, {int? type}) {
    final h    = hint.toLowerCase();
    final pool = categories.where((c) =>
        type == null || c.type == type || c.type == 2);
    return pool
        .where((c) => c.name.toLowerCase().contains(h)
                   || h.contains(c.name.toLowerCase()))
        .firstOrNull;
  }
}