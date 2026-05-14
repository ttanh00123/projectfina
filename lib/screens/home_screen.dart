import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/transaction_data.dart';
import 'package:taexpense/screens/wallet_list_screen.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/material_icons_map.dart';
import 'create_transaction_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/fina_widgets.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ── Period enum ────────────────────────────────────────────────────────────────
enum _Period { month, quarter, year }

extension _PeriodExt on _Period {
  String get key => name;
  String label(AppLocalizations t) {
    switch (this) {
      case _Period.month:   return t.thisMonth;
      case _Period.quarter: return t.thisQuarter;
      case _Period.year:    return t.thisYear;
    }
  }
}

// ── Dashboard data model ───────────────────────────────────────────────────────
class _DashboardData {
  final List<Map<String, dynamic>> balances;
  final Map<String, double>        income;
  final Map<String, double>        expense;
  final List<Map<String, dynamic>> recentTx;

  const _DashboardData({
    required this.balances,
    required this.income,
    required this.expense,
    required this.recentTx,
  });

  factory _DashboardData.empty() => const _DashboardData(
    balances: [], income: {}, expense: {}, recentTx: []);

  factory _DashboardData.fromJson(Map<String, dynamic> j) => _DashboardData(
    balances: (j['total_balance'] as List).cast<Map<String, dynamic>>(),
    income:   (j['income']  as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
    expense:  (j['expense'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
    recentTx: (j['recent_transactions'] as List).cast<Map<String, dynamic>>(),
  );
}

// ── HomeScreen ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  static String routeName = "/home-screen";
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // final _pages = const [
  //   _DashboardPage(onNavigate: _onItemTapped),
  //   _ChartPlaceholder(),
  //   SizedBox.shrink(),
  //   HistoryScreen(),
  //   SettingsScreen(),
  // ];

  // Không dùng static vì cần truyền hàm _onItemTapped
  List<Widget> get _pages => [
    _DashboardPage(onNavigate: _onItemTapped), // Truyền callback xuống
    const _ChartPlaceholder(),
    const SizedBox.shrink(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _tab = index;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: SafeArea(
      child: Column(children: [
        _Header(),
        Expanded(child: _tab == 2 ? const SizedBox.shrink() : _pages[_tab]),
      ]),
    ),
    bottomNavigationBar: _BottomNav(
      current: _tab,
      onTap: (i) {
        if (i == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatScreen()));
        } else {
          setState(() => _tab = i);
        }
      },
    ),
  );
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t    = AppLocalizations.of(context)!;
    final user = Session.user;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        const FinaLogo(size: 34),
        const Spacer(),
        if (user != null)
          Text('${t.hi}, ${user.displayName}',
              style: GoogleFonts.dmSans(fontSize: 16, color: kSubtext)),
        const SizedBox(width: 14),
        Stack(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: kBg, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_outlined,
                color: kText, size: 22),
          ),
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: kError, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Dashboard page ─────────────────────────────────────────────────────────────
class _DashboardPage extends StatefulWidget {
  // Khai báo hàm callback trong class cha
  final Function(int) onNavigate;
  const _DashboardPage({super.key, required this.onNavigate});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  _Period       _period  = _Period.month;
  _DashboardData _data   = _DashboardData.empty();
  bool          _loading = true;

  static const _periodKey = 'dashboard_period';

  @override
  void initState() {
    super.initState();
    _loadPeriodAndFetch();
  }

  Future<void> _loadPeriodAndFetch() async {
    final prefs  = await SharedPreferences.getInstance();
    final saved  = prefs.getString(_periodKey) ?? 'month';
    _period = _Period.values.firstWhere(
        (p) => p.key == saved, orElse: () => _Period.month);
    await _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/dashboard/summary'
            '?period=${_period.key}'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) setState(() => _data = _DashboardData.fromJson(json));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPeriod(_Period p) async {
    if (p == _period) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_periodKey, p.key);
    setState(() => _period = p);
    await _fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ────────────────────────────────────────────────
            _BalanceCard(
              data:      _data,
              period:    _period,
              loading:   _loading,
              onPeriod:  _setPeriod,
            ),
            const SizedBox(height: 24),

            // ── Quick actions ────────────────────────────────────────────────
            _QuickActions(onTransactionAdded: _fetchDashboard),
            const SizedBox(height: 24),

