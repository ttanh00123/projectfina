// lib/screens/wallet_list_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/screens/create_wallet_screen.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import 'package:taexpense/widgets/wallet_icon.dart';
import '../theme/app_theme.dart';

class WalletListScreen extends StatefulWidget {
  static const routeName = '/wallets';
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  List<WalletModel> _wallets = [];
  bool   _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Dùng local cache trước
    _wallets = MasterDataStore().wallets;
    // Sync để đảm bảo fresh
    _syncWallets();
  }

  Future<void> _syncWallets() async {
    setState(() => _loading = true);
    try {
      final updated = await MasterDataStore().sync(Session.token!);
      if (updated || _wallets.isEmpty) {
        setState(() => _wallets = MasterDataStore().wallets);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteWallet(WalletModel wallet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ví'),
        content: Text('Xóa ví "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: kError)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${AppConstants.BASE_URL}/wallets/${wallet.id}'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      if (res.statusCode == 200) {
        await _syncWallets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ví')));
        }
      } else {
        final body = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['detail'] ?? 'Không thể xóa ví'),
                backgroundColor: kError));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối'),
              backgroundColor: kError));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text('Ví của tôi',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, color: kText)),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: kPrimary),
          onPressed: () async {
            final created = await Navigator.push<bool>(context,
                MaterialPageRoute(
                    builder: (_) => const CreateWalletScreen()));
            if (created == true) _syncWallets();
          },
        ),
      ],
    ),
    body: _loading && _wallets.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _wallets.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _syncWallets,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Tổng tài sản
                    _buildTotalCard(),
                    const SizedBox(height: 16),
                    // Danh sách ví
                    ..._wallets.map((w) => _buildWalletCard(w)),
                  ],
                ),
              ),
  );

  Widget _buildTotalCard() {
    final totalVnd = _wallets
        .where((w) => w.currency == 'VND')
        .fold(0.0, (sum, w) => sum + w.balance);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng tài sản (VND)',
              style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            _formatVnd(totalVnd),
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('${_wallets.length} ví',
              style: GoogleFonts.dmSans(
                  color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWalletCard(WalletModel wallet) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: WalletIcon.hexToColor(wallet.color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: WalletIcon(
            iconKey:  wallet.walletType.icon,
            hexColor: '#FFFFFF',
            size: 22,
          ),
        ),
      ),
      title: Text(wallet.name,
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600, color: kText)),
      subtitle: Text(wallet.currency,
          style: GoogleFonts.dmSans(
              fontSize: 12, color: kSubtext)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBalance(wallet.balance, wallet.currency),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: wallet.balance >= 0 ? kText : kError,
                ),
              ),
              if (wallet.isCreditCard && wallet.availableCredit != null)
                Text(
                  'Còn lại: ${_formatBalance(wallet.availableCredit!, wallet.currency)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: kSubtext),
                ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: kSubtext, size: 20),
            onSelected: (v) async {
              if (v == 'edit') {
                final updated = await Navigator.push<bool>(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CreateWalletScreen(wallet: wallet)));
                if (updated == true) _syncWallets();
              } else if (v == 'delete') {
                await _deleteWallet(wallet);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 16, color: kError),
                  const SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: kError)),
                ]),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: kBorder),
        const SizedBox(height: 16),
        Text('Chưa có ví nào',
            style: GoogleFonts.dmSans(
                fontSize: 16, color: kSubtext)),
        const SizedBox(height: 24),
        SizedBox(
          width: 160,
          child: FinaButton(
            label: 'Thêm ví',
            onPressed: () async {
              final created = await Navigator.push<bool>(context,
                  MaterialPageRoute(
                      builder: (_) => const CreateWalletScreen()));
              if (created == true) _syncWallets();
            },
          ),
        ),
      ],
    ),
  );

  String _formatVnd(double amount) {
    final n = amount.round().abs();
    final formatted = n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return amount < 0 ? '-$formatted' : formatted;
  }

  String _formatBalance(double amount, String currency) {
    final isInt = ['VND', 'JPY', 'KRW', 'IDR'].contains(currency);
    if (isInt) return _formatVnd(amount);
    final n = amount.abs();
    final formatted = n.toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
    return amount < 0 ? '-$formatted' : formatted;
  }
}