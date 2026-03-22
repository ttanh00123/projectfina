// lib/widgets/calculator_sheet.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/theme/app_theme.dart';

class CalculatorSheet extends StatefulWidget {
  final String initialValue;
  const CalculatorSheet({super.key, this.initialValue = ''});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expr = '';
  String _display = '0';
  String _exprLabel = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue.isNotEmpty && widget.initialValue != '0') {
      _expr = widget.initialValue;
      _display = widget.initialValue;
    }
  }

  void _input(String c) {
    setState(() {
      const ops = ['+', '-', '×', '÷'];
      final last = _expr.isEmpty ? '' : _expr[_expr.length - 1];
      if (ops.contains(c) && ops.contains(last)) {
        _expr = _expr.substring(0, _expr.length - 1) + c;
      } else {
        _expr += c;
      }
      _exprLabel = _expr;
      _display = _tryEval(_expr) ?? _expr;
    });
  }

  void _delete() {
    setState(() {
      if (_expr.isEmpty) return;
      _expr = _expr.substring(0, _expr.length - 1);
      _exprLabel = _expr;
      _display = _expr.isEmpty ? '0' : (_tryEval(_expr) ?? _expr);
    });
  }

  void _equals() {
    final result = _tryEval(_expr);
    if (result == null) return;
    setState(() {
      _exprLabel = '$_expr =';
      _expr = result;
      _display = result;
    });
  }

  // Evaluate expression string safely
  String? _tryEval(String expr) {
    try {
      final normalized = expr.replaceAll('×', '*').replaceAll('÷', '/');
      // Simple recursive descent — safe, no dart:mirrors
      final val = _eval(normalized);
      if (val == null || val.isNaN || val.isInfinite) return null;
      final rounded = (val * 100).round() / 100;
      return rounded == rounded.truncate()
          ? rounded.toInt().toString()
          : rounded.toString();
    } catch (_) {
      return null;
    }
  }

  // Minimal expression evaluator (+-*/)
  double? _eval(String s) {
    s = s.trim();
    // Find last + or - outside parens
    int depth = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      final c = s[i];
      if (c == ')') depth++;
      if (c == '(') depth--;
      if (depth == 0 && (c == '+' || c == '-') && i > 0) {
        final left  = _eval(s.substring(0, i));
        final right = _eval(s.substring(i + 1));
        if (left == null || right == null) return null;
        return c == '+' ? left + right : left - right;
      }
    }
    // Find last * or /
    depth = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      final c = s[i];
      if (c == ')') depth++;
      if (c == '(') depth--;
      if (depth == 0 && (c == '*' || c == '/') && i > 0) {
        final left  = _eval(s.substring(0, i));
        final right = _eval(s.substring(i + 1));
        if (left == null || right == null) return null;
        if (c == '/' && right == 0) return null;
        return c == '*' ? left * right : left / right;
      }
    }
    // Parentheses
    if (s.startsWith('(') && s.endsWith(')')) {
      return _eval(s.substring(1, s.length - 1));
    }
    return double.tryParse(s);
  }

  void _confirm() {
    final result = _tryEval(_expr) ?? _expr;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _exprLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 14, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 4),
                Text(
                  _display,
                  style: GoogleFonts.dmSans(
                    fontSize: 38, fontWeight: FontWeight.w500,
                    color: kText, letterSpacing: -1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _row([
                  _CalcBtn('⌫',  _delete,    type: _BtnType.del),
                  _CalcBtn('(',   () => _input('('),  type: _BtnType.op),
                  _CalcBtn(')',   () => _input(')'),  type: _BtnType.op),
                  _CalcBtn('÷',   () => _input('÷'),  type: _BtnType.op),
                ]),
                _row([
                  _CalcBtn('7', () => _input('7')),
                  _CalcBtn('8', () => _input('8')),
                  _CalcBtn('9', () => _input('9')),
                  _CalcBtn('×', () => _input('×'), type: _BtnType.op),
                ]),
                _row([
                  _CalcBtn('4', () => _input('4')),
                  _CalcBtn('5', () => _input('5')),
                  _CalcBtn('6', () => _input('6')),
                  _CalcBtn('−', () => _input('-'), type: _BtnType.op),
                ]),
                _row([
                  _CalcBtn('1', () => _input('1')),
                  _CalcBtn('2', () => _input('2')),
                  _CalcBtn('3', () => _input('3')),
                  _CalcBtn('+', () => _input('+'), type: _BtnType.op),
                ]),
                _row([
                  _CalcBtn('0', () => _input('0'), flex: 2),
                  _CalcBtn('.', () => _input('.')),
                  _CalcBtn('=', _equals, type: _BtnType.eq),
                ]),
              ],
            ),
          ),
          // OK button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('OK — Dán kết quả',
                    style: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<_CalcBtn> btns) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: btns.map((b) => Expanded(
        flex: b.flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildBtn(b),
        ),
      )).toList(),
    ),
  );

  Widget _buildBtn(_CalcBtn b) {
    Color bg;
    Color fg;
    switch (b.type) {
      case _BtnType.op:
        bg = kPrimary.withOpacity(0.12);
        fg = kPrimary;
        break;
      case _BtnType.eq:
        bg = kPrimary;
        fg = Colors.white;
        break;
      case _BtnType.del:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = kText;
    }
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: b.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(b.label,
            style: GoogleFonts.dmSans(
                fontSize: 22, fontWeight: FontWeight.w500, color: fg)),
      ),
    );
  }
}

enum _BtnType { normal, op, eq, del }

class _CalcBtn {
  final String label;
  final VoidCallback onTap;
  final _BtnType type;
  final int flex;
  const _CalcBtn(this.label, this.onTap,
      {this.type = _BtnType.normal, this.flex = 1});
}