            // ── Recent transactions ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.recentTransactions,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
                TextButton(
                  onPressed: () => widget.onNavigate(3),
                  child: Text(t.viewAll,
                      style: GoogleFonts.dmSans(color: kPrimary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _loading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator()))
                : _data.recentTx.isEmpty
                    ? _buildEmpty(t)
                    : _buildTxList(t),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      const Icon(Icons.receipt_long_outlined, size: 48, color: kBorder),
      const SizedBox(height: 12),
      Text(t.noTransactionsYet,
          style: GoogleFonts.dmSans(color: kSubtext)),
      const SizedBox(height: 4),
      Text(t.addYourFirstTransaction,
          style: GoogleFonts.dmSans(
              color: kSubtext.withOpacity(0.7), fontSize: 13)),
    ]),
  );

  void _showTransactionDetails(Map<String, dynamic> value) {
    var t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(value['type'] == 0 ? t.expense : value['type'] == 1 ? t.income : t.transfer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: value.entries.map((e) =>
              Text('${e.key}: ${e.value}')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.close),
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CreateTransactionScreen(
              prefill: TransactionData.fromMap(value),
            ))),
            child: Text(t.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildTxList(AppLocalizations t) => Container(
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        ..._data.recentTx.asMap().entries.map((e) {
          // final last = e.key == _data.recentTx.length - 1;
          return Column(children: [
            InkWell(
              onTap: () => _showTransactionDetails(e.value),
              child: _TxItem(tx: e.value)),
            // if (!last) const Divider(height: 1, indent: 64),
          ]);
        }),
        // // Xem thêm
        // InkWell(
        //   onTap: () => Navigator.push(context,
        //       MaterialPageRoute(builder: (_) => const HistoryScreen())),
        //   borderRadius: const BorderRadius.vertical(
        //       bottom: Radius.circular(16)),
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 14),
        //     child: Center(
        //       child: Text(t.viewAll,
        //           style: GoogleFonts.dmSans(
        //               color: kPrimary,
        //               fontWeight: FontWeight.w600,
        //               fontSize: 14)),
        //     ),
        //   ),
        // ),
      ],
    ),
  );
}

// ── Balance Card ───────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final _DashboardData data;
  final _Period        period;
  final bool           loading;
  final ValueChanged<_Period> onPeriod;
  const _BalanceCard({
    required this.data, required this.period,
    required this.loading, required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Lấy currency chính (theo AppSettings hoặc currency đầu tiên)
    final mainCurrency = data.balances.isNotEmpty
        ? data.balances.first['currency'] as String
        : 'VND';
    final totalBalance = data.balances.isNotEmpty
        ? data.balances.first['amount'] as double
        : 0.0;
    final income  = data.income[mainCurrency]  ?? 0.0;
    final expense = data.expense[mainCurrency] ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [kPrimary, kPrimaryL],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPrimary.withOpacity(0.3),
              blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total balance + period picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.totalBalance,
                  style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 14)),
              // Period selector
              GestureDetector(
                onTap: () => _showPeriodPicker(context, t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(period.label(t),
                        style: GoogleFonts.dmSans(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 16),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total balance amount
          loading
              ? const SizedBox(
                  height: 36,
                  child: Center(child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      color: Colors.white)))
              : Text(
                  _fmt(totalBalance, mainCurrency),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700),
                ),
          const SizedBox(height: 20),

          // Income + Expense
          Row(children: [
            _BalanceStat(
              label:  t.income,
              amount: loading ? '—' : _fmt(income, mainCurrency),
              icon:   Icons.arrow_downward_rounded,
              color:  const Color(0xFF86EFAC),
            ),
            const SizedBox(width: 24),
            _BalanceStat(
              label:  t.expense,
              amount: loading ? '—' : _fmt(expense, mainCurrency),
              icon:   Icons.arrow_upward_rounded,
              color:  const Color(0xFFFCA5A5),
            ),
          ]),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _Period.values.map((p) => ListTile(
            title: Text(p.label(t),
                style: GoogleFonts.dmSans(
                    fontWeight: p == period
                        ? FontWeight.w700 : FontWeight.normal)),
            trailing: p == period
                ? const Icon(Icons.check_rounded, color: kPrimary) : null,
            onTap: () {
              Navigator.pop(context);
              onPeriod(p);
            },
          )).toList(),
        ),
      ),
    );
  }

  String _fmt(double amount, String currency) {
    final isInt = const {'VND','JPY','KRW','IDR'}.contains(currency);
    if (isInt) {
      return '${NumberFormat('#,##0', 'vi_VN').format(amount.round())} $currency';
    }
    return '${NumberFormat('#,##0.00', 'en_US').format(amount)} $currency';
  }
}

class _BalanceStat extends StatelessWidget {
  final String label, amount;
  final IconData icon;
  final Color color;
  const _BalanceStat({required this.label, required this.amount,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: color.withOpacity(0.25), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 11)),
          Text(amount,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
      ]);
}

