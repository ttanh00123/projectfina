import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Logo ──────────────────────────────────────────────────────────────────────
class FinaLogo extends StatelessWidget {
  final double size;
  const FinaLogo({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(size * 0.27)),
        // child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: size * 0.55),
        child:
        Center(
        child: SvgPicture.asset(
          'assets/icon/fina_icon.svg',
          width: size * 0.55,
          height: size * 0.55,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      )
      ),
      const SizedBox(width: 8),
      Text('FinA', style: GoogleFonts.spaceGrotesk(
        fontSize: size * 0.72, fontWeight: FontWeight.w800, color: kText,
      )),
    ],
  );
}

// ── Button ────────────────────────────────────────────────────────────────────
class FinaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;
  const FinaButton({super.key, required this.label, this.onPressed,
    this.isLoading = false, this.color, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 54,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? kPrimary,
        disabledBackgroundColor: (color ?? kPrimary).withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isLoading
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white)))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: GoogleFonts.dmSans(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
    ),
  );
}

// ── Text Field ────────────────────────────────────────────────────────────────
// lib/widgets/fina_widgets.dart

class FinaField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final Widget? prefix, suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged; // thêm dòng này

  const FinaField({super.key, required this.label, this.hint,
    required this.controller, this.obscure = false,
    this.keyboard = TextInputType.text, this.validator,
    this.prefix, this.suffix, this.readOnly = false,
    this.onTap, this.onChanged}); // thêm this.onChanged

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: keyboard, validator: validator,
        readOnly: readOnly, onTap: onTap,
        onChanged: onChanged, // thêm dòng này
        style: GoogleFonts.dmSans(fontSize: 15, color: kText),
        decoration: InputDecoration(
          hintText: hint, prefixIcon: prefix, suffixIcon: suffix),
      ),
    ],
  );
}

// ── Dropdown Field ────────────────────────────────────────────────────────────
class FinaDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const FinaDropdown({super.key, required this.label, required this.value,
    required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      DropdownButtonFormField<T>(
        value: value, items: items, onChanged: onChanged,
        style: GoogleFonts.dmSans(fontSize: 15, color: kText),
        dropdownColor: Colors.white, borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kSubtext),
        decoration: const InputDecoration(),
      ),
    ],
  );
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFCA5A5))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: kError, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: GoogleFonts.dmSans(
        color: const Color(0xFFB91C1C), fontSize: 13.5))),
    ]),
  );
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: GoogleFonts.spaceGrotesk(
      fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
  );
}
