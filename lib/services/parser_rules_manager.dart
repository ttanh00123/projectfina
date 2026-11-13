// lib/services/parser_rules_manager.dart
//
// Nạp rule (bundled -> cache) và cập nhật từ server.
//
// manifest.json (file tĩnh, host ở đâu cũng được):
//   {"version": 2, "url": "parser_rules_2.json", "sha256": "<hex>", "minEngine": 1}
//
// pubspec: thêm `http` và `crypto`.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/models/category.dart';
import 'package:taexpense/services/local_transaction_parser.dart';
import 'package:taexpense/services/parser_rules.dart';

/// Nơi lưu bản rule đã tải (thường là 1 file trong thư mục support của app).
abstract class ParserRulesStorage {
  Future<String?> read();
  Future<void> write(String content);
}

/// Ghi qua file tạm rồi rename để không bao giờ để lại file nửa chừng.
class FileParserRulesStorage implements ParserRulesStorage {
  final String path;
  FileParserRulesStorage(this.path);

  @override
  Future<String?> read() async {
    final f = File(path);
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String content) async {
    final tmp = File('$path.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(path);
  }
}

class SharedPreferencesParserRulesStorage implements ParserRulesStorage {
  final String key;
  SharedPreferencesParserRulesStorage([this.key = 'cached_parser_rules']);

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, content);
  }
}

enum RulesUpdateStatus { upToDate, updated, needsAppUpdate, failed }

class RulesUpdateResult {
  final RulesUpdateStatus status;
  final int? version;
  final String? message;
  const RulesUpdateResult(this.status, {this.version, this.message});
  @override
  String toString() => 'RulesUpdateResult($status, v=$version, $message)';
}

class ParserRulesManager {
  final String bundledJson;
  final ParserRulesStorage storage;
  final Uri manifestUri;

  /// Tập category id hợp lệ (từ master data). Pack tham chiếu id ngoài tập này bị từ chối.
  final List<Category>? validCategoryIds;

  final Future<String> Function(Uri) _fetch;
  bool _updating = false;

  ParserRulesManager({
    required this.bundledJson,
    required this.storage,
    required this.manifestUri,
    this.validCategoryIds,
    Future<String> Function(Uri)? fetch,
  }) : _fetch = fetch ?? _defaultFetch;

  static Future<String> _defaultFetch(Uri u) async {
    final r = await http.get(u).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode} cho $u');
    return utf8.decode(r.bodyBytes);
  }

  int get version => ParserRulesStore.current.version;

  /// Gọi 1 lần lúc khởi động app (trước khi parse). Bản bundled bắt buộc hợp lệ;
  /// bản cache chỉ dùng nếu mới hơn, tương thích engine và qua self-test.
  Future<void> init() async {
    final bundled =
        ParserRules.parse(bundledJson, validCategoryIds: validCategoryIds);
    var chosen = bundled;
    try {
      final cached = await storage.read();
      if (cached != null) {
        final pack =
            ParserRules.parse(cached, validCategoryIds: validCategoryIds);
        if (pack.version > bundled.version &&
            LocalTransactionParser.runSelfTests(pack).isEmpty) {
          chosen = pack;
        }
      }
    } catch (_) {
      // cache hỏng / không tương thích -> dùng bundled
    }
    ParserRulesStore.set(chosen);
  }

  /// Không bao giờ throw. Chỉ thay rule khi bản mới qua đủ: version mới hơn, tương thích
  /// engine, khớp SHA-256, đúng schema + category id hợp lệ, và toàn bộ test case đi kèm đạt.
  Future<RulesUpdateResult> checkForUpdate() async {
    if (_updating) {
      return const RulesUpdateResult(RulesUpdateStatus.failed,
          message: 'Đang cập nhật');
    }
    _updating = true;
    try {
      final manifest = jsonDecode(await _fetch(manifestUri));
      if (manifest is! Map) throw ParserRulesException('Manifest không hợp lệ');
      final newVersion = manifest['version'];
      final url = manifest['url'];
      final sha = manifest['sha256'];
      final minEngine = (manifest['minEngine'] as num?)?.toInt() ?? 1;
      if (newVersion is! int || url is! String || sha is! String) {
        throw ParserRulesException('Manifest thiếu version/url/sha256');
      }
      if (newVersion <= version) {
        return RulesUpdateResult(RulesUpdateStatus.upToDate, version: version);
      }
      if (minEngine > kParserEngineVersion) {
        return RulesUpdateResult(RulesUpdateStatus.needsAppUpdate,
            version: newVersion, message: 'Pack cần engine $minEngine');
      }

      final body = await _fetch(manifestUri.resolve(url));
      if (sha256.convert(utf8.encode(body)).toString() != sha.toLowerCase()) {
        throw ParserRulesException('Sai checksum');
      }
      final pack = ParserRules.parse(body, validCategoryIds: validCategoryIds);
      if (pack.version != newVersion) {
        throw ParserRulesException('Version trong pack khác manifest');
      }
      final failures = LocalTransactionParser.runSelfTests(pack);
      if (failures.isNotEmpty) {
        throw ParserRulesException('Pack không qua test: ${failures.first}');
      }

      await storage.write(body);
      ParserRulesStore.set(pack);
      return RulesUpdateResult(RulesUpdateStatus.updated, version: newVersion);
    } on ParserRulesIncompatibleException catch (e) {
      return RulesUpdateResult(RulesUpdateStatus.needsAppUpdate,
          message: e.message);
    } catch (e) {
      return RulesUpdateResult(RulesUpdateStatus.failed, message: '$e');
    } finally {
      _updating = false;
    }
  }
}
