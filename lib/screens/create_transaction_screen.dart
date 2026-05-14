import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/category.dart';
import 'package:taexpense/models/transaction_data.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/services/bill_upload_service.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/transaction_service.dart'
    as TransactionService;
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';
import 'package:taexpense/widgets/bill_image_picker.dart';
import 'package:taexpense/widgets/calculator_sheet.dart';
import 'package:taexpense/widgets/tags_input_field.dart';
import '../theme/app_theme.dart';
import '../widgets/fina_widgets.dart';
import 'package:taexpense/utils/material_icons_map.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateTransactionScreen extends StatefulWidget {
  final TransactionData? prefill;
  const CreateTransactionScreen({super.key, this.prefill});

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _receiveAmountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int _type = 0; // 0=expense 1=income 2=transfer
  String get _currency => _fromWallet?.currency ?? 'VND';
  // Các đồng tiền không dùng số thập phân
  bool get _isIntegerCurrency =>
      ['VND', 'JPY', 'KRW', 'IDR'].contains(_currency);

  DateTime _dt = DateTime.now();
  List<String> _tags = [];
  List<File> _billImages = [];
  String? _requestId;
  bool _saving = false;
  String? _error;

  // Master data — load từ MasterDataStore (đã sync lúc login)
  List<WalletModel> get _wallets => MasterDataStore().wallets;
  List<Category> get _categories => MasterDataStore().categories;

  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  Category? _category;

  List<String> get _tagSuggestions =>
      MasterDataStore().recentTags; // optional: lưu tags hay dùng

  bool get _isTransfer => _type == 2;

  // Categories lọc theo type hiện tại
  List<Category> get _filteredCategories =>
      _categories.where((c) => c.type == _type || c.type == 2).toList();

  @override
  void initState() {
    super.initState();

    // Default wallet = ví đầu tiên
    _fromWallet = _wallets.isNotEmpty ? _wallets.first : null;

    // Default category = expense đầu tiên
    _category =
        _filteredCategories.isNotEmpty ? _filteredCategories.first : null;

    // Prefill từ AI parser
    final p = widget.prefill;
    if (p != null) {
      _type = p.type;
      // _currency = p.currency;  // Lưu ý: currency sẽ theo wallet đã chọn, nên không set trực tiếp được
      _requestId = p.requestId;
      _amountCtrl.text = p.amount.toStringAsFixed(p.amount % 1 == 0 ? 0 : 2);
      if (p.address != null) _addressCtrl.text = p.address!;
      if (p.note != null) _noteCtrl.text = p.note!;

      // Resolve wallet từ prefill
      if (p.wallet != null) {
        _fromWallet = _wallets.where((w) => w.id == p.wallet!.id).firstOrNull ??
            _fromWallet;
      }

      // Resolve category từ prefill
      if (p.category != null) {
        _category =
            _filteredCategories.where((c) => c.id == p.category).firstOrNull ??
                _category;
      }

      try {
        _dt = DateTime.parse(p.dateTime).toLocal();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receiveAmountCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light()
            .copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dt),
      builder: (ctx, child) => Theme(
        data: ThemeData.light()
            .copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    var t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_fromWallet == null) {
      setState(() => _error = t.selectWallet); // Use localized error message
      return;
    }
    if (_isTransfer && _toWallet == null) {
      setState(() => _error = t.selectToWallet); // Use localized error message
      return;
    }
    
    try {
      // 1. Upload bill images lên temp
      final tempKeys = <String>[];
      for (final file in _billImages) {
        final key = await BillUploadService.uploadTemp(file, Session.token!);
        tempKeys.add(key);
      }

      // 2. Build payload và gọi API lưu giao dịch
      final rawAmount = NumberFormat('#,##0.##', 'vi_VN')
          .parse(_amountCtrl.text.isEmpty ? '0' : _amountCtrl.text)
          .toDouble();

      if (rawAmount == 0 || rawAmount.isNaN || rawAmount.isNegative) {
        setState(() => _error = t.invalidAmount); // Use localized error message
        return;
      }

      final rawReceive = _isTransfer && _receiveAmountCtrl.text.isNotEmpty
          ? NumberFormat('#,##0.##', 'vi_VN')
              .parse(_receiveAmountCtrl.text)
              .toDouble()
          : null;

      if (_isTransfer && (rawReceive == 0 || rawReceive!.isNaN || rawReceive.isNegative)) {
        setState(() => _error = t.invalidReceiveAmount); // Use localized error message
        return;
      }

      setState(() {
            _saving = true;
            _error = null;
          });
          
      await TransactionService.saveTransaction({
        'type': _type,
        'wallet_id': _fromWallet!.id,
        'to_wallet_id': _isTransfer ? _toWallet?.id : null,
        'amount': rawAmount,
        'receive_amount': rawReceive,
        'currency': _currency,
        'category_id': _isTransfer ? null : _category?.id,
        'address':
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'date_time': _dt.toUtc().toIso8601String(),
        'tags': _tags.isEmpty ? null : _tags.join(','),
        'temp_bill_keys': tempKeys,
        'request_id': _requestId,
      }, Session.token!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã lưu giao dịch',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.of(context).pop(true); // trả về true để HomeScreen biết là cần refresh
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không thể kết nối server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t.newTransaction,
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, color: kText)),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountCtrl,
            builder: (_, val, __) => TextButton(
              onPressed: (_saving || val.text.isEmpty) ? null : _save,
              child: Text(t.save,
                  style: GoogleFonts.dmSans(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error banner
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],

                // ── Type toggle ────────────────────────────────────────────────
                _TypeToggle(
                  value: _type,
                  onChanged: (v) => setState(() {
                    _type = v;
                    // Reset category khi đổi type
                    _category = _filteredCategories.isNotEmpty
                        ? _filteredCategories.first
                        : null;
                  }),
                ),
                const SizedBox(height: 20),

                // ── Amount + Currency ──────────────────────────────────────────
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    flex: 3,
                    child: _AmountField(
                      controller: _amountCtrl,
                      label: t.amount,
                      currency: _currency,
                      isInteger: _isIntegerCurrency,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Transfer: receive amount ───────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isTransfer
                      ? Column(children: [
                          _AmountField(
                            controller: _receiveAmountCtrl,
                            label: t.receiveAmount,
                          ),
                          const SizedBox(height: 20),
                        ])
                      : const SizedBox.shrink(),
                ),

                // ── From wallet ────────────────────────────────────────────────
                FinaDropdown<WalletModel>(
                  label: _isTransfer ? t.fromWallet : t.toWallet,
                  value: _fromWallet,
                  items: _wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _hexToColor(w.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(w.name),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _fromWallet = v),
                ),
                const SizedBox(height: 20),

                // ── To wallet (transfer only) ──────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isTransfer
                      ? Column(children: [
                          FinaDropdown<WalletModel>(
                            label: t.toWallet,
                            value: _toWallet,
                            items: _wallets
                                .where((w) => w.id != _fromWallet?.id)
                                .map((w) => DropdownMenuItem(
                                      value: w,
                                      child: Row(children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: _hexToColor(w.color),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(w.name),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _toWallet = v),
                          ),
                          const SizedBox(height: 20),
                        ])
                      : const SizedBox.shrink(),
                ),

                // ── Category (expense + income only) ──────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: !_isTransfer
                      ? Column(children: [
                          FinaDropdown<Category>(
                            label: t.category,
                            value: _category,
                            items: _filteredCategories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(c.type)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            iconFromKey(c.icon),
                                            size: 16,
                                            color: _categoryColor(c.type),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(c.name),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v),
                          ),
                          const SizedBox(height: 20),
                        ])
                      : const SizedBox.shrink(),
                ),

                // ── Address / Merchant (expense only) ─────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _type == 0
                      ? Column(children: [
                          FinaField(
                            label: t.address,
                            hint: t.merchantHint,
                            controller: _addressCtrl,
                            prefix: const Icon(Icons.location_on_outlined,
                                size: 20, color: kSubtext),
                          ),
                          const SizedBox(height: 20),
                        ])
                      : const SizedBox.shrink(),
                ),

                // ── Date & Time ────────────────────────────────────────────────
                _DateTimeTile(dt: _dt, onTap: _pickDateTime),
                const SizedBox(height: 20),

                // ── Note ──────────────────────────────────────────────────────
                FinaField(
                  label: t.note,
                  hint: t.addNoteOptional,
                  controller: _noteCtrl,
                  prefix: const Icon(Icons.notes_rounded,
                      size: 20, color: kSubtext),
                ),
                const SizedBox(height: 20),

                // ── Tags ───────────────────────────────────────────────────────
                TagsInputField(
                  tags: _tags,
                  suggestions: _tagSuggestions,
                  onChanged: (t) => setState(() => _tags = t),
                ),
                const SizedBox(height: 20),

                // ── Bill images ────────────────────────────────────────────────
                // BillImagePicker(
                //   images: _billImages,
                //   onChanged: (imgs) => setState(() => _billImages = imgs),
                // ),
                // const SizedBox(height: 24),

                // ── Save button ────────────────────────────────────────────────
                FinaButton(
                  label: t.save,
                  onPressed: _save,
                  isLoading: _saving,
                  icon: Icons.save_rounded,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
Color _categoryColor(int type) {
  switch (type) {
    case 1:
      return kIncome; // thu
    case 0:
      return kExpense; // chi
    default:
      return kPrimary;
  }
}

Color _hexToColor(String? hex) {
  final clean = (hex ?? '#1D9E75').replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

// ── Type Toggle ────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kBorder.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _Tab(
            label: t.expense,
            val: 0,
            active: value == 0,
            activeColor: kExpense,
            onTap: () => onChanged(0)),
        _Tab(
            label: t.income,
            val: 1,
            active: value == 1,
            activeColor: kIncome,
            onTap: () => onChanged(1)),
        _Tab(
            label: t.transfer,
            val: 2,
            active: value == 2,
            activeColor: kTransfer,
            onTap: () => onChanged(2)),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int val;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.val,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: active ? Colors.white : kSubtext,
                ),
              ),
            ),
          ),
        ),
      );
}

