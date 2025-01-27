import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('ListParam equality for Map key', () {
    final param1 = const ListParam(['item1', 'item2'], ListFormat.csv);
    final param2 = const ListParam(['item1', 'item2'], ListFormat.csv);
    final param3 = const ListParam(['item3', 'item4'], ListFormat.csv);
    final param4 = const ListParam(['item2', 'item1'], ListFormat.csv);

    final cache = {param1: 'Cached Response'};

    expect(
      cache.containsKey(param2),
      true,
      reason: 'param1 and param2 should be considered equal',
    );

    expect(
      cache.containsKey(param3),
      false,
      reason: 'param1 and param3 should not be considered equal',
    );

    expect(
      cache.containsKey(param4),
      false,
      reason:
          'param1 and param4 should not be considered equal as order matters',
    );
  });
}
