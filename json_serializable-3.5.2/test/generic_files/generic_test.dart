// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import '../test_utils.dart';
import 'generic_argument_factories.dart';
import 'generic_class.dart';

void main() {
  group('generic', () {
    GenericClass<T, S> roundTripGenericClass<T extends num, S>(
        GenericClass<T, S> p) {
      final outputJson = loudEncode(p);
      final p2 = GenericClass<T, S>.fromJson(
          jsonDecode(outputJson) as Map<String, dynamic>);
      final outputJson2 = loudEncode(p2);
      expect(outputJson2, outputJson);
      return p2;
    }

    test('no type args', () {
      roundTripGenericClass(GenericClass()
        ..fieldDynamic = 1
        ..fieldInt = 2
        ..fieldObject = 3
        ..fieldT = 5
        ..fieldS = 'six');
    });
    test('with type arguments', () {
      roundTripGenericClass(GenericClass<double, String>()
        ..fieldDynamic = 1
        ..fieldInt = 2
        ..fieldObject = 3
        ..fieldT = 5.0
        ..fieldS = 'six');
    });
    test('with bad arguments', () {
      expect(
          () => GenericClass<double, String>()
            ..fieldT = (true as dynamic) as double,
          throwsCastError);
    });
    test('with bad arguments', () {
      expect(
          () =>
              GenericClass<double, String>()..fieldS = (5 as dynamic) as String,
          throwsCastError);
    });
  });

  group('genericArgumentFactories', () {
    test('basic round-trip', () {
      final instance = GenericClassWithHelpers<DateTime, Duration>(
        DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
        [
          DateTime.fromMillisecondsSinceEpoch(1).toUtc(),
          DateTime.fromMillisecondsSinceEpoch(2).toUtc(),
        ],
        {const Duration(milliseconds: 3), const Duration(milliseconds: 4)},
      );

      String encodeDateTime(DateTime value) => value?.toIso8601String();
      int encodeDuration(Duration value) => value.inMilliseconds;

      final encodedJson = loudEncode(
        instance.toJson(encodeDateTime, encodeDuration),
      );

      final decoded = GenericClassWithHelpers<DateTime, Duration>.fromJson(
        jsonDecode(encodedJson) as Map<String, dynamic>,
        (value) => DateTime.parse(value as String),
        (value) => Duration(milliseconds: value as int),
      );

      final encodedJson2 = loudEncode(
        decoded.toJson(encodeDateTime, encodeDuration),
      );

      expect(encodedJson2, encodedJson);
    });
  });

  group('argument factories', () {
    test('round trip decode/decode', () {
      const inputJson = r'''
{
 "value": {
  "value": 5,
  "list": [
   5
  ],
  "someSet": [
   "string"
  ]
 },
 "value2": {
  "value": 3.14,
  "list": [
   3.14
  ],
  "someSet": [
   "2"
  ]
 }
}''';

      final instance = ConcreteClass.fromJson(
        jsonDecode(inputJson) as Map<String, dynamic>,
      );

      expect(loudEncode(instance), inputJson);
    });
  });
}
