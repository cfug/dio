import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('ListParam equality for Map key', () {
    final param1 = const ListParam(['item1', 'item2'], ListFormat.csv);
    final param2 = const ListParam(['item1', 'item2'], ListFormat.csv);

    final cache = {param1: 'Cached Response'};

    expect(cache.containsKey(param2), true, reason: 'param1 and param2 should be considered equal');
  });
}
