import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/widgets/app_icon.dart';
// import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fina_widgets.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home-screen";
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _pages = const [
    _DashboardPage(),
    _ChartPlaceholder(),
    SizedBox.shrink(), // FAB placeholder — handled below
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBg,
        body: Column(children: [
          _Header(),
          Expanded(child: _tab == 2 ? const SizedBox.shrink() : _pages[_tab]),
        ]),
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
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Session.user;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        const FinaLogo(size: 34),
        // const AppIcon(size: 34),
        const SizedBox(width: 12),
        const Spacer(),
        // Greeting
        if (user != null)
          Text('Hi, ${user.displayName}', style: GoogleFonts.dmSans(
            fontSize: 16, color: kSubtext)),
        const SizedBox(width: 14),
        // Notification
        Stack(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: kBg, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_outlined, color: kText, size: 22),
          ),
          Positioned(top: 8, right: 8, child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: kError, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5)),
          )),
        ]),
      ]),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', idx: 0, current: current, onTap: onTap),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Charts', idx: 1, current: current, onTap: onTap),
            _AddButton(onTap: () => onTap(2)),
            _NavItem(icon: Icons.receipt_long_rounded, label: 'History', idx: 3, current: current, onTap: onTap),
            _NavItem(icon: Icons.settings_outlined, label: 'Settings', idx: 4, current: current, onTap: onTap),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label;
  final int idx, current; final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label,
    required this.idx, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = current == idx;
    return Expanded(child: GestureDetector(
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
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? kPrimary : kSubtext)),
      ]),
    ));
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryL],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 2),
        Text('Add', style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary)),
      ]),
    ),
  );
}

// ── Dashboard placeholder ─────────────────────────────────────────────────────
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();
  @override
  Widget build(BuildContext context) {
    // final user = Session.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryL],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3),
              blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Balance', style: GoogleFonts.dmSans(
              color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Dashboard coming soon', style: GoogleFonts.spaceGrotesk(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Row(children: [
              _BalanceStat(label: 'Income', amount: '32,950 SGD', icon: Icons.arrow_downward_rounded, color: Color(0xFF86EFAC)),
              SizedBox(width: 24),
              _BalanceStat(label: 'Expense', amount: '15,000 SGD', icon: Icons.arrow_upward_rounded, color: Color(0xFFFCA5A5)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        _QuickActions(),
        const SizedBox(height: 24),
        Text('Recent Transactions', style: GoogleFonts.spaceGrotesk(
          fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Column(children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: kBorder),
            const SizedBox(height: 12),
            Text('No transactions yet', style: GoogleFonts.dmSans(color: kSubtext)),
            const SizedBox(height: 4),
            Text('Tap + to add your first one', style: GoogleFonts.dmSans(
              color: kSubtext.withOpacity(0.7), fontSize: 13)),
          ])),
        ),
      ]),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label, amount; final IconData icon; final Color color;
  const _BalanceStat({required this.label, required this.amount,
    required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 28, height: 28,
      decoration: BoxDecoration(color: color.withOpacity(0.25), shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: color)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 11)),
      Text(amount, style: GoogleFonts.spaceGrotesk(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    ]),
  ]);
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    for (final item in [
      (Icons.add_circle_outline_rounded, 'Add', () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ChatScreen()))),
      (Icons.bar_chart_rounded, 'Reports', () {}),
      (Icons.account_balance_wallet_outlined, 'Wallets', () {}),
      (Icons.swap_horiz_rounded, 'Transfer', () {}),
    ])
      Expanded(child: GestureDetector(
        onTap: item.$3,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(item.$1, color: kPrimary, size: 22),
            const SizedBox(height: 6),
            Text(item.$2, style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: kText)),
          ]),
        ),
      )),
  ]);
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bar_chart_rounded, size: 64, color: kBorder),
      const SizedBox(height: 16),
      Text('Charts coming soon', style: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w700, color: kSubtext)),
    ]),
  );
}
