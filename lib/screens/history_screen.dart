import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/screens/edit_transaction_screen.dart';
import 'package:taexpense/screens/transaction_detail_sheet.dart';
import 'package:taexpense/services/transaction_service.dart' as TransactionService;
import 'package:taexpense/utils/material_icons_map.dart';
import 'package:taexpense/utils/utils.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../services/transaction_service.dart';
import '../session.dart';
import '../theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ── Filter preset ──────────────────────────────────────────────────────────────

enum _DatePreset { today, thisWeek, thisMonth, thisYear, custom }

extension _DatePresetRange on _DatePreset {
  (DateTime, DateTime) get range {
    final now = DateTime.now();
    switch (this) {
      case _DatePreset.today:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case _DatePreset.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return (
          DateTime(monday.year, monday.month, monday.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case _DatePreset.thisMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case _DatePreset.thisYear:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case _DatePreset.custom:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  String? _error;

  _DatePreset _preset = _DatePreset.thisMonth;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    // ← dùng local var trước, rồi assign vào instance
    final range = _preset.range;
    _from = range.$1;
    _to   = range.$2;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await getTransactions(
        Session.token!,
        fromDate: _from.toIso8601String(),
        toDate: _to.toIso8601String(),
      );
      setState(() { _txns = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Chọn preset nhanh
  void _selectPreset(_DatePreset p) {
    final range = p.range;
    setState(() {
      _preset = p;
      _from   = range.$1;
      _to     = range.$2;
    });
    _load();
  }

  // Picker tuỳ chọn từ–đến
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final from = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Từ ngày',
      builder: (ctx, child) => _blueTheme(ctx, child!),
    );
    if (from == null || !mounted) return;

    final to = await showDatePicker(
      context: context,
      initialDate: _to.isBefore(from) ? from : _to,
      firstDate: from,
      lastDate: now,
      helpText: 'Đến ngày',
      builder: (ctx, child) => _blueTheme(ctx, child!),
    );
    if (to == null || !mounted) return;

    setState(() {
      _preset = _DatePreset.custom;
      _from = DateTime(from.year, from.month, from.day);
      _to   = DateTime(to.year,   to.month,   to.day, 23, 59, 59);
    });
    _load();
  }

  Widget _blueTheme(BuildContext ctx, Widget child) => Theme(
    data: ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(primary: kPrimary),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FilterBar(
          preset: _preset,
          from: _from,
          to: _to,
          onPreset: _selectPreset,
          onCustom: _pickCustomRange,
          t: t,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: kPrimary,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _error != null
                    ? _buildError()
                    : _txns.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ),
      ],
    );
  }

  Widget _buildError() => ListView(children: [
    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
    Center(child: Column(children: [
      Icon(Icons.wifi_off_rounded, size: 48, color: kBorder),
      const SizedBox(height: 12),
      Text(_error!, style: GoogleFonts.dmSans(color: kSubtext)),
      const SizedBox(height: 16),
      TextButton(onPressed: _load, child: const Text('Retry')),
    ])),
  ]);

  Widget _buildEmpty() => ListView(children: [
    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
    Center(child: Column(children: [
      Icon(Icons.receipt_long_outlined, size: 64, color: kBorder),
      const SizedBox(height: 16),
      Text('Không có giao dịch',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700, color: kSubtext)),
    ])),
  ]);

  Widget _buildList() => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _txns.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (ctx, i) => _TxnTile(
      txn: _txns[i],
      onRefresh: _load,         // để detail sheet có thể trigger reload
    ),
  );
}

