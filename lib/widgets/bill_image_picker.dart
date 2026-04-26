// lib/widgets/bill_image_picker.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:taexpense/theme/app_theme.dart';

class BillImagePicker extends StatelessWidget {
  final List<File> images;
  final ValueChanged<List<File>> onChanged;
  static const maxImages = 3;
  static const maxDimension = 1024;

  const BillImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (images.length >= maxImages) return;
    final picker = ImagePicker();
    final picked  = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    // Resize tại client về max 1024px
    final resized = await _resize(File(picked.path));
    onChanged([...images, resized]);
  }

  Future<File> _resize(File file) async {
    final bytes  = await file.readAsBytes();
    var decoded  = img.decodeImage(bytes);
    if (decoded == null) return file;

    // Chỉ resize nếu vượt max
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width:  decoded.width > decoded.height ? maxDimension : -1,
        height: decoded.height >= decoded.width ? maxDimension : -1,
      );
    }

    final dir     = await getTemporaryDirectory();
    final outPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final out     = File(outPath)..writeAsBytesSync(img.encodeJpg(decoded, quality: 85));
    return out;
  }

  void _remove(int index) {
    final updated = [...images]..removeAt(index);
    onChanged(updated);
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text('Chọn từ thư viện',
                style: GoogleFonts.dmSans(fontSize: 15)),
            onTap: () { Navigator.pop(context); _pick(context, ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: Text('Chụp ảnh',
                style: GoogleFonts.dmSans(fontSize: 15)),
            onTap: () { Navigator.pop(context); _pick(context, ImageSource.camera); },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ảnh hoá đơn', style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF374151))),
      const SizedBox(height: 8),
      Row(children: [
        // Thumbnail list
        ...images.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(e.value,
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
            Positioned(top: 4, right: 4,
              child: GestureDetector(
                onTap: () => _remove(e.key),
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
            ),
          ]),
        )),
        // Add button
        if (images.length < maxImages)
          GestureDetector(
            onTap: () => _showSourcePicker(context),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: kBorder, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: kSubtext),
                  const SizedBox(height: 4),
                  Text('${images.length}/$maxImages',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: kSubtext)),
                ],
              ),
            ),
          ),
      ]),
    ],
  );
}