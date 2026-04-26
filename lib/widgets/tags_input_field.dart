// lib/widgets/tags_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/theme/app_theme.dart';

class TagsInputField extends StatefulWidget {
  final List<String> tags;
  final List<String> suggestions;    // tags đã dùng trước
  final ValueChanged<List<String>> onChanged;

  const TagsInputField({
    super.key,
    required this.tags,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  State<TagsInputField> createState() => _TagsInputFieldState();
}

class _TagsInputFieldState extends State<TagsInputField> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _ctrl.text;
    // Nhập dấu phẩy → tạo tag ngay
    if (text.endsWith(',')) {
      _addTag(text.replaceAll(',', '').trim());
      return;
    }
    setState(() {
      _filtered = text.isEmpty
          ? []
          : widget.suggestions
              .where((s) =>
                  s.toLowerCase().contains(text.toLowerCase()) &&
                  !widget.tags.contains(s))
              .take(5)
              .toList();
    });
  }

  void _addTag(String tag) {
    if (tag.isEmpty || widget.tags.contains(tag)) {
      _ctrl.clear();
      return;
    }
    final newTags = [...widget.tags, tag];
    widget.onChanged(newTags);
    _ctrl.clear();
    setState(() => _filtered = []);
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Tags', style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF374151))),
      const SizedBox(height: 6),
      // Chip + input box
      Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 6, runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...widget.tags.map((tag) => _TagChip(
              label: tag,
              onRemove: () => _removeTag(tag),
            )),
            IntrinsicWidth(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                decoration: InputDecoration(
                  hintText: widget.tags.isEmpty ? 'ăn uống, cafe...' : '',
                  hintStyle: GoogleFonts.dmSans(
                      fontSize: 14, color: kSubtext),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                style: GoogleFonts.dmSans(fontSize: 14, color: kText),
                onSubmitted: (v) => _addTag(v.trim()),
              ),
            ),
          ],
        ),
      ),
      // Autocomplete suggestions
      if (_filtered.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: _filtered.map((s) => InkWell(
              onTap: () => _addTag(s),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.tag, size: 14, color: kSubtext),
                  const SizedBox(width: 8),
                  Text(s, style: GoogleFonts.dmSans(
                      fontSize: 14, color: kText)),
                ]),
              ),
            )).toList(),
          ),
        ),
      Text('Nhập tag, cách nhau bằng dấu phẩy',
          style: GoogleFonts.dmSans(fontSize: 11, color: kSubtext)),
    ],
  );
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.dmSans(
          fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500)),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 14, color: kPrimary),
      ),
    ]),
  );
}