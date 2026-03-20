import 'package:taexpense/models/transaction_data.dart';

class PromptResult {
  final String requestId;
  final String userPrompt;
  final TransactionData data;

  PromptResult({required this.requestId, required this.userPrompt, required this.data});

  factory PromptResult.fromJson(Map<String, dynamic> j) => PromptResult(
    requestId: j['request_id'] ?? '',
    userPrompt: j['user_prompt'] ?? '',
    data: TransactionData.fromJson(j['data'] as Map<String, dynamic>),
  );
}