// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils.dart';
import 'kitchen_sink.factories.dart';
import 'kitchen_sink_interface.dart';
import 'strict_keys_object.dart';

// copied and renamed as private from /lib/src/constants.dart
const _generatedLocalVarName = 'val';
const _toJsonMapHelperName = 'writeNotNull';

final _isATypeError = isA<TypeError>();

// ignore: deprecated_member_use
final _isACastError = isA<CastError>();

Matcher _isAUnrecognizedKeysException(expectedMessage) =>
    isA<UnrecognizedKeysException>()
        .having((e) => e.message, 'message', expectedMessage);

Matcher _isMissingKeyException(expectedMessage) =>
    isA<MissingRequiredKeysException>()
        .having((e) => e.message, 'message', expectedMessage);

void main() {
  test('valid values covers all keys', () {
    expect(_invalidValueTypes.keys, orderedEquals(_validValues.keys));
  });

  test('tracking Map/Iterable types correctly', () {
    for (var entry in _validValues.entries) {
      if (_iterableMapKeys.contains(entry.key) ||
          _encodedAsMapKeys.contains(entry.key)) {
        expect(entry.value, anyOf(isMap, isList));
      } else {
        expect(entry.value, isNot(anyOf(isMap, isList)));
      }
    }
  });

  test('required keys', () {
    expect(
        () => StrictKeysObject.fromJson({}),
        throwsA(_isMissingKeyException(
            'Required keys are missing: value, custom_field.')));
  });

  for (var factory in factories) {
    group(factory.description, () {
      if (factory.nullable) {
        _nullableTests(factory);
      } else {
        _nonNullableTests(factory);
      }
      if (factory.anyMap) {
        _anyMapTests(factory);
      }
      _sharedTests(factory);
    });
  }
}

const _jsonConverterValidValues = {
  'duration': 5,
  'durationList': [5],
  'bigInt': '5',
  'bigIntMap': {'vaule': '5'},
  'numberSilly': 5,
  'numberSillySet': [5],
  'dateTime': 5
};

void _nonNullableTests(KitchenSinkFactory factory) {
  test('with null values fails serialization', () {
    expect(() => (factory.ctor()..objectDateTimeMap = null).toJson(),
        throwsNoSuchMethodError);
  });

  test('with empty json fails deserialization', () {
    Matcher matcher;
    if (factory.checked) {
      matcher = _checkedMatcher('intIterable');
    } else {
      matcher = isNoSuchMethodError;
    }
    expect(() => factory.fromJson(<String, dynamic>{}), throwsA(matcher));
  });

  test('nullable values are not allowed in non-nullable version', () {
    var instance = factory.jsonConverterCtor();
    expect(() => instance.toJson(), throwsNoSuchMethodError,
        reason: 'Trying to call `map` on a null list');

    instance = factory.jsonConverterFromJson(_jsonConverterValidValues);
    final json = instance.toJson();
    expect(json, _jsonConverterValidValues);
    expect(json.values, everyElement(isNotNull));

    final instance2 = factory.jsonConverterFromJson(json);
    expect(instance2.toJson(), json);
  });
}

void _nullableTests(KitchenSinkFactory factory) {
  void roundTripSink(KitchenSink p) {
    roundTripObject(p, factory.fromJson);
  }

  test('nullable values are allowed in the nullable version', () {
    final instance = factory.jsonConverterCtor();
    final json = instance.toJson();

    if (factory.excludeNull) {
      expect(json, isEmpty);
    } else {
      expect(json.values, everyElement(isNull));
      expect(json.keys, unorderedEquals(_jsonConverterValidValues.keys));

      final instance2 = factory.jsonConverterFromJson(json);
      expect(instance2.toJson(), json);
    }
  });

  test('Fields with `!includeIfNull` should not be included when null', () {
    final item = factory.ctor();
    final encoded = item.toJson();

    if (factory.excludeNull) {
      expect(encoded, isEmpty);
    } else {
      expect(encoded.keys, orderedEquals(_validValues.keys));

      for (final key in _validValues.keys) {
        expect(encoded, containsPair(key, isNull));
      }
    }
  });

  test('list and map of DateTime', () {
    final now = DateTime.now();
    final item = factory.ctor(dateTimeIterable: <DateTime>[now])
      ..dateTimeList = <DateTime>[now, null]
      ..objectDateTimeMap = <Object, DateTime>{'value': now, 'null': null};

    roundTripSink(item);
  });

  test('complex nested type', () {
    final item = factory.ctor()
      ..crazyComplex = [
        null,
        {},
        {
          'null': null,
          'empty': {},
          'items': {
            'null': null,
            'empty': [],
            'items': [
              null,
              [],
              [DateTime.now()]
            ]
          }
        }
      ];
    roundTripSink(item);
  });
}