// ── Transaction item ───────────────────────────────────────────────────────────
class _TxItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final type     = tx['type'] as int;
    final amount   = tx['amount'] as double;
    final currency = tx['currency'] as String? ?? 'VND';
    final content  = tx['content'] as String? ?? '';
    final catId    = tx['category_id'] as int?;
    final dtStr    = tx['date_time'] as String?;
    final color    = tx['wallet_color'] as String? ?? '#1D9E75';

    final isExpense  = type == 0;
    final isTransfer = type == 2;
    final amtColor   = isTransfer ? kSubtext
        : isExpense  ? kError : kIncome;
    final prefix     = isExpense ? '-' : isTransfer ? '⇄' : '+';

    final isInt = const {'VND','JPY','KRW','IDR'}.contains(currency);
    final amtStr = isInt
        ? '${NumberFormat('#,##0', 'vi_VN').format(amount.round())} $currency'
        : '${NumberFormat('#,##0.00', 'en_US').format(amount)} $currency';

    DateTime? dt;
    try { dt = dtStr != null ? DateTime.parse(dtStr).toLocal() : null; }
    catch (_) {}

    // Icon từ category_id — dùng fallback icon theo type
    final iconData = isTransfer
        ? Icons.swap_horiz_rounded
        : isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Icon
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _hexToColor(color).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, size: 20,
              color: isTransfer ? kSubtext
                  : isExpense  ? kError : kIncome),
        ),
        const SizedBox(width: 12),

        // Content + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.isNotEmpty ? content : (
                    isTransfer ? 'Chuyển khoản'
                    : isExpense ? 'Chi tiêu' : 'Thu nhập'),
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14, color: kText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (dt != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm, dd MMM').format(dt),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: kSubtext),
                ),
              ],
            ],
          ),
        ),

        // Amount
        Text(
          '$prefix $amtStr',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: amtColor),
        ),
      ]),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onTransactionAdded;
  const _QuickActions({required this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(children: [
      for (final item in [
        (Icons.add_circle_outline_rounded, t.addExpense, () async {
          final added = await Navigator.push<bool>(context,
              MaterialPageRoute(
                  builder: (_) => const CreateTransactionScreen()));
          if (added == true) onTransactionAdded();
        }),
        (Icons.add_circle_outline_rounded, t.addIncome, () async {
          final added = await Navigator.push<bool>(context,
              MaterialPageRoute(
                  builder: (_) => const CreateTransactionScreen()));
          if (added == true) onTransactionAdded();
        }),
        (Icons.swap_horiz_rounded, t.transfer, () async {
          final added = await Navigator.push<bool>(context,
              MaterialPageRoute(
                  builder: (_) => const CreateTransactionScreen()));
          if (added == true) onTransactionAdded();
        }),
        (Icons.account_balance_wallet_outlined, t.wallets, () =>
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WalletListScreen()))),
        
      ])
        // Expanded(
        //   child: GestureDetector(
        //     onTap: item.$3,
        //     child: Container(
        //       margin: const EdgeInsets.symmetric(horizontal: 4),
        //       padding: const EdgeInsets.symmetric(vertical: 14),
        //       decoration: BoxDecoration(
        //           color: kPrimary,
        //           borderRadius: BorderRadius.circular(14)),
        //       child: Column(children: [
        //         Icon(item.$1, color: Colors.white, size: 22),
        //         const SizedBox(height: 6),
        //         Text(item.$2,
        //             style: GoogleFonts.dmSans(
        //                 fontSize: 11, fontWeight: FontWeight.w600,
        //                 color: Colors.white)),
        //       ]),
        //     ),
        //   ),
        // ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // 1. Dùng Material để hiển thị hiệu ứng Ink (gợn sóng)
            child: Material(
              // color: kPrimary, // Màu nền của nút
              borderRadius: BorderRadius.circular(14),
              // 2. InkWell xử lý sự kiện bấm và tạo hiệu ứng gợn sóng
              child: InkWell(
                onTap: item.$3,
                borderRadius: BorderRadius.circular(14), // Bo góc hiệu ứng khớp với Material
                splashColor: Colors.white.withOpacity(0.2), // Màu hiệu ứng gợn sóng
                highlightColor: Colors.white.withOpacity(0.1), // Màu khi nhấn giữ
                child: Container(
                  // Lưu ý: Không đặt màu nền (color) trong BoxDecoration của Container nữa 
                  // vì Material đã quản lý màu nền để hiệu ứng Ink có thể hiển thị lên trên.
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [kPrimary, kPrimaryL],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, color: Colors.white, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    ]);
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            _NavItem(icon: Icons.home_rounded,        label: t.home,    idx: 0, current: current, onTap: onTap),
            _NavItem(icon: Icons.bar_chart_rounded,   label: t.charts,  idx: 1, current: current, onTap: onTap),
            _AddButton(onTap: () => onTap(2)),
            _NavItem(icon: Icons.receipt_long_rounded, label: t.history, idx: 3, current: current, onTap: onTap),
            _NavItem(icon: Icons.settings_outlined,   label: t.settings, idx: 4, current: current, onTap: onTap),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      idx, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label,
      required this.idx, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: active ? kPrimary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: active ? kPrimary : kSubtext, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? kPrimary : kSubtext)),
        ]),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryL],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: kPrimary.withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          Text(t.add,
              style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
        ]),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bar_chart_rounded, size: 64, color: kBorder),
      const SizedBox(height: 16),
      Text('Charts coming soon',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700, color: kSubtext)),
    ]),
  );
}