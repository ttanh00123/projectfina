// lib/services/bill_upload_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class BillUploadService {
  static const _baseUrl = 'https://your-api.com';

  /// Upload ảnh lên s3_bucket/temp, trả về temp key
  static Future<String> uploadTemp(File file, String authToken) async {
    final uri     = Uri.parse('$_baseUrl/bills/upload-temp');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $authToken'
      ..files.add(await http.MultipartFile.fromPath(
        'file', file.path,
        contentType: MediaType('image', 'jpeg'),
        filename: p.basename(file.path),
      ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
    final body = await response.stream.bytesToString();
    // Server trả về: { "temp_key": "temp/abc123.jpg" }
    return (jsonDecode(body) as Map)['temp_key'] as String;
  }
}