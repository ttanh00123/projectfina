// lib/models/category.dart

class Category {
  final int id;
  final String name;
  final String icon;
  final int type;
  final int sortOrder;
  final int? masterId;
  final List<String> keywords;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.sortOrder,
    this.masterId,
    this.keywords = const [],
  });

  factory Category.fromJson(
    Map<String, dynamic> j, {
    String locale = 'vi',
  }) =>
      Category(
        id: j['id'] as int,
        name: j['name'] as String,
        icon: j['icon'] as String? ?? 'category',
        type: j['type'] as int? ?? 0,
        sortOrder: j['sort_order'] as int? ?? 0,
        masterId: j['master_id'] as int?,
        keywords: _decodeKeywords(j['keywords'], locale),
      );

  static List<String> _decodeKeywords(dynamic raw, String locale) {
    if (raw is Map) {
      raw = raw[locale] ?? raw['any'] ?? raw['vi'] ?? raw['en'];
    }

    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      return _splitCsv(raw);
    }

    return const [];
  }

  static List<String> _splitCsv(String value) {
    final result = <String>[];
    final buffer = StringBuffer();
    var quoted = false;

    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == '"') {
        if (quoted && i + 1 < value.length && value[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        final keyword = buffer.toString().trim();
        if (keyword.isNotEmpty) result.add(keyword);
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    final keyword = buffer.toString().trim();
    if (keyword.isNotEmpty) result.add(keyword);
    return result;
  }
}
