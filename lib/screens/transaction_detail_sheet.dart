import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/transaction_service.dart' as TransactionService;
import 'package:taexpense/session.dart';
import 'package:taexpense/theme/app_theme.dart';
import 'package:taexpense/utils/utils.dart';
import 'package:taexpense/widgets/fina_widgets.dart';

class TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppLocalizations t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  

  const TransactionDetailSheet({
    required this.data,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type     = data['type'] as int;
    final amount   = data['amount'] as double;
    final currency = data['currency'] as String? ?? 'VND';
    final content  = data['content'] as String? ?? '';
    final catId    = data['category_id'] as int?;
    final dtStr    = data['date_time'] as String?;
    final color    = data['wallet_color'] as String? ?? '#1D9E75';

    
    final isExpense = type == 0;
    final isIncome = type == 1;
    final isTransfer = type == 2;

    final String typeLabel = isExpense ? t.expense : isIncome ? t.income : t.transfer;
    final String amountDisplay = Utils.moneyFormatFromDouble(amount);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // hoặc Theme.of(context).colorScheme.surface
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: icon + type + amount + badge
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                TransactionIconWidget(type: type, radius: 28, iconSize: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(typeLabel,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      AmountText(amount: amount, type: type, fontSize: 18, fontWeight: FontWeight.w700),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.confirmed, // thêm localization key này
                    style: TextStyle(
                        fontSize: 12, color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Detail rows
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.title_outlined,
                  label: t.content,
                  value: data['content'] ?? '-',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.label_outline_rounded,
                  label: t.category,
                  value: MasterDataStore().categoryName(data['category_id'] as int?),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: t.wallet,
                  value: MasterDataStore().walletName(data['wallet_id'] as int?),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: t.date,
                  value: Utils.formattedServerDateTime(dtStr)
                ),
                
                if ((data['note'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: t.note,
                    value: data['note'],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red),
                    label: Text(t.delete,
                        style: const TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(t.edit),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá giao dịch',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá giao dịch này không?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ', style: GoogleFonts.dmSans(color: kSubtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // ← trả true
            child: Text('Xoá',
                style: GoogleFonts.dmSans(
                    color: kError, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    onDelete(); // ← gọi callback, logic xử lý ở parent
  }
  
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Icon(icon, size: 18, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