void _anyMapTests(KitchenSinkFactory factory) {
  test('valid values round-trip - yaml', () {
    final jsonEncoded = loudEncode(_validValues);
    final yaml = loadYaml(jsonEncoded, sourceUrl: Uri.parse('input.yaml'));
    expect(jsonEncoded, loudEncode(factory.fromJson(yaml as YamlMap)));
  });

  group('a bad value for', () {
    for (final e in _invalidValueTypes.entries) {
      _testBadValue(e.key, e.value, factory, false);
    }
    for (final e in _invalidCheckedValues.entries) {
      _testBadValue(e.key, e.value, factory, true);
    }
  });
}

void _sharedTests(KitchenSinkFactory factory) {
  test('empty', () {
    final item = factory.ctor();
    roundTripObject(item, factory.fromJson);
  });

  test('list and map of DateTime - not null', () {
    final now = DateTime.now();
    final item = factory.ctor(dateTimeIterable: <DateTime>[now])
      ..dateTimeList = <DateTime>[now, now]
      ..objectDateTimeMap = <Object, DateTime>{'value': now};

    roundTripObject(item, factory.fromJson);
  });

  test('complex nested type - not null', () {
    final item = factory.ctor()
      ..crazyComplex = [
        {},
        {
          'empty': {},
          'items': {
            'empty': [],
            'items': [
              [],
              [DateTime.now()]
            ]
          }
        }
      ];
    roundTripObject(item, factory.fromJson);
  });

  test('round trip valid, empty values', () {
    final values = Map.fromEntries(_validValues.entries.map((e) {
      var value = e.value;
      if (_iterableMapKeys.contains(e.key)) {
        if (value is List) {
          value = [];
        } else {
          assert(value is Map);
          value = <String, dynamic>{};
        }
      }
      return MapEntry(e.key, value);
    }));

    final validInstance = factory.fromJson(values);

    roundTripObject(validInstance, factory.fromJson);
  });

  test('JSON keys should be defined in field/property order', () {
    final json = factory.ctor().toJson();
    if (factory.excludeNull && factory.nullable) {
      expect(json.keys, isEmpty);
    } else {
      expect(json.keys, orderedEquals(_validValues.keys));
    }
  });

  test('valid values round-trip - json', () {
    final validInstance = factory.fromJson(_validValues);
    roundTripObject(validInstance, factory.fromJson);
  });
}

void _testBadValue(String key, Object badValue, KitchenSinkFactory factory,
    bool checkedAssignment) {
  final matcher = _getMatcher(factory.checked, key, checkedAssignment);

  for (final isJson in [true, false]) {
    test('`$key` fails with value `$badValue`- ${isJson ? 'json' : 'yaml'}',
        () {
      var copy = Map.from(_validValues);
      copy[key] = badValue;

      if (!isJson) {
        copy = loadYaml(loudEncode(copy)) as YamlMap;
      }

      expect(() => factory.fromJson(copy), matcher);
    });
  }
}

Matcher _checkedMatcher(String expectedKey) => isA<CheckedFromJsonException>()
    .having((e) => e.className, 'className', 'KitchenSink')
    .having((e) => e.key, 'key', expectedKey);

