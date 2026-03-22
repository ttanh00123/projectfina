// lib/widgets/fina_calculator_field.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/theme/app_theme.dart';
import 'package:taexpense/widgets/calculator_sheet.dart';

class FinaCalculatorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;

  const FinaCalculatorField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '0',
  });

  Future<void> _openCalculator(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CalculatorSheet(initialValue: controller.text),
    );
    if (result != null) controller.text = result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openCalculator(context),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.text.isEmpty ? (hint ?? '0') : value.text,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: value.text.isEmpty ? kSubtext : kText,
                      ),
                    ),
                  ),
                  Icon(Icons.calculate_outlined,
                      size: 18, color: kPrimary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}