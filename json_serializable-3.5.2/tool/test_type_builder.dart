// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

import 'shared.dart';
import 'test_type_data.dart';

final _formatter = DartFormatter();

const _trivialTypesToTest = {
  'BigInt': TestTypeData(
    jsonExpression: "'12345'",
    altJsonExpression: "'67890'",
  ),
  'bool': TestTypeData(
    defaultExpression: 'true',
    altJsonExpression: 'false',
  ),
  'DateTime': TestTypeData(
    jsonExpression: "'2020-01-01T00:00:00.000'",
    altJsonExpression: "'2018-01-01T00:00:00.000'",
  ),
  'double': TestTypeData(
    defaultExpression: '3.14',
    altJsonExpression: '6.28',
  ),
  'Duration': TestTypeData(
    jsonExpression: '1234',
    altJsonExpression: '2345',
  ),
  'int': TestTypeData(
    defaultExpression: '42',
    altJsonExpression: '43',
  ),
  customEnumType: TestTypeData(
    defaultExpression: '$customEnumType.alpha',
    jsonExpression: "'alpha'",
    altJsonExpression: "'beta'",
  ),
  'num': TestTypeData(
    defaultExpression: '88.6',
    altJsonExpression: '29',
  ),
  'Object': TestTypeData(
    altJsonExpression: "'Object'",
  ),
  'String': TestTypeData(
    defaultExpression: "'a string'",
    altJsonExpression: "'another string'",
  ),
  'Uri': TestTypeData(
    jsonExpression: "'https://example.com'",
    altJsonExpression: "'https://dart.dev'",
  ),
};

final _typesToTest = {
  ..._trivialTypesToTest,
  //
  // Collection types
  //
  'Map': TestTypeData(
    defaultExpression: "{'a': 1}",
    altJsonExpression: "{'b': 2}",
    genericArgs: _iterableGenericArgs
        .expand((v) => _mapKeyTypes.map((k) => '$k,$v'))
        .toSet(),
  ),
  'List': TestTypeData(
    defaultExpression: '[$_defaultCollectionExpressions]',
    altJsonExpression: '[$_altCollectionExpressions]',
    genericArgs: _iterableGenericArgs,
  ),
  'Set': TestTypeData(
    defaultExpression: '{$_defaultCollectionExpressions}',
    jsonExpression: '[$_defaultCollectionExpressions]',
    altJsonExpression: '[$_altCollectionExpressions]',
    genericArgs: _iterableGenericArgs,
  ),
  'Iterable': TestTypeData(
    defaultExpression: '[$_defaultCollectionExpressions]',
    altJsonExpression: '[$_altCollectionExpressions]',
    genericArgs: _iterableGenericArgs,
  ),
};

const _mapKeyTypes = {
  'BigInt',
  'DateTime',
  'dynamic',
  'EnumType',
  'int',
  'Object',
  'String',
  'Uri',
};

final _iterableGenericArgs = ([
  ..._trivialTypesToTest.keys,
  'dynamic',
]..sort(compareAsciiLowerCase))
    .toSet();

const _defaultCollectionExpressions = '42, true, false, null';
const _altCollectionExpressions = '43, false';

Builder typeBuilder([_]) => validate('_type_builder', const _TypeBuilder());

class _TypeBuilder implements Builder {
  const _TypeBuilder();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    final sourceContent = await buildStep.readAsString(inputId);

    for (var entry in _typesToTest.entries) {
      final type = entry.key;
      final newId = buildStep.inputId.changeExtension(toTypeExtension(type));

      await buildStep.writeAsString(
        newId,
        _formatter.format(entry.value.libContent(sourceContent, type)),
      );
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': _typesToTest.keys.map(toTypeExtension).toSet().toList()..sort()
      };
}

Builder typeTestBuilder([_]) =>
    validate('_type_test_builder', const _TypeTestBuilder());

class _TypeTestBuilder implements Builder {
  const _TypeTestBuilder();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    final sourceContent = await buildStep.readAsString(inputId);

    for (var entry in _typesToTest.entries) {
      final type = entry.key;
      final newId =
          buildStep.inputId.changeExtension(_toTypeTestExtension(type));

      await buildStep.writeAsString(
        newId,
        entry.value.testContent(sourceContent, type),
      );
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': _typesToTest.keys.map(_toTypeTestExtension).toSet().toList()
          ..sort()
      };
}

String _toTypeTestExtension(String e) => '.${typeToPathPart(e)}_test.dart';
