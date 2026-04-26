import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taexpense/constants/wallet_colors.dart';
import 'package:taexpense/constants/wallet_types.dart';
import 'package:taexpense/models/wallet_type.dart';
import 'package:taexpense/utils/wallet_type_l10n.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import 'package:taexpense/widgets/wallet_icon.dart';
import 'package:taexpense/widgets/fina_calculator_field.dart';


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
  'wallet_type.cash':       _FieldConfig(),
  'wallet_type.bank':       _FieldConfig(showAccount: true),
  'wallet_type.credit':     _FieldConfig(showAccount: true, showCreditLimit: true, showDueDay: true),
  'wallet_type.ewallet':    _FieldConfig(),
  'wallet_type.investment': _FieldConfig(),
  'wallet_type.savings':    _FieldConfig(),
};

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _balCtrl    = TextEditingController();
  final _acctCtrl   = TextEditingController();
  final _limitCtrl  = TextEditingController();
  final _dueDayCtrl = TextEditingController();

  WalletType _selectedType  = kWalletTypes.first;
  String     _selectedColor = kWalletColors.first;
  String     _currency      = 'VND';

  _FieldConfig get _fields =>
      _fieldMap[_selectedType.nameKey] ?? const _FieldConfig();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    _acctCtrl.dispose();
    _limitCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        title: const Text('Thêm ví mới'),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameCtrl,
            builder: (context, value, _) => TextButton(
              onPressed: value.text.trim().isEmpty ? null : _handleSave,
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _buildPreview(),
              _buildTypeSection(l10n),
              const SizedBox(height: 16),
              _buildCommonFields(),
              _fields.showAccount
                  ? _buildExtraAccount()
                  : const SizedBox.shrink(),
              _fields.showCreditLimit
                  ? _buildExtraCreditLimit()
                  : const SizedBox.shrink(),
              _fields.showDueDay
                  ? _buildExtraDueDay()
                  : const SizedBox.shrink(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameCtrl,
                  builder: (context, value, _) => FinaButton(
                    label: 'Thêm ví',
                    onPressed: value.text.trim().isEmpty ? null : _handleSave,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preview avatar + color picker ─────────────────────────────────────────

  Widget _buildPreview() => Column(
    children: [
      const SizedBox(height: 24),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: WalletIcon.hexToColor(_selectedColor),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: WalletIcon(iconKey: _selectedType.icon, hexColor: '#FFFFFF', size: 34),
        ),
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
              width: 26, height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: WalletIcon.hexToColor(hex),
                shape: BoxShape.circle,
                border: active ? Border.all(color: Colors.white, width: 2.5) : null,
                boxShadow: active
                    ? [BoxShadow(color: WalletIcon.hexToColor(hex).withOpacity(0.5), blurRadius: 6)]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
    ],
  );

  // ── Wallet type grid ───────────────────────────────────────────────────────

  Widget _buildTypeSection(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Loại ví'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: kWalletTypes.map((wt) {
            final active = wt.nameKey == _selectedType.nameKey;
            final color  = WalletIcon.hexToColor(_selectedColor);
            return GestureDetector(
              onTap: () => setState(() => _selectedType = wt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: active
                      ? color.withOpacity(0.08)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WalletIcon(iconKey: wt.icon, hexColor: _selectedColor, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      l10n.translateKey(wt.nameKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                        color: active
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  // ── Common fields ──────────────────────────────────────────────────────────

  Widget _buildCommonFields() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Thông tin'),
        FinaField(
          label: 'Tên ví',
          hint: 'VD: VISA Techcombank',
          controller: _nameCtrl,
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
        const SizedBox(height: 16),
        FinaCalculatorField(
          label: 'Số dư ban đầu',
          hint: '0',
          controller: _balCtrl,
          // keyboard: TextInputType.number,
        ),
      ],
    ),
  );

  // ── Extra fields ───────────────────────────────────────────────────────────

  Widget _buildExtraAccount() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 16),
        FinaField(
          label: _selectedType.nameKey == 'wallet_type.credit'
              ? 'Số thẻ'
              : 'Số tài khoản',
          hint: '•••• •••• ••••',
          controller: _acctCtrl,
          keyboard: TextInputType.number,
        ),
      ],
    ),
  );

  Widget _buildExtraCreditLimit() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 16),
        FinaField(
          label: 'Hạn mức',
          hint: '0',
          controller: _limitCtrl,
          keyboard: TextInputType.number,
        ),
      ],
    ),
  );

  Widget _buildExtraDueDay() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 16),
        FinaField(
          label: 'Ngày sao kê hàng tháng',
          hint: '1 – 28',
          controller: _dueDayCtrl,
          keyboard: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final n = int.tryParse(v);
            if (n == null || n < 1 || n > 28) return 'Nhập số từ 1 đến 28';
            return null;
          },
        ),
      ],
    ),
  );

  // ── Save ───────────────────────────────────────────────────────────────────

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'name':           _nameCtrl.text.trim(),
      'wallet_type':    _selectedType.nameKey,
      'currency':       _currency,
      'balance':        double.tryParse(_balCtrl.text) ?? 0.0,
      'color':          _selectedColor,
      'account_number': _acctCtrl.text.isEmpty ? null : _acctCtrl.text,
      'credit_limit':   double.tryParse(_limitCtrl.text),
      'due_day':        int.tryParse(_dueDayCtrl.text),
    };
    // TODO: walletRepository.createWallet(payload)
    Navigator.pop(context);
  }
}