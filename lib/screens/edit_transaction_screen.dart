import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/category.dart';
import 'package:taexpense/models/wallet_model.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/transaction_service.dart'
    as TransactionService;
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';
import 'package:taexpense/widgets/calculator_sheet.dart';
import 'package:taexpense/widgets/tags_input_field.dart';
import '../theme/app_theme.dart';
import '../widgets/fina_widgets.dart';
import 'package:taexpense/utils/material_icons_map.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditTransactionScreen extends StatefulWidget {
  final int transactionId;

  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  // ── Loading state ──────────────────────────────────────────────────────────
  bool _loading = true;
  String? _loadError;

  // ── Form state (same as CreateTransactionScreen) ───────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl        = TextEditingController();
  final _receiveAmountCtrl = TextEditingController();
  final _contentCtrl       = TextEditingController();
  final _noteCtrl          = TextEditingController();

  int           _type       = 0;
  DateTime      _dt         = DateTime.now();
  List<String>  _tags       = [];
  bool          _saving     = false;
  String?       _error;

  List<WalletModel> get _wallets    => MasterDataStore().wallets;
  List<Category>    get _categories => MasterDataStore().categories;

  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  Category?    _category;

  String get _currency        => _fromWallet?.currency ?? 'VND';
  bool   get _isIntegerCurrency =>
      ['VND', 'JPY', 'KRW', 'IDR'].contains(_currency);
  bool   get _isTransfer      => _type == 2;

  List<Category> get _filteredCategories =>
      _categories.where((c) => c.type == _type || c.type == 2).toList();

  List<String> get _tagSuggestions => MasterDataStore().recentTags;

  // ── Raw record from API ────────────────────────────────────────────────────
  Map<String, dynamic>? _record;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _receiveAmountCtrl.dispose();
    _contentCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Load transaction from API ──────────────────────────────────────────────

  Future<void> _loadTransaction() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final data = await TransactionService.getTransaction(
        widget.transactionId,
        Session.token!,
      );
      _record = data;
      _prefillForm(data);
    } catch (e) {
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Pre-fill form từ record ────────────────────────────────────────────────

  // void _prefillForm(Map<String, dynamic> r) {
  //   // Type
  //   _type = (r['type'] as num?)?.toInt() ?? 0;

  //   // Amount
  //   final amount = double.tryParse(r['amount']?.toString() ?? '0') ?? 0;
  //   _amountCtrl.text = _isIntegerCurrency
  //       ? NumberFormat('#,##0', 'vi_VN').format(amount.round())
  //       : NumberFormat('#,##0.00', 'en_US').format(amount);

  //   // Receive amount (transfer)
  //   if (r['receive_amount'] != null) {
  //     final recv = double.tryParse(r['receive_amount'].toString()) ?? 0;
  //     _receiveAmountCtrl.text = recv == recv.roundToDouble()
  //         ? recv.round().toString()
  //         : recv.toString();
  //   }

  //   // Wallets
  //   final walletId   = (r['wallet_id']   as num?)?.toInt();
  //   final toWalletId = (r['to_wallet_id'] as num?)?.toInt();
  //   _fromWallet = _wallets.where((w) => w.id == walletId).firstOrNull
  //       ?? (_wallets.isNotEmpty ? _wallets.first : null);
  //   _toWallet = toWalletId != null
  //       ? _wallets.where((w) => w.id == toWalletId).firstOrNull
  //       : null;

  //   // Category
  //   final catId = (r['category_id'] as num?)?.toInt();
  //   _category = catId != null
  //       ? _filteredCategories.where((c) => c.id == catId).firstOrNull
  //       : (_filteredCategories.isNotEmpty ? _filteredCategories.first : null);

  //   // Address / note — stored as 'content' and 'notes' in API
  //   _addressCtrl.text = r['content']?.toString() ?? '';
  //   _noteCtrl.text    = r['notes']?.toString()   ?? '';

  //   // Tags
  //   final rawTags = r['tags']?.toString() ?? '';
  //   _tags = rawTags.isEmpty ? [] : rawTags.split(',');

  //   // Date time
  //   try {
  //     _dt = DateTime.parse(r['date_time'].toString()).toLocal();
  //   } catch (_) {
  //     _dt = DateTime.now();
  //   }
  // }

  void _prefillForm(Map<String, dynamic> r) {
    // Type
    _type = (r['type'] as num?)?.toInt() ?? AppConstants.EXPENSE;

    // Amount
    final amount = double.tryParse(r['amount']?.toString() ?? '0') ?? 0;
    _amountCtrl.text = _isIntegerCurrency
        ? NumberFormat('#,##0', 'vi_VN').format(amount.round())
        : NumberFormat('#,##0.00', 'en_US').format(amount);

    // Receive amount (transfer)
    if (r['receive_amount'] != null) {
      final recv = double.tryParse(r['receive_amount'].toString()) ?? 0;
      _receiveAmountCtrl.text = _isIntegerCurrency
          ? NumberFormat('#,##0', 'vi_VN').format(recv.round())
          : NumberFormat('#,##0.00', 'en_US').format(recv);
    }

    // Wallets — dùng wallet_id từ response, KHÔNG cần join thêm
    final walletId   = (r['wallet_id']    as num?)?.toInt();
    final toWalletId = (r['to_wallet_id'] as num?)?.toInt();
    _fromWallet = _wallets.where((w) => w.id == walletId).firstOrNull
        ?? (_wallets.isNotEmpty ? _wallets.first : null);
    _toWallet = toWalletId != null
        ? _wallets.where((w) => w.id == toWalletId).firstOrNull
        : null;

    // Category
    final catId = (r['category_id'] as num?)?.toInt();
    // Gọi sau khi _type đã được set để _filteredCategories đúng
    _category = catId != null
        ? _filteredCategories.where((c) => c.id == catId).firstOrNull
        : (_filteredCategories.isNotEmpty ? _filteredCategories.first : null);

    // Content → address field, notes → note field
    _contentCtrl.text = r['content']?.toString() ?? '';
    _noteCtrl.text    = r['notes']?.toString()   ?? '';

    // Tags — stored as comma-separated string
    final rawTags = r['tags']?.toString() ?? '';
    _tags = rawTags.trim().isEmpty ? [] : rawTags.split(',');

    // Date time
    try {
      // _dt = DateTime.parse(r['date_time'].toString()).toLocal();
      _dt = Utils.parseServerDateTime(r['date_time'])!;
    } catch (_) {
      _dt = DateTime.now();
    }
  }

  // ── Date/time picker ───────────────────────────────────────────────────────

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
    setState(() =>
        _dt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  // ── Save (update) ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_fromWallet == null) {
      setState(() => _error = t.selectWallet);
      return;
    }
    if (_isTransfer && _toWallet == null) {
      setState(() => _error = t.selectToWallet);
      return;
    }

    final rawAmount = NumberFormat('#,##0.##', 'vi_VN')
        .parse(_amountCtrl.text.isEmpty ? '0' : _amountCtrl.text)
        .toDouble();

    if (rawAmount <= 0 || rawAmount.isNaN) {
      setState(() => _error = t.invalidAmount);
      return;
    }

    final rawReceive = _isTransfer && _receiveAmountCtrl.text.isNotEmpty
        ? NumberFormat('#,##0.##', 'vi_VN')
            .parse(_receiveAmountCtrl.text)
            .toDouble()
        : null;

    if (_isTransfer && (rawReceive == null || rawReceive <= 0)) {
      setState(() => _error = t.invalidReceiveAmount);
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await TransactionService.updateTransaction(
        widget.transactionId,
        {
          'type':           _type,
          'wallet_id':      _fromWallet!.id,
          'to_wallet_id':   _isTransfer ? _toWallet?.id : null,
          'amount':         rawAmount,
          'receive_amount': rawReceive,
          'currency':       _currency,
          'category_id':    _isTransfer ? null : _category?.id,
          'content':        _contentCtrl.text.trim().isEmpty
                                ? null : _contentCtrl.text.trim(),
          'notes':          _noteCtrl.text.trim().isEmpty
                                ? null : _noteCtrl.text.trim(),
          'date_time':      _dt.toUtc().toIso8601String(),
          'tags':           _tags.isEmpty ? null : _tags.join(','),
        },
        Session.token!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã cập nhật giao dịch',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.of(context).pop(true); // true = cần refresh danh sách
      }
    } on TransactionService.ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không thể kết nối server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
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
            child: Text('Huỷ',
                style: GoogleFonts.dmSans(color: kSubtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xoá',
                style: GoogleFonts.dmSans(
                    color: kError, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await TransactionService.deleteTransaction(
          widget.transactionId, Session.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã xoá giao dịch',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.of(context).pop('deleted'); // signal đặc biệt để list biết
      }
    } catch (_) {
      setState(() => _error = 'Không thể xoá. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // ── Loading / error state ────────────────────────────────────────────────
    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: kText),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Chỉnh sửa giao dịch',
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700, color: kText)),
        ),
        body: const Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: kText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: kError),
            const SizedBox(height: 12),
            Text(_loadError!, style: GoogleFonts.dmSans(color: kSubtext),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadTransaction, child: const Text('Thử lại')),
          ],
        )),
      );
    }

    // ── Main form ────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chỉnh sửa giao dịch',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700, color: kText)),
        actions: [
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: kError),
            onPressed: _saving ? null : _confirmDelete,
            tooltip: 'Xoá',
          ),
          // Save button
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
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],

                // ── Type toggle ──────────────────────────────────────────────
                _TypeToggle(
                  value: _type,
                  onChanged: (v) => setState(() {
                    _type = v;
                    _category = _filteredCategories.isNotEmpty
                        ? _filteredCategories.first
                        : null;
                  }),
                ),
                const SizedBox(height: 20),

                // ── Content ───────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: FinaField(
                    label: t.content,
                    hint: t.contentHint,
                    controller: _contentCtrl,
                    prefix: const Icon(Icons.content_paste_rounded,
                        size: 20, color: kSubtext),
                  )
                ),

                const SizedBox(height: 20),
                // ── Amount ───────────────────────────────────────────────────
                _AmountField(
                  controller: _amountCtrl,
                  label: t.amount,
                  currency: _currency,
                  isInteger: _isIntegerCurrency,
                ),
                const SizedBox(height: 20),

                // ── Receive amount (transfer) ────────────────────────────────
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

                // ── From wallet ──────────────────────────────────────────────
                FinaDropdown<WalletModel>(
                  label: _isTransfer ? t.fromWallet : t.toWallet,
                  value: _fromWallet,
                  items: _wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Row(children: [
                              Container(
                                width: 10, height: 10,
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

                // ── To wallet (transfer) ─────────────────────────────────────
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
                                          width: 10, height: 10,
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
                            onChanged: (v) => setState(() => _toWallet = v),
                          ),
                          const SizedBox(height: 20),
                        ])
                      : const SizedBox.shrink(),
                ),

                // ── Category (expense + income) ──────────────────────────────
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
                                          width: 28, height: 28,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(c.type)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(iconFromKey(c.icon),
                                              size: 16,
                                              color: _categoryColor(c.type)),
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

                // ── Date & Time ──────────────────────────────────────────────
                _DateTimeTile(dt: _dt, onTap: _pickDateTime),
                const SizedBox(height: 20),

                // ── Note ─────────────────────────────────────────────────────
                FinaField(
                  label: t.note,
                  hint: t.addNoteOptional,
                  controller: _noteCtrl,
                  prefix: const Icon(Icons.notes_rounded,
                      size: 20, color: kSubtext),
                ),
                const SizedBox(height: 20),

                // ── Tags ─────────────────────────────────────────────────────
                TagsInputField(
                  tags: _tags,
                  suggestions: _tagSuggestions,
                  onChanged: (tags) => setState(() => _tags = tags),
                ),
                const SizedBox(height: 24),

                // ── Save button ──────────────────────────────────────────────
                FinaButton(
                  label: t.save,
                  onPressed: _save,
                  isLoading: _saving,
                  icon: Icons.save_rounded,
                ),
                const SizedBox(height: 12),

                // ── Delete button ────────────────────────────────────────────
                FinaButton(
                  label: 'Xoá giao dịch',
                  onPressed: _saving ? null : _confirmDelete,
                  color: kError,
                  icon: Icons.delete_outline_rounded,
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

// ── Helpers (copy từ CreateTransactionScreen) ─────────────────────────────────

Color _categoryColor(int type) {
  switch (type) {
    case 1:  return kIncome;
    case 0:  return kExpense;
    default: return kPrimary;
  }
}

Color _hexToColor(String? hex) {
  final clean = (hex ?? '#1D9E75').replaceAll('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

// ── _TypeToggle, _Tab, _AmountField, _DateTimeTile ────────────────────────────
// Copy từ CreateTransactionScreen — hoặc extract ra file shared nếu muốn

class _TypeToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kBorder.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _Tab(label: t.expense,  val: 0, active: value == 0,
            activeColor: kExpense,  onTap: () => onChanged(0)),
        _Tab(label: t.income,   val: 1, active: value == 1,
            activeColor: kIncome,   onTap: () => onChanged(1)),
        _Tab(label: t.transfer, val: 2, active: value == 2,
            activeColor: kTransfer, onTap: () => onChanged(2)),
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
  const _Tab({required this.label, required this.val, required this.active,
    required this.activeColor, required this.onTap});

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
          child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                fontSize: 14,
                color: active ? Colors.white : kSubtext)),
        ),
      ),
    ),
  );
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String currency;
  final bool isInteger;

  const _AmountField({
    required this.controller,
    required this.label,
    this.currency = 'VND',
    this.isInteger = true,
  });

  Future<void> _openCalculator(BuildContext context) async {
    final raw = controller.text
        .replaceAll(RegExp(r'[,.](?=\d{3})'), '')
        .replaceAll(',', '.')
        .trim();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CalculatorSheet(initialValue: raw),
    );
    if (result != null) {
      final val = double.tryParse(result);
      if (val != null) {
        controller.text = isInteger
            ? NumberFormat('#,##0', 'vi_VN').format(val.round())
            : NumberFormat('#,##0.00', 'en_US').format(val);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(currency, style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.text.isEmpty ? (isInteger ? '0' : '0.00') : value.text,
                  style: GoogleFonts.spaceGrotesk(fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: value.text.isEmpty ? kBorder : kText),
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

class _DateTimeTile extends StatelessWidget {
  final DateTime dt;
  final VoidCallback onTap;
  const _DateTimeTile({required this.dt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.dateTime, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600,
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
              const Icon(Icons.calendar_month_rounded, color: kSubtext, size: 20),
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