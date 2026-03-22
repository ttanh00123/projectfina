import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/transaction_data.dart';
import 'package:taexpense/services/transaction_service.dart' as TransactionService;
import 'package:taexpense/session.dart';
import 'package:taexpense/utils/utils.dart';
import 'package:taexpense/widgets/calculator_sheet.dart';
// import '../models/user.dart';
// import '../services/api_service.dart';
// import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
// import '../utils/constants.dart';
import '../widgets/fina_widgets.dart';

class CreateTransactionScreen extends StatefulWidget {
  final TransactionData? prefill;
  const CreateTransactionScreen({super.key, this.prefill});
  @override State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  final _form    = GlobalKey<FormState>();
  final _amount  = TextEditingController();
  final _address = TextEditingController();
  final _note    = TextEditingController();

  String _type     = 'expense';
  String _currency = 'VND';
  String _wallet   = 'Cash';
  String _category = 'Food & Drinks';
  DateTime _dt     = DateTime.now();
  String? _requestId;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _type       = p.type;
      _currency   = p.currency;
      _wallet     = _capitalise(p.wallet);
      _category   = p.category;
      _requestId  = p.requestId;
      _amount.text = p.amount.toStringAsFixed(p.amount % 1 == 0 ? 0 : 2);
      if (p.address != null) _address.text = p.address!;
      if (p.note != null) _note.text = p.note!;
      try { _dt = DateTime.parse(p.dateTime).toLocal(); } catch (_) {}
    }
    // Ensure wallet matches list
    if (!kWallets.contains(_wallet)) _wallet = kWallets.first;
    if (!kCategories.contains(_category)) _category = kCategories.first;
  }

  String _capitalise(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  void dispose() { _amount.dispose(); _address.dispose(); _note.dispose(); super.dispose(); }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dt,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
        child: child!));
    if (time == null) return;
    setState(() => _dt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    // final auth = context.read<AuthProvider>();
    try {
      await TransactionService.saveTransaction({
        'type': _type,
        'amount': double.parse(_amount.text.replaceAll(',', '')),
        'currency': _currency,
        'wallet': _wallet.toLowerCase(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'category': _category,
        'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
        'date_time': _dt.toUtc().toIso8601String(),
        'request_id': _requestId,
      }, Session.token!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Transaction saved!', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        Navigator.pop(context);
        Navigator.pop(context); // go back past chat
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      title: const Text('New Transaction'),
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: kText),
        onPressed: () => Navigator.pop(context)),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text('Save', style: GoogleFonts.dmSans(
            color: kPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ...[ErrorBanner(message: _error!), const SizedBox(height: 16)],

            // Type toggle
            _TypeToggle(value: _type, onChanged: (v) => setState(() => _type = v)),
            const SizedBox(height: 20),

            // Amount + Currency row
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(flex: 3, child: _AmountField(controller: _amount)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: FinaDropdown<String>(
                label: 'Currency', value: _currency,
                items: kCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              )),
            ]),
            const SizedBox(height: 20),

            // Wallet
            FinaDropdown<String>(
              label: 'Wallet', value: _wallet,
              items: kWallets.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (v) => setState(() => _wallet = v ?? _wallet),
            ),
            const SizedBox(height: 20),

            // Address
            FinaField(
              label: 'Address / Merchant', hint: 'e.g. Highlands Coffee',
              controller: _address,
              prefix: const Icon(Icons.location_on_outlined, size: 20, color: kSubtext),
            ),
            const SizedBox(height: 20),

            // Date time picker
            _DateTimeTile(dt: _dt, onTap: _pickDateTime),
            const SizedBox(height: 20),

            // Category
            FinaDropdown<String>(
              label: 'Category', value: _category,
              items: kCategories.map((c) => DropdownMenuItem(value: c,
                child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 20),

            // Note
            FinaField(
              label: 'Note (optional)', hint: 'Add a note...',
              controller: _note,
              prefix: const Icon(Icons.notes_rounded, size: 20, color: kSubtext),
            ),
            const SizedBox(height: 32),

            FinaButton(label: _saving ? 'Saving...' : 'Save Transaction',
              onPressed: _save, isLoading: _saving,
              icon: Icons.save_rounded),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    ),
  );
}

// ── Type Toggle ───────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: kBorder.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      _Toggle(label: 'Expense', val: 'expense', active: value == 'expense',
        activeColor: kExpense, onTap: () => onChanged('expense')),
      _Toggle(label: 'Income', val: 'income', active: value == 'income',
        activeColor: kIncome, onTap: () => onChanged('income')),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final String label, val; final bool active;
  final Color activeColor; final VoidCallback onTap;
  const _Toggle({required this.label, required this.val, required this.active,
    required this.activeColor, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(11)),
      child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14,
          color: active ? Colors.white : kSubtext)),
    ),
  ));
}

// ── Amount Field ──────────────────────────────────────────────────────────────
// class _AmountField extends StatelessWidget {
//   final TextEditingController controller;
//   const _AmountField({required this.controller});
//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text('Amount', style: GoogleFonts.dmSans(
//         fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
//       const SizedBox(height: 6),
//       TextFormField(
//         controller: controller,
//         keyboardType: const TextInputType.numberWithOptions(decimal: true),
//         inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
//         style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: kText),
//         validator: (v) {
//           if (v == null || v.isEmpty) return 'Required';
//           if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid';
//           return null;
//         },
//         decoration: InputDecoration(
//           hintText: '0',
//           hintStyle: GoogleFonts.spaceGrotesk(fontSize: 20, color: kBorder),
//           prefixIcon: const Icon(Icons.attach_money_rounded, color: kSubtext, size: 20),
//           filled: true, fillColor: const Color(0xFFF9FAFB),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: kBorder)),
//           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: kBorder)),
//           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: kPrimary, width: 2)),
//           errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: kError)),
//         ),
//       ),
//     ],
//   );
// }

// Thay _AmountField bằng cái này trong create_transaction_screen.dart

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  Future<void> _openCalculator(BuildContext context) async {
    final raw = controller.text.replaceAll(',', '');
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
      // Format số có dấu phẩy ngàn
      final val = double.tryParse(result);
      if (val != null) {
        controller.text = NumberFormat('#,##0.##', 'vi_VN').format(val);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Amount', style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) => GestureDetector(
          onTap: () => _openCalculator(context),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value.text.isEmpty ? kBorder : kPrimary,
                width: value.text.isEmpty ? 1 : 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.attach_money_rounded,
                    color: kSubtext, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.text.isEmpty ? '0' : value.text,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: value.text.isEmpty ? kBorder : kText,
                    ),
                  ),
                ),
                Icon(Icons.calculate_outlined,
                    size: 18, color: kPrimary.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ── DateTime Tile ─────────────────────────────────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  final DateTime dt; final VoidCallback onTap;
  const _DateTimeTile({required this.dt, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Date & Time', style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
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