// ── Filter bar ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _DatePreset preset;
  final DateTime from;
  final DateTime to;
  final ValueChanged<_DatePreset> onPreset;
  final VoidCallback onCustom;
  final AppLocalizations t;

  const _FilterBar({
    required this.preset,
    required this.from,
    required this.to,
    required this.onPreset,
    required this.onCustom,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final labels = <_DatePreset, String>{
      _DatePreset.today:     'Hôm nay',
      _DatePreset.thisWeek:  'Tuần này',
      _DatePreset.thisMonth: 'Tháng này',
      _DatePreset.thisYear:  'Năm nay',
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...labels.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PresetChip(
                    label: e.value,
                    active: preset == e.key,
                    onTap: () => onPreset(e.key),
                  ),
                )),
                _PresetChip(
                  label: 'Tuỳ chọn',
                  icon: Icons.date_range_outlined,
                  active: preset == _DatePreset.custom,
                  onTap: onCustom,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date range display
          GestureDetector(
            onTap: onCustom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 15, color: kSubtext),
                const SizedBox(width: 8),
                Text('Từ ', style: GoogleFonts.dmSans(fontSize: 13, color: kSubtext)),
                Text(fmt.format(from),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
                Text('  →  ', style: GoogleFonts.dmSans(fontSize: 13, color: kSubtext)),
                Text('Đến ', style: GoogleFonts.dmSans(fontSize: 13, color: kSubtext)),
                Text(fmt.format(to),
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
                const Spacer(),
                Icon(Icons.edit_outlined, size: 14, color: kPrimary),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? kPrimary : kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: active ? Colors.white : kSubtext),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : kSubtext,
            )),
      ]),
    ),
  );
}

// ── Tile (StatefulWidget để có context đúng) ───────────────────────────────────

class _TxnTile extends StatefulWidget {
  final Map<String, dynamic> txn;
  final VoidCallback onRefresh;

  const _TxnTile({required this.txn, required this.onRefresh});

  @override
  State<_TxnTile> createState() => _TxnTileState();
}

class _TxnTileState extends State<_TxnTile> {
  @override
  Widget build(BuildContext context) {
    final txn     = widget.txn;
    final amount  = (txn['amount'] as num).toDouble();
    final type    = txn['type'] ?? AppConstants.EXPENSE;
    final category = txn['category'] ?? 'Other';
    final wallet  = txn['wallet'] ?? '';
    final content = txn['content'];
    final note    = txn['note'];

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(children: [
          TransactionIconWidget(type: type, radius: 20, iconSize: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content ?? category,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: kText)),
                Text(category,
                    style: GoogleFonts.dmSans(fontSize: 12.5, color: kSubtext)),
                if (note != null && (note as String).isNotEmpty)
                  Text(note,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: kSubtext.withOpacity(0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 12, color: kSubtext),
                  const SizedBox(width: 3),
                  Text(wallet,
                      style: GoogleFonts.dmSans(
                          fontSize: 11.5, color: kSubtext)),
                  const SizedBox(width: 8),
                  Text('• ${Utils.formattedServerDateTime(txn['date_time'])}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11.5, color: kSubtext)),
                ]),
              ],
            ),
          ),
          AmountText(amount: amount, type: type),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final t = AppLocalizations.of(context)!;   // ← context đúng, từ State
    showModalBottomSheet(
      context: context,
      useSafeArea: true, 
      isScrollControlled: true, 
      useRootNavigator: true,          // ← tránh bị chặn bởi bottom nav
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(
        data: widget.txn,
        t: t,
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTransactionScreen(
                transactionId: widget.txn['id'] as int,
              ),
            ),
          ).then((_) => widget.onRefresh()); // refresh sau khi edit xong
        }, 
        onDelete: () async {
          Navigator.pop(context); // đóng bottom sheet trước
          try {
            await TransactionService.deleteTransaction(
                widget.txn['id'], Session.token!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Đã xoá giao dịch',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                backgroundColor: kError,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
              
              // _loadPeriodAndFetch();
              
            }
          } on TransactionService.ApiException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.message),
                backgroundColor: kError,
              ));
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Không thể kết nối server.'),
                backgroundColor: kError,
              ));
            }
          }
        },
      ),
    );
  }
}