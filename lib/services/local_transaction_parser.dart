// lib/services/local_transaction_parser.dart

import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/models/transaction_data.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/services/master_data_store.dart';

class LocalTransactionParser {
  /// Entry point to parse natural language transaction offline.
  /// Returns a [PromptResult] if parsed successfully, or null if cannot parse.
  static PromptResult? parse(
    String input, {
    String defaultCurrency = 'VND',
    String locale = 'vi',
  }) {
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
      final nDaysAgoRegex =
          RegExp(r'\b(\d+)\s*(?:ngày trước|ngay truoc|days ago)\b');
      final nDaysMatch = nDaysAgoRegex.firstMatch(normalized);
      if (nDaysMatch != null) {
        final days = int.tryParse(nDaysMatch.group(1) ?? '') ?? 0;
        detectedDate = now.subtract(Duration(days: days));
        working = working.replaceFirst(
            RegExp(r'\b' + RegExp.escape(nDaysMatch.group(0)!) + r'\b',
                caseSensitive: false),
            ' ');
      }
    }

    if (detectedDate == null) {
      // C. Relative keywords
      final relativeMap = <String, int>{
        // -2 days
        'hôm kia': -2,
        'hom kia': -2,
        'the day before yesterday': -2,
        // -1 day
        'hôm qua': -1,
        'hom qua': -1,
        'tối qua': -1,
        'toi qua': -1,
        'sáng qua': -1,
        'sang qua': -1,
        'chiều qua': -1,
        'chieu qua': -1,
        'yesterday': -1,
        'last night': -1,
        // today (0)
        'hôm nay': 0,
        'hom nay': 0,
        'sáng nay': 0,
        'sang nay': 0,
        'trưa nay': 0,
        'trua nay': 0,
        'chiều nay': 0,
        'chieu nay': 0,
        'tối nay': 0,
        'toi nay': 0,
        'today': 0,
        'this morning': 0,
        'this afternoon': 0,
        'tonight': 0,
      };

      for (final entry in relativeMap.entries) {
        final pattern = RegExp(r'\b' + entry.key + r'\b', caseSensitive: false);
        if (pattern.hasMatch(working)) {
          detectedDate = now.add(Duration(days: entry.value));
          working = working.replaceFirst(pattern, ' ');
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
    // Pattern 1: Currency prefix: $15, S$ 8.50, ₫50,000, €25, £10
    final prefixPattern = RegExp(
      r'(?:^|\s+)(\$|s\$|us\$|a\$|₫|đ|€|£|¥)\s*(\d{1,3}(?:[.,]\d{3})*|\d+)(?:[.,](\d{1,2}))?(?=$|\s|[.,;!?])',
      caseSensitive: false,
    );

    final prefixMatch = prefixPattern.firstMatch(text);
    if (prefixMatch != null) {
      final symbol = prefixMatch.group(1)?.toLowerCase() ?? '';
      final intPart = prefixMatch.group(2) ?? '0';
      final decPart = prefixMatch.group(3);

      final amount = _parseFormattedNumber(intPart, decPart);
      if (amount > 0) {
        final currency = _resolveCurrencyFromSymbol(symbol, defaultCurrency);
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
    // Use lookahead (?=$|\s|[.,;!?]) instead of \b to reliably match non-ASCII characters like 'củ', 'lít'
    final suffixPattern = RegExp(
      r'(?:^|\b)(\d+(?:[.,]\d+)?)\s*(k|nghìn|nghin|ngàn|ngan|tr|triệu|trieu|m|củ|cu|lít|lit|xị|xi|tỷ|ty|b|đ|₫|vnd|usd|sgd|eur|gbp|dollars?|bucks?)(?=$|\s|[.,;!?])',
      caseSensitive: false,
    );

    final suffixMatch = suffixPattern.firstMatch(text);
    if (suffixMatch != null) {
      final numStr = suffixMatch.group(1)!;
      final unit = suffixMatch.group(2)!.toLowerCase();

      final parsedNum = _parseFlexibleNumber(numStr);
      final multiplier = _getMultiplier(unit);
      final currency = _resolveCurrencyFromUnit(unit, defaultCurrency);
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

  static double _getMultiplier(String unit) {
    switch (_removeDiacritics(unit)) {
      case 'k':
      case 'nghin':
      case 'ngan':
        return 1000.0;
      case 'lit':
      case 'xi':
        return 100000.0;
      case 'tr':
      case 'trieu':
      case 'm':
      case 'cu':
        return 1000000.0;
      case 'ty':
      case 'b':
        return 1000000000.0;
      default:
        return 1.0;
    }
  }

  static String _resolveCurrencyFromSymbol(String symbol, String fallback) {
    switch (symbol) {
      case r'$':
      case 'us\$':
        return 'USD';
      case r's$':
        return 'SGD';
      case r'a$':
        return 'AUD';
      case '₫':
      case 'đ':
        return 'VND';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      default:
        return fallback;
    }
  }

  static String _resolveCurrencyFromUnit(String unit, String fallback) {
    final u = _removeDiacritics(unit.toLowerCase());
    switch (u) {
      case 'vnd':
      case 'd':
      case 'đ':
      case 'dong':
        return 'VND';
      case 'usd':
      case 'dollar':
      case 'dollars':
      case 'bucks':
        return 'USD';
      case 'sgd':
      case 'sing':
        return 'SGD';
      case 'eur':
      case 'euro':
        return 'EUR';
      case 'gbp':
      case 'pound':
        return 'GBP';
      default:
        return fallback;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. INTENT DETECTION (TRANSFER / INCOME / EXPENSE)
  // ─────────────────────────────────────────────────────────────────────────────

  static bool _isTransferIntent(String normalized) {
    return RegExp(
      r'\b(chuyen khoan|chuyen tien|chuyen|rut tien|rut|ban tien|transfer|transferred|send money|sent money|withdraw|move money|moved money)\b',
    ).hasMatch(normalized);
  }

  static bool _isIncomeIntent(String normalized) {
    return RegExp(
      r'\b(nhan luong|luong|thuong|nhan tien|nhan|thu nhap|ban hang|co tuc|lai|duoc tang|duoc cho|salary|paycheck|bonus|income|received|cashback|dividend|sold|wage)\b',
    ).hasMatch(normalized);
  }

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
    var working = rawText;
    // Remove transfer action verbs
    working = working.replaceFirst(
      RegExp(
        r'\b(chuyển khoản|chuyen khoan|chuyển tiền|chuyen tien|chuyển|chuyen|rút tiền|rut tien|rút|rut|bắn tiền|transfer|transferred|send|withdraw|move)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    working = _clean(working);

    final normalized = _removeDiacritics(working.toLowerCase());

    String? fromHint;
    String? toHint;

    // Pattern A: từ X sang/đến/qua/vào Y / from X to Y
    final fromToPattern = RegExp(
      r'(?:^|\s+)(?:từ|tu|from)\s+([a-zA-Z0-9\s]+?)\s+(?:sang|đến|den|tới|toi|qua|vào|vao|về|ve|to)\s+([a-zA-Z0-9\s]+)',
      caseSensitive: false,
    );
    final fromToMatch = fromToPattern.firstMatch(working);

    if (fromToMatch != null) {
      fromHint = fromToMatch.group(1)?.trim();
      toHint = fromToMatch.group(2)?.trim();
    } else {
      // Pattern B: X sang/đến/qua Y
      final separatorPattern = RegExp(
        r'(?:^|\s+)(sang|đến|den|tới|toi|qua|vào|vao|về|ve|to)\s+([a-zA-Z0-9\s]+)',
        caseSensitive: false,
      );
      final sepMatch = separatorPattern.firstMatch(working);
      if (sepMatch != null) {
        fromHint = working.substring(0, sepMatch.start).trim();
        toHint = sepMatch.group(2)?.trim();
        fromHint = fromHint
            .replaceFirst(
                RegExp(r'^(?:từ|tu|from)\s+', caseSensitive: false), '')
            .trim();
      } else if (normalized.contains('rut') ||
          normalized.contains('withdraw')) {
        // Rút từ X về tiền mặt
        fromHint = working
            .replaceFirst(
                RegExp(r'^(?:từ|tu|from)\s+', caseSensitive: false), '')
            .trim();
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
    final prepPattern = RegExp(
      r'(?:^|\s+)(bằng ví|bang vi|bằng|bang|qua|từ|tu|ví|vi|using|via|with|by|through)\s+([a-zA-Z0-9\s]+?)(?=$|\s|[.,;!?])',
      caseSensitive: false,
    );

    final matches = prepPattern.allMatches(working).toList();
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

  static WalletModel? _resolveWalletByHint(String hint) {
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
      if ((cleanHint.contains('tien mat') || cleanHint.contains('cash')) &&
          (wNameClean.contains('tien mat') || wNameClean.contains('cash'))) {
        return w;
      }
      if ((cleanHint.contains('bank') ||
              cleanHint.contains('ngan hang') ||
              cleanHint.contains('tai khoan')) &&
          (wNameClean.contains('bank') ||
              wNameClean.contains('ngan hang') ||
              w.walletType.nameKey == 'wallet_type.bank')) {
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
    var working = text;
    String? location;

    // Prepositions: ở Highlands, tại Circle K, at Starbucks, in food court
    final locPattern = RegExp(
      r'(?:^|\s+)(ở|o|tại|tai|quán|quan|tiệm|tiem|cửa hàng|cua hang|at|in|from)\s+([^,]+)',
      caseSensitive: false,
    );

    final match = locPattern.firstMatch(working);
    if (match != null) {
      final prep = match.group(1)!;
      final rawLoc = match.group(2)!.trim();

      // Check that it's not a common category word (e.g. "quán cafe" -> cafe is category, not location)
      final normLoc = _removeDiacritics(rawLoc.toLowerCase());
      if (prep.toLowerCase() == 'quán' || prep.toLowerCase() == 'quan') {
        if (normLoc == 'cafe' ||
            normLoc == 'ca phe' ||
            normLoc == 'an' ||
            normLoc == 'nhau') {
          // Keep as content
          return _LocationExtractionResult(location: null, remainingText: text);
        }
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
    var working = text;

    // Strip leading action verbs
    final leadingVerbs = RegExp(
      r'^(?:mua hộ|mua ho|mua|ăn|an|uống|uong|trả|tra|thanh toán|thanh toan|chi|đi|di|đổ|do|nạp|nap|thuê|thue|gửi|gui|bán|ban|được tặng|duoc tang|được cho|duoc cho|nhận|nhan|thu|bought|buy|paid|pay|spent|spend|ate|eat|had|drank|drink|ordered|order|got|received)\s+',
      caseSensitive: false,
    );
    working = working.replaceFirst(leadingVerbs, '');

    // Strip common filler words
    final fillers = RegExp(
      r'\b(?:tiền|tien|cho mình|cho minh|hết|het|mất|mat|mình|minh|tôi|toi|for|a|an|the)\b',
      caseSensitive: false,
    );
    // Don't strip 'tiền' if it's 'tiền nhà', 'tiền điện', 'tiền nước', 'tiền mạng'
    final norm = _removeDiacritics(working.toLowerCase());
    if (!norm.contains('tien nha') &&
        !norm.contains('tien dien') &&
        !norm.contains('tien nuoc') &&
        !norm.contains('tien mang') &&
        !norm.contains('tien hoc')) {
      working = working.replaceAll(fillers, ' ');
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
  // 8. CATEGORY CLASSIFICATION (35 CANONICAL CATEGORIES)
  // ─────────────────────────────────────────────────────────────────────────────

  static int _resolveMasterCategoryId(
    String content,
    String fullSentenceNormalized,
    int type,
    String locale,
  ) {
    final textNorm = _removeDiacritics(content.toLowerCase());
    final fullNorm = fullSentenceNormalized;
    final categories = MasterDataStore()
        .categories
        .where((c) => c.type == type)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    var bestCategoryId = type == AppConstants.INCOME ? 35 : 34;
    var bestScore = 0;

    for (final category in categories) {
      final candidates = <String>{
        category.name,
        ...category.keywords,
      };

      for (final candidate in candidates) {
        final keyword = _removeDiacritics(candidate.toLowerCase().trim());
        if (keyword.isEmpty) continue;

        final textScore = _keywordScore(textNorm, keyword, sourceWeight: 100);
        final fullScore = _keywordScore(fullNorm, keyword, sourceWeight: 10);
        final score = textScore > fullScore ? textScore : fullScore;

        if (score > bestScore ||
            (score == bestScore &&
                score > 0 &&
                category.sortOrder <
                    (categories
                            .where((c) => c.id == bestCategoryId)
                            .firstOrNull
                            ?.sortOrder ??
                        9999))) {
          bestScore = score;
          bestCategoryId = category.id;
        }
      }
    }

    return bestCategoryId;
  }

  static int _keywordScore(
    String text,
    String keyword, {
    required int sourceWeight,
  }) {
    if (!_hasWordOrPhrase(text, keyword)) return 0;
    final phraseBonus = keyword.contains(' ') ? 50 : 0;
    return sourceWeight + phraseBonus + keyword.length;
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

  static String _removeDiacritics(String value) {
    var result = value;
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    for (final entry in groups.entries) {
      for (final char in entry.value.split('')) {
        result = result.replaceAll(char, entry.key);
        result = result.replaceAll(char.toUpperCase(), entry.key.toUpperCase());
      }
    }
    return result;
  }

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
