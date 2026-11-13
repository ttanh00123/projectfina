// lib/services/parser_rules.dart
//
// Dữ liệu (data) của LocalTransactionParser: từ khoá category, đơn vị tiền, động từ,
// giới từ... Logic vẫn nằm trong LocalTransactionParser. Regex được build ở đây từ danh sách
// từ (đã escape) chứ không nhận regex thô từ server.

import 'dart:convert';

import 'package:taexpense/models/category.dart';

/// Phiên bản engine (logic trong app). Pack khai báo `minEngine`; lớn hơn số này nghĩa là
/// pack cần logic mới => phải update app.
const int kParserEngineVersion = 1;
const int kParserSchemaVersion = 1;

class ParserRulesException implements Exception {
  final String message;
  ParserRulesException(this.message);
  @override
  String toString() => 'ParserRulesException: $message';
}

class ParserRulesIncompatibleException extends ParserRulesException {
  ParserRulesIncompatibleException(String message) : super(message);
}

/// Bỏ dấu tiếng Việt, giữ nguyên hoa/thường, độ dài chuỗi không đổi (1-1 theo ký tự dựng sẵn).
String removeDiacriticsVi(String value) {
  final sb = StringBuffer();
  for (final r in value.runes) {
    sb.write(_foldMap[r] ?? String.fromCharCode(r));
  }
  return sb.toString();
}

final Map<int, String> _foldMap = () {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final m = <int, String>{};
  groups.forEach((base, chars) {
    for (final r in chars.runes) {
      m[r] = base;
      for (final u in String.fromCharCode(r).toUpperCase().runes) {
        m[u] = base.toUpperCase();
      }
    }
  });
  return m;
}();

String _norm(String s) => removeDiacriticsVi(s.toLowerCase().trim());

String _alt(Iterable<String> words) => words.map(RegExp.escape).join('|');

class RelativeDay {
  final RegExp pattern;
  final int offsetDays;
  const RelativeDay(this.pattern, this.offsetDays);
}

class AmountUnit {
  final double multiplier;
  final String? currency;
  const AmountUnit(this.multiplier, this.currency);
}

class CategoryAliases {
  final int id;
  final List<String> keywords; // đã normalize (bỏ dấu, lowercase)
  const CategoryAliases(this.id, this.keywords);
}

class RuleTest {
  final String input;
  final String? type; // expense | income | transfer
  final double? amount;
  final String? currency;
  final int? category;
  final String? location;
  const RuleTest(this.input, this.type, this.amount, this.currency,
      this.category, this.location);
}

class ParserRules {
  final int version;
  final int minEngine;
  final String name;

  // Date
  final List<RelativeDay> relativeDays;
  final RegExp nDaysAgoRegex; // chạy trên text đã bỏ dấu

  // Amount
  final RegExp prefixPattern;
  final RegExp suffixPattern;
  final Map<String, String> currencySymbols; // key lowercase
  final Map<String, AmountUnit> amountUnits; // key đã normalize

  // Intent
  final RegExp transferIntentRegex; // chạy trên text đã bỏ dấu
  final RegExp incomeIntentRegex;

  // Transfer
  final RegExp transferVerbRegex;
  final RegExp fromToPattern;
  final RegExp separatorPattern;
  final RegExp fromPrefixRegex;
  final List<String> withdrawHints;

  // Wallet
  final RegExp walletPrepPattern;
  final List<String> cashTerms;
  final List<String> bankHintTerms;
  final List<String> bankWalletTerms;

  // Location
  final RegExp locationPattern;
  final Set<String> locationQuanPrepositions;
  final Set<String> locationQuanExceptions;

  // Content
  final RegExp leadingVerbRegex;
  final RegExp fillerRegex;
  final List<String> keepTienPhrases;

  // Category (thứ tự = ưu tiên)
  final List<CategoryAliases> incomeCategories;
  final List<CategoryAliases> expenseGeneralCategories;
  final List<CategoryAliases> expenseSpecificCategories;
  final int defaultIncomeCategory;
  final int defaultExpenseCategory;

  final List<RuleTest> tests;