Matcher _getMatcher(bool checked, String expectedKey, bool checkedAssignment) {
  Matcher innerMatcher;

  if (checked) {
    if (checkedAssignment &&
        const ['intIterable', 'datetime-iterable'].contains(expectedKey)) {
      expectedKey = null;
    }

    innerMatcher = _checkedMatcher(expectedKey);
  } else {
    innerMatcher = anyOf(
      _isACastError,
      _isATypeError,
      _isAUnrecognizedKeysException(
        'Unrecognized keys: [invalid_key]; supported keys: '
        '[value, custom_field]',
      ),
    );

    if (checkedAssignment) {
      switch (expectedKey) {
        case 'validatedPropertyNo42':
          innerMatcher = isStateError;
          break;
        case 'no-42':
          innerMatcher = isArgumentError;
          break;
        case 'strictKeysObject':
          innerMatcher = _isAUnrecognizedKeysException('bob');
          break;
        case 'intIterable':
        case 'datetime-iterable':
          innerMatcher = _isACastError;
          break;
        default:
          throw StateError('Not expected! - $expectedKey');
      }
    }
  }

  return throwsA(innerMatcher);
}

const _validValues = <String, dynamic>{
  'no-42': 0,
  'dateTime': '2018-05-10T14:20:58.927',
  'bigInt': '10000000000000000000',
  'iterable': [true],
  'dynamicIterable': [true],
  'objectIterable': [true],
  'intIterable': [42],
  'set': [true],
  'dynamicSet': [true],
  'objectSet': [true],
  'intSet': [42],
  'dateTimeSet': ['2018-05-10T14:20:58.927'],
  'datetime-iterable': ['2018-05-10T14:20:58.927'],
  'list': [true],
  'dynamicList': [true],
  'objectList': [true],
  'intList': [42],
  'dateTimeList': ['2018-05-10T14:20:58.927'],
  'map': <String, dynamic>{'key': true},
  'stringStringMap': <String, dynamic>{'key': 'vaule'},
  'dynamicIntMap': <String, dynamic>{'key': 42},
  'objectDateTimeMap': <String, dynamic>{'key': '2018-05-10T14:20:58.927'},
  'crazyComplex': [<String, dynamic>{}],
  _generatedLocalVarName: <String, dynamic>{'key': true},
  _toJsonMapHelperName: true,
  r'$string': 'string',
  'simpleObject': {'value': 42},
  'strictKeysObject': {'value': 10, 'custom_field': 'cool'},
  'validatedPropertyNo42': 0
};

const _invalidValueTypes = {
  'no-42': true,
  'dateTime': true,
  'bigInt': true,
  'iterable': true,
  'dynamicIterable': true,
  'objectIterable': true,
  'intIterable': true,
  'set': true,
  'dynamicSet': true,
  'objectSet': true,
  'intSet': true,
  'dateTimeSet': true,
  'datetime-iterable': true,
  'list': true,
  'dynamicList': true,
  'objectList': true,
  'intList': [true],
  'dateTimeList': [true],
  'map': true,
  'stringStringMap': {'key': 42},
  'dynamicIntMap': {'key': 'value'},
  'objectDateTimeMap': {'key': 42},
  'crazyComplex': [true],
  _generatedLocalVarName: {'key': 42},
  _toJsonMapHelperName: 42,
  r'$string': true,
  'simpleObject': 42,
  'strictKeysObject': {
    'value': 10,
    'invalid_key': true,
  },
  'validatedPropertyNo42': true
};

/// Invalid values that are found after the property set or ctor call
const _invalidCheckedValues = {
  'no-42': 42,
  'validatedPropertyNo42': 42,
  'intIterable': [true],
  'datetime-iterable': [true],
};

const _encodedAsMapKeys = ['simpleObject', 'strictKeysObject'];

const _iterableMapKeys = [
  'bigIntMap',
  'crazyComplex',
  'datetime-iterable',
  'dateTimeList',
  'dateTimeSet',
  'durationList',
  'dynamicIntMap',
  'dynamicIterable',
  'dynamicList',
  'dynamicSet',
  'intIterable',
  'intList',
  'intSet',
  'iterable',
  'list',
  'map',
  'numberSillySet',
  'objectDateTimeMap',
  'objectIterable',
  'objectList',
  'objectSet',
  'set',
  'stringStringMap',
  _generatedLocalVarName,
];
