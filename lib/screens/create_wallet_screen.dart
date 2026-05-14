// lib/screens/create_wallet_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/constants/wallet_colors.dart';
import 'package:taexpense/constants/wallet_types.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/models/wallet_type.dart';
import 'package:taexpense/screens/wallet_list_screen.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/wallet_type_l10n.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import 'package:taexpense/widgets/wallet_icon.dart';
import '../theme/app_theme.dart';

class _FieldConfig {
  final bool showAccount;
  final bool showCreditLimit;
  final bool showDueDay;
  const _FieldConfig({
    this.showAccount = false,
    this.showCreditLimit = false,
    this.showDueDay = false,
  });
}

const _fieldMap = {
  'wallet_type.cash': _FieldConfig(),
  'wallet_type.bank': _FieldConfig(showAccount: true),
  'wallet_type.credit':
      _FieldConfig(showAccount: true, showCreditLimit: true, showDueDay: true),
  'wallet_type.ewallet': _FieldConfig(),
  'wallet_type.investment': _FieldConfig(),
  'wallet_type.savings': _FieldConfig(),
};

class CreateWalletScreen extends StatefulWidget {
  final WalletModel? wallet; // null = create, non-null = edit
  const CreateWalletScreen({super.key, this.wallet});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();
  final _acctCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _dueDayCtrl = TextEditingController();

  WalletType _selectedType = kWalletTypes.first;
  String _selectedColor = kWalletColors.first;
  String _currency = 'VND';
  bool _loading = false;
  String? _error;

  bool get _isEditMode => widget.wallet != null;
  _FieldConfig get _fields =>
      _fieldMap[_selectedType.nameKey] ?? const _FieldConfig();

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    if (w != null) {
      _nameCtrl.text = w.name;
      _selectedType = w.walletType;
      _selectedColor = w.color;
      _currency = w.currency;
      if (w.accountNumber != null) _acctCtrl.text = w.accountNumber!;
      if (w.creditLimit != null)
        _limitCtrl.text = w.creditLimit!.toStringAsFixed(0);
      if (w.dueDay != null) _dueDayCtrl.text = '${w.dueDay}';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    _acctCtrl.dispose();
    _limitCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'wallet_type': _selectedType.nameKey,
        'currency': _currency,
        'color': _selectedColor,
        'account_number': _acctCtrl.text.isEmpty ? null : _acctCtrl.text,
        'credit_limit': double.tryParse(_limitCtrl.text),
        'due_day': int.tryParse(_dueDayCtrl.text),
      };
      if (!_isEditMode) {
        payload['balance'] = double.tryParse(_balCtrl.text) ?? 0.0;
      }

      final uri = _isEditMode
          ? Uri.parse('${AppConstants.BASE_URL}/wallets/${widget.wallet!.id}')
          : Uri.parse('${AppConstants.BASE_URL}/wallets');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Session.token}',
      };

      final res = _isEditMode
          ? await http.put(uri, headers: headers, body: jsonEncode(payload))
          : await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (res.statusCode == 200 || res.statusCode == 201) {
        await MasterDataStore().sync(Session.token!);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletListScreen()),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        setState(() => _error = body['detail'] as String? ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      setState(() => _error = 'Không thể kết nối server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kText),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _isEditMode ? 'Chỉnh sửa ví' : 'Thêm ví mới',
          style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, color: kText),
        ),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameCtrl,
            builder: (_, val, __) => TextButton(
              onPressed: (_loading || val.text.trim().isEmpty) ? null : _save,
              child: Text('Lưu',
                  style: GoogleFonts.dmSans(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildPreview(),

            // Wallet type grid — chỉ hiện khi tạo mới
            if (_isEditMode)
              WalletIcon(hexColor: _selectedColor, size: 20, iconKey: _selectedType.icon,)
              // Text('Loại ví: ${_selectedType.nameKey}', style: GoogleFonts.dmSans(fontSize: 14, color: kText))
            else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Loại ví'),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: kWalletTypes.map((wt) {
                          final active = wt.nameKey == _selectedType.nameKey;
                          final color = WalletIcon.hexToColor(_selectedColor);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedType = wt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: active
                                    ? color.withOpacity(0.08)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: active ? color : Colors.transparent,
                                    width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  WalletIcon(
                                      iconKey: wt.icon,
                                      hexColor: _selectedColor,
                                      size: 26),
                                  const SizedBox(height: 6),
                                  Text(l10n.translateKey(wt.nameKey),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: active
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                          color: active
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              

            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ErrorBanner(message: _error!),
              ),

            // Common fields
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Thông tin'),
                  FinaField(
                    label: 'Tên ví',
                    hint: 'VD: VISA Techcombank',
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  FinaDropdown<String>(
                    label: 'Tiền tệ',
                    value: _currency,
                    items: ['VND', 'USD', 'EUR', 'SGD']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                  if (!_isEditMode) ...[
                    const SizedBox(height: 16),
                    FinaField(
                      label: 'Số dư ban đầu',
                      hint: '0',
                      controller: _balCtrl,
                      keyboard: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),

            // Extra fields
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _fields.showAccount
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: FinaField(
                        label: _selectedType.nameKey == 'wallet_type.credit'
                            ? 'Số thẻ'
                            : 'Số tài khoản',
                        hint: '•••• •••• ••••',
                        controller: _acctCtrl,
                        keyboard: TextInputType.number,
                      ))
                  : const SizedBox.shrink(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _fields.showCreditLimit
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: FinaField(
                        label: 'Hạn mức',
                        hint: '0',
                        controller: _limitCtrl,
                        keyboard: TextInputType.number,
                      ))
                  : const SizedBox.shrink(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _fields.showDueDay
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: FinaField(
                        label: 'Ngày sao kê hàng tháng',
                        hint: '1 – 28',
                        controller: _dueDayCtrl,
                        keyboard: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 28)
                            return 'Nhập số từ 1 đến 28';
                          return null;
                        },
                      ))
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FinaButton(
                label: _isEditMode ? 'Cập nhật ví' : 'Thêm ví',
                isLoading: _loading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() => Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WalletIcon.hexToColor(_selectedColor),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
                child: WalletIcon(
                    iconKey: _selectedType.icon,
                    hexColor: '#FFFFFF',
                    size: 34)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: kWalletColors.map((hex) {
              final active = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: WalletIcon.hexToColor(hex),
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color:
                                    WalletIcon.hexToColor(hex).withOpacity(0.5),
                                blurRadius: 6)
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      );
}