  const ParserRules._({
    required this.version,
    required this.minEngine,
    required this.name,
    required this.relativeDays,
    required this.nDaysAgoRegex,
    required this.prefixPattern,
    required this.suffixPattern,
    required this.currencySymbols,
    required this.amountUnits,
    required this.transferIntentRegex,
    required this.incomeIntentRegex,
    required this.transferVerbRegex,
    required this.fromToPattern,
    required this.separatorPattern,
    required this.fromPrefixRegex,
    required this.withdrawHints,
    required this.walletPrepPattern,
    required this.cashTerms,
    required this.bankHintTerms,
    required this.bankWalletTerms,
    required this.locationPattern,
    required this.locationQuanPrepositions,
    required this.locationQuanExceptions,
    required this.leadingVerbRegex,
    required this.fillerRegex,
    required this.keepTienPhrases,
    required this.incomeCategories,
    required this.expenseGeneralCategories,
    required this.expenseSpecificCategories,
    required this.defaultIncomeCategory,
    required this.defaultExpenseCategory,
    required this.tests,
  });

  /// [validCategoryIds]: nếu truyền vào, mọi category id trong pack phải thuộc danh sách này
  /// (dùng master data của app) — pack không thể trả về category không tồn tại.
  factory ParserRules.parse(String source, {List<Category>? validCategoryIds}) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw ParserRulesException('JSON không hợp lệ: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ParserRulesException('Gốc của file phải là JSON object');
    }
    return ParserRules.fromJson(decoded, validCategoryIds: validCategoryIds);
  }

  factory ParserRules.fromJson(Map<String, dynamic> j,
      {List<Category>? validCategoryIds}) {
    final schema = _int(j, 'schemaVersion');
    if (schema != kParserSchemaVersion) {
      throw ParserRulesIncompatibleException(
          'schemaVersion $schema không được hỗ trợ');
    }
    final minEngine = _int(j, 'minEngine', def: 1);
    if (minEngine > kParserEngineVersion) {
      throw ParserRulesIncompatibleException(
          'Pack cần engine $minEngine, app hiện là $kParserEngineVersion');
    }

    // ── date
    final relativeDays = <RelativeDay>[];
    final rd = j['relativeDays'];
    if (rd is! Map) throw ParserRulesException('Thiếu "relativeDays"');
    rd.forEach((k, v) {
      if (v is! int)
        throw ParserRulesException('relativeDays["$k"] phải là số nguyên');
      relativeDays.add(RelativeDay(
          RegExp(r'\b' + RegExp.escape('$k') + r'\b', caseSensitive: false),
          v));
    });
    final nDaysUnits = _norms(j, 'nDaysAgoUnits', nonEmpty: true);

    // ── amount
    final symbols = <String, String>{};
    final rawSym = j['currencySymbols'];
    if (rawSym is! Map || rawSym.isEmpty) {
      throw ParserRulesException('Thiếu "currencySymbols"');
    }
    rawSym.forEach((k, v) => symbols[('$k').toLowerCase()] = '$v');

    final unitSurfaces = <String>[];
    final units = <String, AmountUnit>{};
    final rawUnits = j['amountUnits'];
    if (rawUnits is! List || rawUnits.isEmpty) {
      throw ParserRulesException('Thiếu "amountUnits"');
    }
    for (final e in rawUnits) {
      if (e is! Map || e['u'] is! String || (e['u'] as String).trim().isEmpty) {
        throw ParserRulesException('amountUnits có phần tử không hợp lệ');
      }
      final u = (e['u'] as String).trim();
      final mult = (e['mult'] as num?)?.toDouble() ?? 1.0;
      if (mult <= 0)
        throw ParserRulesException('amountUnits["$u"].mult phải > 0');
      unitSurfaces.add(u);
      units.putIfAbsent(
          _norm(u), () => AmountUnit(mult, e['currency'] as String?));
    }

    // ── intents (keyword đã normalize, chạy trên text đã bỏ dấu)
    final transferKw = _norms(j, 'transferIntentKeywords', nonEmpty: true);
    final incomeKw = _norms(j, 'incomeIntentKeywords', nonEmpty: true);

    // ── transfer
    final transferVerbs = _strings(j, 'transferVerbs', nonEmpty: true);
    final fromWords = _strings(j, 'transferFromWords', nonEmpty: true);
    final toWords = _strings(j, 'transferToWords', nonEmpty: true);
    final fromAlt = _alt(fromWords);
    final toAlt = _alt(toWords);

    // ── wallet
    final walletPreps = _strings(j, 'walletPrepositions', nonEmpty: true);
    final aliases = j['walletAliases'];
    if (aliases is! Map) throw ParserRulesException('Thiếu "walletAliases"');

    // ── location
    final locPreps = _strings(j, 'locationPrepositions', nonEmpty: true);

    // ── content
    final leadingVerbs = _strings(j, 'leadingVerbs', nonEmpty: true);
    final fillers = _strings(j, 'fillerWords', nonEmpty: true);

    // ── categories
    final incomeCats = _categories(j, 'incomeCategories', validCategoryIds);
    final generalCats =
        _categories(j, 'expenseGeneralCategories', validCategoryIds);
    final specificCats =
        _categories(j, 'expenseSpecificCategories', validCategoryIds);
    final defIncome = _int(j, 'defaultIncomeCategory');
    final defExpense = _int(j, 'defaultExpenseCategory');
    if (validCategoryIds != null &&
        (!_containsCategoryId(validCategoryIds, defIncome) ||
            !_containsCategoryId(validCategoryIds, defExpense))) {
      throw ParserRulesException(
          'Category mặc định không có trong master data');
    }

    // ── tests
    final tests = <RuleTest>[];
    final rawTests = j['tests'];
    if (rawTests is List) {
      for (final e in rawTests) {
        if (e is! Map || e['input'] is! String) {
          throw ParserRulesException('tests có phần tử không hợp lệ');
        }
        tests.add(RuleTest(
          e['input'] as String,
          e['type'] as String?,
          (e['amount'] as num?)?.toDouble(),
          e['currency'] as String?,
          (e['category'] as num?)?.toInt(),
          e['location'] as String?,
        ));
      }
    }

    return ParserRules._(
      version: _int(j, 'version'),
      minEngine: minEngine,
      name: (j['name'] as String?) ?? 'unnamed',
      relativeDays: relativeDays,
      nDaysAgoRegex: RegExp(r'\b(\d+)\s*(?:' + _alt(nDaysUnits) + r')\b'),
      prefixPattern: RegExp(
        r'(?:^|\s+)(' +
            _alt(symbols.keys) +
            r')\s*(\d{1,3}(?:[.,]\d{3})*|\d+)(?:[.,](\d{1,2}))?(?=$|\s|[.,;!?])',
        caseSensitive: false,
      ),
      suffixPattern: RegExp(
        r'(?:^|\b)(\d+(?:[.,]\d+)?)\s*(' +
            _alt(unitSurfaces) +
            r')(?=$|\s|[.,;!?])',
        caseSensitive: false,
      ),
      currencySymbols: symbols,
      amountUnits: units,
      transferIntentRegex: RegExp(r'\b(' + _alt(transferKw) + r')\b'),
      incomeIntentRegex: RegExp(r'\b(' + _alt(incomeKw) + r')\b'),
      transferVerbRegex:
          RegExp(r'\b(' + _alt(transferVerbs) + r')\b', caseSensitive: false),
      fromToPattern: RegExp(
        r'(?:^|\s+)(?:' +
            fromAlt +
            r')\s+([a-zA-Z0-9\s]+?)\s+(?:' +
            toAlt +
            r')\s+([a-zA-Z0-9\s]+)',
        caseSensitive: false,
      ),
      separatorPattern: RegExp(
        r'(?:^|\s+)(' + toAlt + r')\s+([a-zA-Z0-9\s]+)',
        caseSensitive: false,
      ),
      fromPrefixRegex:
          RegExp(r'^(?:' + fromAlt + r')\s+', caseSensitive: false),
      withdrawHints: _norms(j, 'withdrawHints'),
      walletPrepPattern: RegExp(
        r'(?:^|\s+)(' +
            _alt(walletPreps) +
            r')\s+([a-zA-Z0-9\s]+?)(?=$|\s|[.,;!?])',
        caseSensitive: false,
      ),
      cashTerms: _normList(aliases['cash']),
      bankHintTerms: _normList(aliases['bankHint']),
      bankWalletTerms: _normList(aliases['bankWallet']),
      locationPattern: RegExp(
        r'(?:^|\s+)(' + _alt(locPreps) + r')\s+([^,]+)',
        caseSensitive: false,
      ),
      locationQuanPrepositions: _norms(j, 'locationQuanPrepositions').toSet(),
      locationQuanExceptions: _norms(j, 'locationQuanExceptions').toSet(),
      leadingVerbRegex:
          RegExp(r'^(?:' + _alt(leadingVerbs) + r')\s+', caseSensitive: false),
      fillerRegex:
          RegExp(r'\b(?:' + _alt(fillers) + r')\b', caseSensitive: false),
      keepTienPhrases: _norms(j, 'keepTienPhrases'),
      incomeCategories: incomeCats,
      expenseGeneralCategories: generalCats,
      expenseSpecificCategories: specificCats,
      defaultIncomeCategory: defIncome,
      defaultExpenseCategory: defExpense,
      tests: tests,
    );
  }

  AmountUnit? unitFor(String surfaceUnit) => amountUnits[_norm(surfaceUnit)];

  // ── helpers ────────────────────────────────────────────────────────────────

  static int _int(Map<String, dynamic> j, String key, {int? def}) {
    final v = j[key];
    if (v == null && def != null) return def;
    if (v is! int) throw ParserRulesException('"$key" phải là số nguyên');
    return v;
  }

  static List<String> _strings(Map<String, dynamic> j, String key,
      {bool nonEmpty = false}) {
    final raw = j[key];
    if (raw == null) {
      if (nonEmpty) throw ParserRulesException('Thiếu "$key"');
      return [];
    }
    if (raw is! List) throw ParserRulesException('"$key" phải là list chuỗi');
    final out = [
      for (final e in raw)
        if (e is String && e.trim().isNotEmpty) e.trim()
    ];
    if (nonEmpty && out.isEmpty)
      throw ParserRulesException('"$key" không được rỗng');
    return out;
  }

  static List<String> _norms(Map<String, dynamic> j, String key,
          {bool nonEmpty = false}) =>
      _strings(j, key, nonEmpty: nonEmpty).map(_norm).toList();

  static List<String> _normList(Object? raw) {
    if (raw is! List) return [];
    return [
      for (final e in raw)
        if (e is String && e.trim().isNotEmpty) _norm(e)
    ];
  }

  static List<CategoryAliases> _categories(
      Map<String, dynamic> j, String key, List<Category>? valid) {
    final raw = j[key];
    if (raw is! List || raw.isEmpty) throw ParserRulesException('Thiếu "$key"');
    final out = <CategoryAliases>[];
    for (final e in raw) {
      if (e is! Map || e['id'] is! int || e['keywords'] is! List) {
        throw ParserRulesException('"$key" có phần tử không hợp lệ');
      }
      final id = e['id'] as int;
      if (valid != null && !_containsCategoryId(valid, id)) {
        throw ParserRulesException(
            '"$key": category id $id không có trong master data');
      }
      final kws = [
        for (final k in e['keywords'] as List)
          if (k is String && k.trim().isNotEmpty) _norm(k)
      ];
      out.add(CategoryAliases(id, kws));
    }
    return out;
  }

  static bool _containsCategoryId(List<Category> categories, int id) =>
      categories.any((category) => category.id == id);
}

/// Nơi giữ rule đang dùng. LocalTransactionParser đọc từ đây.
class ParserRulesStore {
  static ParserRules? _current;

  static ParserRules get current {
    final c = _current;
    if (c == null) {
      throw StateError(
          'ParserRulesStore chưa được khởi tạo: gọi ParserRulesManager.init()');
    }
    return c;
  }

  static bool get isReady => _current != null;

  static void set(ParserRules rules) => _current = rules;
}
