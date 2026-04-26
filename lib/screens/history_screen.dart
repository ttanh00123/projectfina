import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../session.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = Session.token!;
      final data = await getTransactions(token);

      setState(() {
        _txns = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _buildError()
              : _txns.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: kBorder),
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.dmSans(color: kSubtext)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: kBorder),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kSubtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _txns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TxnTile(txn: _txns[i]),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;

  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isExpense = txn['type'] == 'expense';

    final amount = (txn['amount'] as num).toDouble();
    final currency = txn['currency'] ?? 'VND';

    final category = txn['category'] ?? 'Other';
    final wallet = txn['wallet'] ?? '';

    final address = txn['address'];
    final note = txn['note'];

    final amtFmt = NumberFormat('#,##0', 'vi_VN').format(amount);

    DateTime? dt;
    try {
      dt = DateTime.parse(txn['date_time']).toLocal();
    } catch (_) {}

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isExpense ? kExpense : kIncome).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isExpense
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isExpense ? kExpense : kIncome,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          /// LEFT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: kText,
                  ),
                ),

                if (address != null && address.isNotEmpty)
                  Text(
                    address,
                    style: GoogleFonts.dmSans(
                        fontSize: 12.5, color: kSubtext),
                  ),

                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: kSubtext.withOpacity(0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 12, color: kSubtext),
                    const SizedBox(width: 3),
                    Text(
                      wallet,
                      style: GoogleFonts.dmSans(
                          fontSize: 11.5, color: kSubtext),
                    ),
                    if (dt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormat('dd/MM HH:mm').format(dt)}',
                        style: GoogleFonts.dmSans(
                            fontSize: 11.5, color: kSubtext),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          /// RIGHT AMOUNT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}$amtFmt',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? kExpense : kIncome,
                ),
              ),
              Text(
                currency,
                style: GoogleFonts.dmSans(
                    fontSize: 11.5, color: kSubtext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}