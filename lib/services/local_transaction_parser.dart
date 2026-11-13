// lib/services/local_transaction_parser.dart
//
// Logic parser giữ nguyên; toàn bộ dữ liệu (từ khoá, đơn vị, giới từ, category...) đọc từ
// ParserRules (assets/parser_rules.json hoặc bản đã tải về), xem parser_rules.dart.

import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/models/transaction_data.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/parser_rules.dart';

class LocalTransactionParser {
  static ParserRules? _override;

  /// Rule đang dùng: [_override] (khi self-test một pack ứng viên) hoặc rule hiện hành của app.
  static ParserRules get _r => _override ?? ParserRulesStore.current;

  /// Entry point to parse natural language transaction offline.
  /// Returns a [PromptResult] if parsed successfully, or null if cannot parse.
  ///
  /// [rules]: chỉ dùng để thử một bộ rule khác (self-test trước khi áp dụng bản cập nhật).
  static PromptResult? parse(
    String input, {
    String defaultCurrency = 'VND',
    String locale = 'vi',
    ParserRules? rules,
  }) {
    if (rules == null) return _parseImpl(input, defaultCurrency, locale);
    final prev = _override;
    _override = rules;
    try {
      return _parseImpl(input, defaultCurrency, locale);
    } finally {
      _override = prev; // parse là đồng bộ nên không bị chen ngang
    }
  }

  /// Chạy các test case đi kèm [rules]. Trả về danh sách lỗi (rỗng = đạt).
  static List<String> runSelfTests(ParserRules rules) {
    final failures = <String>[];
    for (final t in rules.tests) {
      PromptResult? res;
      try {
        res = parse(t.input, rules: rules);
      } catch (e) {
        failures.add('"${t.input}": lỗi khi parse ($e)');
        continue;
      }
      final TransactionData? d = res?.data;
      if (d == null) {
        failures.add('"${t.input}": không parse được');
        continue;
      }
      void check(String field, Object? expected, Object? actual) {
        if (expected != null && expected != actual) {
          failures.add('"${t.input}": $field mong đợi $expected, nhận $actual');
        }
      }

      if (t.type != null) {
        final int? want = t.type == 'transfer'
            ? AppConstants.TRANSFER
            : (t.type == 'income'
                ? AppConstants.INCOME
                : (t.type == 'expense' ? AppConstants.EXPENSE : null));
        check('type', want, d.type);
      }
      if (t.amount != null && (d.amount - t.amount!).abs() > 0.005) {
        failures
            .add('"${t.input}": amount mong đợi ${t.amount}, nhận ${d.amount}');
      }
      check('currency', t.currency, d.currency);
      check('category', t.category, d.category);
      check('location', t.location, d.note);
    }
    return failures;
  }