// ── Amount Field ───────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String currency;
  final bool isInteger; // true = không thập phân (VND, JPY...)

  const _AmountField({
    required this.controller,
    required this.label,
    this.currency = 'VND',
    this.isInteger = true,
  });

  Future<void> _openCalculator(BuildContext context) async {
    final raw = controller.text
        .replaceAll(RegExp(r'[,.](?=\d{3})'), '') // bỏ dấu ngàn
        .replaceAll(',', '.') // phẩy thập phân → chấm
        .trim();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CalculatorSheet(initialValue: raw),
    );

    if (result != null) {
      final val = double.tryParse(result);
      if (val != null) {
        controller.text = _formatAmount(val);
      }
    }
  }

  String _formatAmount(double val) {
    if (isInteger) {
      // VND: 1.500.000
      return NumberFormat('#,##0', 'vi_VN').format(val.round());
    } else {
      // SGD, USD: 1,500.00
      return NumberFormat('#,##0.00', 'en_US').format(val);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151))),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => GestureDetector(
              onTap: () => _openCalculator(context),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value.text.isEmpty ? kBorder : kPrimary,
                    width: value.text.isEmpty ? 1 : 2,
                  ),
                ),
                child: Row(children: [
                  // Currency badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(currency,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value.text.isEmpty
                          ? (isInteger ? '0' : '0.00')
                          : value.text,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: value.text.isEmpty ? kBorder : kText,
                      ),
                    ),
                  ),
                  Icon(Icons.calculate_outlined,
                      size: 18, color: kPrimary.withOpacity(0.6)),
                ]),
              ),
            ),
          ),
        ],
      );
}

// ── DateTime Tile ──────────────────────────────────────────────────────────────

class _DateTimeTile extends StatelessWidget {
  final DateTime dt;
  final VoidCallback onTap;
  const _DateTimeTile({required this.dt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.dateTime,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_month_rounded,
                  color: kSubtext, size: 20),
              const SizedBox(width: 12),
              Text(DateFormat('HH:mm, dd MMM yyyy').format(dt),
                  style: GoogleFonts.dmSans(fontSize: 15, color: kText)),
              const Spacer(),
              const Icon(Icons.edit_outlined, color: kSubtext, size: 16),
            ]),
          ),
        ),
      ],
    );
  }
}
