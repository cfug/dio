// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../test_utils.dart';
import 'json_test_common.dart' show Category, Platform, StatusCode;
import 'json_test_example.dart';

Matcher _throwsArgumentError(matcher) =>
    throwsA(isArgumentError.having((e) => e.message, 'message', matcher));

void main() {
  group('Person', () {
    void roundTripPerson(Person p) {
      roundTripObject(p, (json) => Person.fromJson(json));
    }

    test('null', () {
      roundTripPerson(Person(null, null, null));
    });

    test('empty', () {
      roundTripPerson(Person('', '', null,
          middleName: '', dateOfBirth: DateTime.fromMillisecondsSinceEpoch(0)));
    });

    test('now', () {
      roundTripPerson(Person('a', 'b', Category.charmed,
          middleName: 'c', dateOfBirth: DateTime.now()));
    });

    test('now toUtc', () {
      roundTripPerson(Person('a', 'b', Category.bottom,
          middleName: 'c', dateOfBirth: DateTime.now().toUtc()));
    });

    test('empty json', () {
      final person = Person.fromJson({});
      expect(person.dateOfBirth, isNull);
      roundTripPerson(person);
    });

    test('enum map', () {
      final person = Person(null, null, null)
        ..houseMap = {'bob': Category.strange}
        ..categoryCounts = {Category.strange: 1};
      expect(person.dateOfBirth, isNull);
      roundTripPerson(person);
    });
  });

  group('Order', () {
    void roundTripOrder(Order p) {
      roundTripObject(p, (json) => Order.fromJson(json));
    }

    test('null', () {
      roundTripOrder(Order(Category.charmed)..statusCode = StatusCode.success);
    });

    test('empty', () {
      roundTripOrder(Order(Category.strange, const [])
        ..statusCode = StatusCode.success
        ..count = 0
        ..isRushed = false);
    });

    test('simple', () {
      roundTripOrder(Order(Category.top, <Item>[
        Item(24)
          ..itemNumber = 42
          ..saleDates = [DateTime.now()]
      ])
        ..statusCode = StatusCode.success
        ..count = 42
        ..isRushed = true);
    });

    test('almost empty json', () {
      final order = Order.fromJson({'category': 'not_discovered_yet'});
      expect(order.items, isEmpty);
      expect(order.category, Category.notDiscoveredYet);
      expect(
        order.statusCode,
        StatusCode.success,
        reason: 'success is the default on an unset value',
      );
      roundTripOrder(order);
    });

    test('required, but missing enum value fails', () {
      expect(
          () => Order.fromJson({}),
          _throwsArgumentError('A value must be provided. Supported values: '
              'top, bottom, strange, charmed, up, down, not_discovered_yet'));
    });

    test('mismatched enum value fails', () {
      expect(
          () => Order.fromJson({'category': 'weird'}),
          _throwsArgumentError('`weird` is not one of the supported values: '
              'top, bottom, strange, charmed, up, down, not_discovered_yet'));
    });

    test('platform', () {
      final order = Order(Category.charmed)
        ..statusCode = StatusCode.success
        ..platform = Platform.undefined
        ..altPlatforms = {
          'u': Platform.undefined,
          'f': Platform.foo,
          'null': null
        };

      roundTripOrder(order);
    });

    test('homepage', () {
      final order = Order(Category.charmed)
        ..platform = Platform.undefined
        ..statusCode = StatusCode.success
        ..altPlatforms = {
          'u': Platform.undefined,
          'f': Platform.foo,
          'null': null
        }
        ..homepage = Uri.parse('https://dart.dev');

      roundTripOrder(order);
    });

    test('statusCode', () {
      final order = Order.fromJson(
        {'category': 'not_discovered_yet', 'status_code': 404},
      );
      expect(order.statusCode, StatusCode.notFound);
      roundTripOrder(order);
    });

    test('statusCode "500" - weird', () {
      final order = Order.fromJson(
        {'category': 'not_discovered_yet', 'status_code': '500'},
      );
      expect(order.statusCode, StatusCode.weird);
      roundTripOrder(order);
    });

    test('statusCode `500` - unknown', () {
      final order = Order.fromJson(
        {'category': 'not_discovered_yet', 'status_code': 500},
      );
      expect(order.statusCode, StatusCode.unknown);
      roundTripOrder(order);
    });

    test('duration toJson', () {
      final order = Order(Category.notDiscoveredYet)
        ..statusCode = StatusCode.success
        ..duration = const Duration(
          days: 2,
          hours: 4,
          minutes: 54,
          seconds: 33,
          milliseconds: 23,
          microseconds: 12,
        );
      expect(order.toJson()['duration'], equals(190473023012));
      roundTripOrder(order);
    });

    test('duration fromJson', () {
      final order = Order.fromJson({
        'category': 'not_discovered_yet',
        'duration': 190473023012,
      });
      expect(
          order.duration,
          equals(const Duration(
            days: 2,
            hours: 4,
            minutes: 54,
            seconds: 33,
            milliseconds: 23,
            microseconds: 12,
          )));
      roundTripOrder(order);
    });
  });

  group('Item', () {
    void roundTripItem(Item p) {
      roundTripObject(p, (json) => Item.fromJson(json));
    }

    test('empty json', () {
      final item = Item.fromJson({});
      expect(item.saleDates, isNull);
      roundTripItem(item);

      expect(item.toJson().keys, orderedEquals(['price', 'saleDates', 'rates']),
          reason: 'Omits null `itemNumber`');
    });

    test('set itemNumber - with custom JSON key', () {
      final item = Item.fromJson({'item-number': 42});
      expect(item.itemNumber, 42);
      roundTripItem(item);

      expect(item.toJson().keys,
          orderedEquals(['price', 'item-number', 'saleDates', 'rates']),
          reason: 'Includes non-null `itemNumber` - with custom key');
    });
  });

  group('Numbers', () {
    void roundTripNumber(Numbers p) {
      roundTripObject(p, (json) => Numbers.fromJson(json));
    }

    test('simple', () {
      roundTripNumber(Numbers()
        ..nums = [0, 0.0]
        ..doubles = [0.0]
        ..nnDoubles = [0.0]
        ..ints = [0]
        ..duration = const Duration(seconds: 1)
        ..date = DateTime.now());
    });

    test('custom DateTime', () {
      final instance = Numbers()
        ..date = DateTime.fromMillisecondsSinceEpoch(42);
      final json = instance.toJson();
      expect(json, containsPair('date', 42000));
    });

    test('support ints as doubles', () {
      final value = {
        'doubles': [0, 0.0, null],
        'nnDoubles': [0, 0.0]
      };

      roundTripNumber(Numbers.fromJson(value));
    });

    test('does not support doubles as ints', () {
      final value = {
        'ints': [3.14, 0],
      };

      expect(() => Numbers.fromJson(value), throwsCastError);
    });
  });

  test('MapKeyVariety', () {
    final instance = MapKeyVariety()
      ..bigIntMap = {BigInt.from(1): 1}
      ..dateTimeIntMap = {DateTime.parse('2018-01-01'): 2}
      ..intIntMap = {3: 3}
      ..uriIntMap = {Uri.parse('https://example.com'): 4};

    final roundTrip =
        roundTripObject(instance, (j) => MapKeyVariety.fromJson(j));

    expect(roundTrip, instance);
  });

  test('UnknownEnumValue', () {
    final instance = UnknownEnumValue.fromJson({
      'enumValue': 'nope',
      'enumIterable': ['nope'],
      'enumList': ['nope'],
      'enumSet': ['nope'],
    });

    expect(instance.enumValue, Category.notDiscoveredYet);
    expect(instance.enumIterable, [Category.notDiscoveredYet]);
    expect(instance.enumList, [Category.notDiscoveredYet]);
    expect(instance.enumSet, [Category.notDiscoveredYet]);
  });
}