  static PromptResult? _parseImpl(
      String input, String defaultCurrency, String locale) {
    final rawText = _clean(input);
    if (rawText.isEmpty) return null;

    final categoryLocale = _categoryLocale(locale);

    // 1. Bóc tách Ngày & Thời gian (Date/Time Extraction)
    final dateResult = _extractDateTime(rawText);
    final textWithoutDate = dateResult.remainingText;
    final dateTime = dateResult.dateTime;

    // 2. Bóc tách Số tiền & Tiền tệ (Amount & Currency Extraction)
    final amountResult = _extractAmount(textWithoutDate, defaultCurrency);
    if (amountResult == null || amountResult.amount <= 0) {
      return null;
    }
    final textWithoutAmount = amountResult.remainingText;
    final amount = amountResult.amount;
    final currency = amountResult.currency;

    // 3. Nhận diện Ý định (Transfer vs Income vs Expense)
    final normalized = _removeDiacritics(rawText.toLowerCase());
    final isTransfer = _isTransferIntent(normalized);
    final isIncome = !isTransfer && _isIncomeIntent(normalized);
    final int type = isTransfer
        ? AppConstants.TRANSFER
        : (isIncome ? AppConstants.INCOME : AppConstants.EXPENSE);

    // 4. Xử lý riêng luồng Transfer (Chuyển khoản)
    if (type == AppConstants.TRANSFER) {
      return _parseTransfer(
        originalInput: input,
        rawText: textWithoutAmount,
        amount: amount,
        currency: currency,
        dateTime: dateTime,
        locale: categoryLocale,
      );
    }

    // 5. Bóc tách Ví / Phương thức thanh toán (Wallet Resolution)
    final walletResult = _extractWallet(textWithoutAmount);
    final textWithoutWallet = walletResult.remainingText;
    final wallet = walletResult.wallet ?? _getDefaultWallet();

    // 6. Bóc tách Địa điểm / Quán / Ghi chú (Location / Note Extraction)
    final locationResult = _extractLocation(textWithoutWallet);
    final textWithoutLocation = locationResult.remainingText;
    final location = locationResult.location;

    // 7. Làm sạch Nội dung giao dịch (Content Cleaning)
    final cleanContent = _cleanContent(textWithoutLocation, type, locale);

    // 8. Phân loại Danh mục (Category Classification)
    final masterCategoryId = _resolveMasterCategoryId(
      cleanContent,
      normalized,
      type,
      categoryLocale,
    );

    final finalContent = cleanContent.isNotEmpty
        ? cleanContent
        : _getDefaultContent(type, masterCategoryId, categoryLocale);

    final transactionData = TransactionData(
      requestId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      amount: amount,
      currency: currency,
      content: finalContent,
      wallet: wallet,
      dateTime: dateTime.toIso8601String(),
      category: masterCategoryId,
      note: location,
    );

    return PromptResult(
      requestId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      userPrompt: input,
      data: transactionData,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. DATE / TIME EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────────

  static _DateExtractionResult _extractDateTime(String text) {
    final r = _r;
    final now = DateTime.now();
    var working = text;
    DateTime? detectedDate;

    // A. Explicit dates: ngày 15/05, 15/5/2026, 15-05, on 15/05
    final explicitDateRegex = RegExp(
      r'\b(?:ngày|ngay|on)?\s*(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
      caseSensitive: false,
    );
    final explicitMatch = explicitDateRegex.firstMatch(working);
    if (explicitMatch != null) {
      final day = int.tryParse(explicitMatch.group(1) ?? '');
      final month = int.tryParse(explicitMatch.group(2) ?? '');
      var year = int.tryParse(explicitMatch.group(3) ?? '') ?? now.year;
      if (year < 100) year += 2000;

      if (day != null &&
          month != null &&
          day >= 1 &&
          day <= 31 &&
          month >= 1 &&
          month <= 12) {
        detectedDate = DateTime(year, month, day, now.hour, now.minute);
        working =
            working.replaceRange(explicitMatch.start, explicitMatch.end, ' ');
      }
    }

    if (detectedDate == null) {
      final normalized = _removeDiacritics(working.toLowerCase());

      // B. N days ago: 2 ngày trước, 3 ngay truoc, 2 days ago
      final nDaysMatch = r.nDaysAgoRegex.firstMatch(normalized);
      if (nDaysMatch != null) {
        final days = int.tryParse(nDaysMatch.group(1) ?? '') ?? 0;
        detectedDate = now.subtract(Duration(days: days));
        // _removeDiacritics giữ nguyên độ dài nên dùng được vị trí match trên text gốc
        if (normalized.length == working.length) {
          working = working.replaceRange(nDaysMatch.start, nDaysMatch.end, ' ');
        }
      }
    }

    if (detectedDate == null) {
      // C. Relative keywords (thứ tự trong pack = thứ tự ưu tiên)
      for (final entry in r.relativeDays) {
        if (entry.pattern.hasMatch(working)) {
          detectedDate = now.add(Duration(days: entry.offsetDays));
          working = working.replaceFirst(entry.pattern, ' ');
          break;
        }
      }
    }

    return _DateExtractionResult(
      dateTime: detectedDate ?? now,
      remainingText: _clean(working),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. AMOUNT & CURRENCY EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────────

  static _AmountExtractionResult? _extractAmount(
      String text, String defaultCurrency) {
    final r = _r;

    // Pattern 1: Currency prefix: $15, S$ 8.50, ₫50,000, €25, £10
    final prefixMatch = r.prefixPattern.firstMatch(text);
    if (prefixMatch != null) {
      final symbol = prefixMatch.group(1)?.toLowerCase() ?? '';
      final intPart = prefixMatch.group(2) ?? '0';
      final decPart = prefixMatch.group(3);

      final amount = _parseFormattedNumber(intPart, decPart);
      if (amount > 0) {
        final currency = r.currencySymbols[symbol] ?? defaultCurrency;
        final remaining =
            text.replaceRange(prefixMatch.start, prefixMatch.end, ' ');
        return _AmountExtractionResult(
          amount: amount,
          currency: currency,
          remainingText: _clean(remaining),
        );
      }
    }

    // Pattern 2: Number with suffix multiplier / currency:
    // e.g. 35k, 50 nghìn, 1.5tr, 2 triệu, 2 củ, 1 lít, 3.50 dollars, 12 SGD, 50.000đ
    final suffixMatch = r.suffixPattern.firstMatch(text);
    if (suffixMatch != null) {
      final numStr = suffixMatch.group(1)!;
      final unit = suffixMatch.group(2)!.toLowerCase();

      final parsedNum = _parseFlexibleNumber(numStr);
      final unitInfo = r.unitFor(unit);
      final multiplier = unitInfo?.multiplier ?? 1.0;
      final currency = unitInfo?.currency ?? defaultCurrency;
      final amount = parsedNum * multiplier;

      if (amount > 0) {
        final remaining =
            text.replaceRange(suffixMatch.start, suffixMatch.end, ' ');
        return _AmountExtractionResult(
          amount: amount,
          currency: currency,
          remainingText: _clean(remaining),
        );
      }
    }

    // Pattern 3: Standalone number without suffix (e.g. "Kopi 1.80", "Ăn trưa 35000", "Taxi 50,000")
    final standalonePattern = RegExp(
      r'(?:^|\s+)(\d{1,3}(?:[.,]\d{3})+|\d+(?:[.,]\d{1,2})?)(?=$|\s|[.,;!?])',
    );

    final matches = standalonePattern.allMatches(text).toList();
    if (matches.isNotEmpty) {
      // Find the match that is most likely the amount (usually the last numeric token in sentence)
      final match = matches.last;
      final raw = match.group(1)!;
      final amount = _parseFlexibleNumber(raw);
      if (amount > 0) {
        final remaining = text.replaceRange(match.start, match.end, ' ');
        return _AmountExtractionResult(
          amount: amount,
          currency: defaultCurrency,
          remainingText: _clean(remaining),
        );
      }
    }

    return null;
  }

  static double _parseFormattedNumber(String intPart, String? decPart) {
    final cleanInt = intPart.replaceAll('.', '').replaceAll(',', '');
    final intVal = double.tryParse(cleanInt) ?? 0.0;
    if (decPart != null && decPart.isNotEmpty) {
      final decVal = double.tryParse('0.$decPart') ?? 0.0;
      return intVal + decVal;
    }
    return intVal;
  }

  static double _parseFlexibleNumber(String raw) {
    var val = raw.trim();
    if (val.contains(',') && val.contains('.')) {
      // 1,234.56 or 1.234,56
      if (val.indexOf(',') < val.indexOf('.')) {
        val = val.replaceAll(',', '');
      } else {
        val = val.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (val.contains(',')) {
      final parts = val.split(',');
      if (parts.last.length == 3) {
        // 50,000 -> thousands separator
        val = val.replaceAll(',', '');
      } else {
        // 1,5 -> decimal
        val = val.replaceAll(',', '.');
      }
    } else if (val.contains('.')) {
      final parts = val.split('.');
      if (parts.last.length == 3) {
        // 50.000 -> thousands separator in VN
        val = val.replaceAll('.', '');
      }
    }
    return double.tryParse(val) ?? 0.0;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. INTENT DETECTION (TRANSFER / INCOME / EXPENSE)
  // ─────────────────────────────────────────────────────────────────────────────

  static bool _isTransferIntent(String normalized) =>
      _r.transferIntentRegex.hasMatch(normalized);

  static bool _isIncomeIntent(String normalized) =>
      _r.incomeIntentRegex.hasMatch(normalized);

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. TRANSFER HANDLER
  // ─────────────────────────────────────────────────────────────────────────────

  static PromptResult? _parseTransfer({
    required String originalInput,
    required String rawText,
    required double amount,
    required String currency,
    required DateTime dateTime,
    required String locale,
  }) {
    final r = _r;
    var working = rawText;
    // Remove transfer action verbs
    working = working.replaceFirst(r.transferVerbRegex, ' ');
    working = _clean(working);

    final normalized = _removeDiacritics(working.toLowerCase());

    String? fromHint;
    String? toHint;

    // Pattern A: từ X sang/đến/qua/vào Y / from X to Y
    final fromToMatch = r.fromToPattern.firstMatch(working);

    if (fromToMatch != null) {
      fromHint = fromToMatch.group(1)?.trim();
      toHint = fromToMatch.group(2)?.trim();
    } else {
      // Pattern B: X sang/đến/qua Y
      final sepMatch = r.separatorPattern.firstMatch(working);
      if (sepMatch != null) {
        fromHint = working.substring(0, sepMatch.start).trim();
        toHint = sepMatch.group(2)?.trim();
        fromHint = fromHint.replaceFirst(r.fromPrefixRegex, '').trim();
      } else if (r.withdrawHints.any(normalized.contains)) {
        // Rút từ X về tiền mặt
        fromHint = working.replaceFirst(r.fromPrefixRegex, '').trim();
        toHint = locale == 'en' ? 'cash' : 'tiền mặt';
      }
    }

    final fromWallet = (fromHint != null && fromHint.isNotEmpty)
        ? _resolveWalletByHint(fromHint)
        : _getDefaultWallet();
    final toWallet = (toHint != null && toHint.isNotEmpty)
        ? _resolveWalletByHint(toHint)
        : null;

    final isEn = locale.toLowerCase().startsWith('en');
    final content = isEn
        ? (_joinNonEmpty([
              'Transfer',
              fromWallet != null
                  ? 'from ${fromWallet.name}'
                  : (fromHint != null && fromHint.isNotEmpty
                      ? 'from $fromHint'
                      : null),
              toWallet != null
                  ? 'to ${toWallet.name}'
                  : (toHint != null && toHint.isNotEmpty ? 'to $toHint' : null),
            ]) ??
            'Transfer')
        : (_joinNonEmpty([
              'Chuyển khoản',
              fromWallet != null
                  ? 'từ ${fromWallet.name}'
                  : (fromHint != null && fromHint.isNotEmpty
                      ? 'từ $fromHint'
                      : null),
              toWallet != null
                  ? 'đến ${toWallet.name}'
                  : (toHint != null && toHint.isNotEmpty
                      ? 'đến $toHint'
                      : null),
            ]) ??
            'Chuyển khoản');

    final data = TransactionData(
      requestId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      type: AppConstants.TRANSFER,
      amount: amount,
      receiveAmount: amount,
      currency: currency,
      content: content,
      wallet: fromWallet,
      toWallet: toWallet,
      dateTime: dateTime.toIso8601String(),
      category: 0,
      note: null,
    );

    return PromptResult(
      requestId: 'local-${DateTime.now().microsecondsSinceEpoch}',
      userPrompt: originalInput,
      data: data,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. WALLET EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────────

  static _WalletExtractionResult _extractWallet(String text) {
    final wallets = MasterDataStore().wallets;
    if (wallets.isEmpty) {
      return _WalletExtractionResult(wallet: null, remainingText: text);
    }

    var working = text;
    WalletModel? matchedWallet;

    // A. Explicit wallet prepositions: bằng ví VCB, qua momo, using cash, via bank
    final matches = _r.walletPrepPattern.allMatches(working).toList();
    for (final match in matches) {
      final hint = match.group(2)!.trim();
      final resolved = _resolveWalletByHint(hint);
      if (resolved != null) {
        matchedWallet = resolved;
        working = working.replaceRange(match.start, match.end, ' ');
        break;
      }
    }

    // B. Direct wallet name lookup if not found with preposition
    if (matchedWallet == null) {
      for (final w in wallets) {
        final wName = w.name.toLowerCase();
        final regex = RegExp(
            r'(?:^|\s+)' + RegExp.escape(wName) + r'(?=$|\s|[.,;!?])',
            caseSensitive: false);
        if (regex.hasMatch(working)) {
          matchedWallet = w;
          working = working.replaceFirst(regex, ' ');
          break;
        }
      }
    }

    return _WalletExtractionResult(
      wallet: matchedWallet,
      remainingText: _clean(working),
    );
  }

  static bool _containsAny(String text, List<String> terms) {
    for (final t in terms) {
      if (text.contains(t)) return true;
    }
    return false;
  }

  static WalletModel? _resolveWalletByHint(String hint) {
    final r = _r;
    final cleanHint = _removeDiacritics(hint.toLowerCase().trim());
    if (cleanHint.isEmpty) return null;

    final wallets = MasterDataStore().wallets;
    for (final w in wallets) {
      final wNameClean = _removeDiacritics(w.name.toLowerCase().trim());
      if (wNameClean == cleanHint ||
          wNameClean.contains(cleanHint) ||
          cleanHint.contains(wNameClean)) {
        return w;
      }
      // Aliases
      if (_containsAny(cleanHint, r.cashTerms) &&
          _containsAny(wNameClean, r.cashTerms)) {
        return w;
      }
      if (_containsAny(cleanHint, r.bankHintTerms) &&
          (_containsAny(wNameClean, r.bankWalletTerms) ||
              w.walletType == 'bank')) {
        return w;
      }
    }
    return null;
  }

  static WalletModel? _getDefaultWallet() {
    final wallets = MasterDataStore().wallets;
    return wallets.isNotEmpty ? wallets.first : null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. LOCATION / NOTE EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────────

  static _LocationExtractionResult _extractLocation(String text) {
    final r = _r;
    var working = text;
    String? location;

    // Prepositions: ở Highlands, tại Circle K, at Starbucks, in food court
    final match = r.locationPattern.firstMatch(working);
    if (match != null) {
      final prep = _removeDiacritics(match.group(1)!.toLowerCase());
      final rawLoc = match.group(2)!.trim();

      // Check that it's not a common category word (e.g. "quán cafe" -> cafe is category, not location)
      final normLoc = _removeDiacritics(rawLoc.toLowerCase());
      if (r.locationQuanPrepositions.contains(prep) &&
          r.locationQuanExceptions.contains(normLoc)) {
        // Keep as content
        return _LocationExtractionResult(location: null, remainingText: text);
      }

      location = rawLoc;
      working = working.replaceRange(match.start, match.end, ' ');
    }

    return _LocationExtractionResult(
      location: location != null && location.isNotEmpty ? location : null,
      remainingText: _clean(working),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. CONTENT CLEANING
  // ─────────────────────────────────────────────────────────────────────────────

  static String _cleanContent(String text, int type, String locale) {
    final r = _r;
    var working = text;

    // Strip leading action verbs
    working = working.replaceFirst(r.leadingVerbRegex, '');

    // Don't strip 'tiền' if it's 'tiền nhà', 'tiền điện', 'tiền nước', 'tiền mạng'
    final norm = _removeDiacritics(working.toLowerCase());
    if (!_containsAny(norm, r.keepTienPhrases)) {
      // Strip common filler words
      working = working.replaceAll(r.fillerRegex, ' ');
    }

    working = _clean(working);
    if (working.isEmpty) return '';

    // Capitalize first letter
    return working[0].toUpperCase() + working.substring(1);
  }

  static String _getDefaultContent(int type, int categoryId, String locale) {
    if (type == AppConstants.INCOME) {
      return locale == 'vi' ? 'Thu nhập' : 'Income';
    }
    return locale == 'vi' ? 'Chi tiêu' : 'Expense';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. CATEGORY CLASSIFICATION
  // ─────────────────────────────────────────────────────────────────────────────

  static int? _firstMatch(List<CategoryAliases> groups, String text) {
    for (final g in groups) {
      for (final kw in g.keywords) {
        if (_hasWordOrPhrase(text, kw)) return g.id;
      }
    }
    return null;
  }

  static int _resolveMasterCategoryId(
    String content,
    String fullSentenceNormalized,
    int type,
    String locale,
  ) {
    final r = _r;
    final textNorm = _removeDiacritics(content.toLowerCase());
    final fullNorm = fullSentenceNormalized;

    if (type == AppConstants.INCOME) {
      for (final g in r.incomeCategories) {
        for (final kw in g.keywords) {
          if (_hasWordOrPhrase(textNorm, kw) ||
              _hasWordOrPhrase(fullNorm, kw)) {
            return g.id;
          }
        }
      }
      return r.defaultIncomeCategory;
    }

    // Expense: 1. khớp theo nội dung chính (textNorm): nhóm general trước rồi tới specific
    var id = _firstMatch(r.expenseGeneralCategories, textNorm) ??
        _firstMatch(r.expenseSpecificCategories, textNorm);
    if (id != null) return id;

    // 2. Khớp theo cả câu nếu nội dung chính chưa xác định được
    id = _firstMatch(r.expenseGeneralCategories, fullNorm) ??
        _firstMatch(r.expenseSpecificCategories, fullNorm);
    if (id != null) return id;

    return r.defaultExpenseCategory;
  }

  static bool _hasWordOrPhrase(String text, String keyword) {
    if (keyword.contains(' ')) {
      return text.contains(keyword);
    }
    return RegExp(r'(?:^|\s+)' + RegExp.escape(keyword) + r'(?=$|\s+)')
        .hasMatch(text);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPER UTILITIES
  // ─────────────────────────────────────────────────────────────────────────────

  static String _clean(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String? _joinNonEmpty(List<String?> parts) {
    final values = parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    if (values.isEmpty) return null;
    return values.join(' ');
  }

  static String _removeDiacritics(String value) => removeDiacriticsVi(value);

  static String _categoryLocale(String locale) {
    final normalized = locale.toLowerCase();
    if (normalized.startsWith('en')) return 'en';
    return 'vi';
  }
}

class _DateExtractionResult {
  final DateTime dateTime;
  final String remainingText;
  const _DateExtractionResult(
      {required this.dateTime, required this.remainingText});
}

class _AmountExtractionResult {
  final double amount;
  final String currency;
  final String remainingText;
  const _AmountExtractionResult({
    required this.amount,
    required this.currency,
    required this.remainingText,
  });
}

class _WalletExtractionResult {
  final WalletModel? wallet;
  final String remainingText;
  const _WalletExtractionResult(
      {required this.wallet, required this.remainingText});
}

class _LocationExtractionResult {
  final String? location;
  final String remainingText;
  const _LocationExtractionResult(
      {required this.location, required this.remainingText});
}
