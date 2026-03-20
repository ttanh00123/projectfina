import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimary   = Colors.indigo;
const kPrimaryL  = Colors.indigoAccent;
const kBg        = Color(0xFFF6F8F7);
const kCard      = Colors.white;
const kText      = Color.fromARGB(255, 50, 51, 57);
const kSubtext   = Color(0xFF6B7280);
const kBorder    = Color(0xFFE5E7EB);
const kError     = Color(0xFFEF4444);
const kIncome    = Color(0xFF059669);
const kExpense   = Color(0xFFDC2626);

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: kPrimary,
    secondary: kPrimaryL,
    surface: kBg,
    error: kError,
  ),
  scaffoldBackgroundColor: kBg,
  textTheme: GoogleFonts.dmSansTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    iconTheme: const IconThemeData(color: kText),
    titleTextStyle: GoogleFonts.spaceGrotesk(
      fontSize: 18, fontWeight: FontWeight.w700, color: kText,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary, foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0, minimumSize: const Size(double.infinity, 54),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 2)),
    hintStyle: GoogleFonts.dmSans(color: const Color(0xFF9CA3AF), fontSize: 15),
  ),
);
