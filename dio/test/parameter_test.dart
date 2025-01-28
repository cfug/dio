import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('ListParam', () {
    test('param1 and param2 should be considered equal', () {
      final param1 = const ListParam(['item1', 'item2'], ListFormat.csv);
      final param2 = const ListParam(['item1', 'item2'], ListFormat.csv);
      expect(param1 == param2, isTrue);
    });

    test('param1 and param3 should not be considered equal', () {
      final param1 = const ListParam(['item1', 'item2'], ListFormat.csv);
      final param3 = const ListParam(['item3', 'item4'], ListFormat.csv);
      expect(param1 == param3, isFalse);
    });

    test('Order matters: param1 and param4 should not be equal', () {
      final param1 = const ListParam(['item1', 'item2'], ListFormat.csv);
      final param4 = const ListParam(['item2', 'item1'], ListFormat.csv);
      expect(param1 == param4, isFalse);
    });
  });
}
