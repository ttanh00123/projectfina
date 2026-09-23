// lib/models/category.dart

class Category {
  final int    id;
  final String name;
  final String icon;
  final int    type;
  final int    sortOrder;
  final int?   masterId;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.sortOrder,
    this.masterId,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id:        j['id']         as int,
    name:      j['name']       as String,
    icon:      j['icon']       as String? ?? 'category',
    type:      j['type']       as int? ?? 0,
    sortOrder: j['sort_order'] as int? ?? 0,
    masterId:  j['master_id']  as int?,
  );
}