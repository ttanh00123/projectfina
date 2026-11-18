import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/prompt_result.dart';
import 'package:taexpense/services/local_transaction_parser.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/parser_rules.dart';
import 'package:taexpense/services/remote_categorizer.dart';
import 'package:taexpense/services/settings_service.dart';

final _defaultRemoteCategorizer = RemoteCategorizer(
  endpoint: Uri.parse(AppConstants.CATEGORY_CLASSIFICATION_API),
);

Future<PromptResult?> sendPrompt(
  String text,
  int userId,
  String token, {
  RemoteCategorizer? remoteCategorizer,
}) async {
  final currency = await SettingsService.getCurrency();
  final languageCode = await SettingsService.getLocale();

  final localResult = LocalTransactionParser.parse(
    text,
    defaultCurrency: currency,
    locale: languageCode,
  );
  if (localResult == null) return null;

  final transaction = localResult.data;
  if (transaction.type == AppConstants.TRANSFER) return localResult;

  final rules = ParserRulesStore.current;
  final fallbackCategoryId = transaction.type == AppConstants.INCOME
      ? rules.defaultIncomeCategory
      : rules.defaultExpenseCategory;
  if (transaction.category != fallbackCategoryId) return localResult;

  final allowedCategoryIds = MasterDataStore()
      .categories
      .where((category) =>
          (category.type == transaction.type || category.type == 2) &&
          category.id != rules.defaultExpenseCategory &&
          category.id != rules.defaultIncomeCategory)
      .map((category) => category.id)
      .toSet();

  final categoryId = await (remoteCategorizer ?? _defaultRemoteCategorizer)
      .categorize(
    text: text,
    isIncome: transaction.type == AppConstants.INCOME,
    allowedIds: allowedCategoryIds,
    authToken: token,
    locale: languageCode,
  );
  if (categoryId == null) return localResult;

  return PromptResult(
    requestId: localResult.requestId,
    userPrompt: localResult.userPrompt,
    data: transaction.copyWith(category: categoryId),
  );
}
