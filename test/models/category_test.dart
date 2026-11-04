import 'package:flutter_test/flutter_test.dart';
import 'package:taexpense/models/category.dart';

void main() {
  test('decodes CSV keywords for the requested locale', () {
    final category = Category.fromJson({
      'id': 9,
      'name': 'Food & Drink',
      'type': 0,
      'sort_order': 1,
      'keywords': {
        'vi': 'cafe, "vịt quay", ăn uống',
        'en': 'coffee, roasted duck, food',
      },
    });

    expect(category.keywords, ['cafe', 'vịt quay', 'ăn uống']);
  });

  test('keeps supporting the legacy keyword list payload', () {
    final category = Category.fromJson({
      'id': 9,
      'name': 'Food & Drink',
      'type': 0,
      'sort_order': 1,
      'keywords': ['cafe', 'food'],
    });

    expect(category.keywords, ['cafe', 'food']);
  });
}
