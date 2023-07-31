// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:json_serializable/src/constants.dart';
import 'package:json_serializable/src/type_helper.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

import 'shared_config.dart';

LibraryReader _libraryReader;

Future<void> main() async {
  initializeBuildLogTracking();
  _libraryReader = await initializeLibraryReaderForDirectory(
    p.join('test', 'test_sources'),
    'test_sources.dart',
  );

  group('without wrappers', () {
    _registerTests(JsonSerializable.defaults);
  });

  group('configuration', () {
    Future<void> runWithConfigAndLogger(
        JsonSerializable config, String className) async {
      await generateForElement(
          JsonSerializableGenerator(
              config: config, typeHelpers: const [_ConfigLogger()]),
          _libraryReader,
          className);
    }

    setUp(_ConfigLogger.configurations.clear);

    group('defaults', () {
      for (var className in [
        'ConfigurationImplicitDefaults',
        'ConfigurationExplicitDefaults',
      ]) {
        for (var nullConfig in [true, false]) {
          final testDescription =
              '$className with ${nullConfig ? 'null' : 'default'} config';

          test(testDescription, () async {
            await runWithConfigAndLogger(
                nullConfig ? null : const JsonSerializable(), className);

            expect(_ConfigLogger.configurations, hasLength(2));
            expect(_ConfigLogger.configurations.first,
                same(_ConfigLogger.configurations.last));
            expect(_ConfigLogger.configurations.first.toJson(),
                generatorConfigDefaultJson);
          });
        }
      }
    });

    test(
        'values in config override unconfigured (default) values in annotation',
        () async {
      await runWithConfigAndLogger(
          JsonSerializable.fromJson(generatorConfigNonDefaultJson),
          'ConfigurationImplicitDefaults');

      expect(_ConfigLogger.configurations, isEmpty,
          reason: 'all generation is disabled');

      // Create a configuration with just `create_to_json` set to true so we
      // can validate the configuration that is run with
      final configMap =
          Map<String, dynamic>.from(generatorConfigNonDefaultJson);
      configMap['create_to_json'] = true;

      await runWithConfigAndLogger(JsonSerializable.fromJson(configMap),
          'ConfigurationImplicitDefaults');
    });

    test(
      'explicit values in annotation override corresponding settings in config',
      () async {
        await runWithConfigAndLogger(
            JsonSerializable.fromJson(generatorConfigNonDefaultJson),
            'ConfigurationExplicitDefaults');

        expect(_ConfigLogger.configurations, hasLength(2));
        expect(_ConfigLogger.configurations.first,
            same(_ConfigLogger.configurations.last));

        // The effective configuration should be non-Default configuration, but
        // with all fields set from JsonSerializable as the defaults

        final expected =
            Map<String, dynamic>.from(generatorConfigNonDefaultJson);
        for (var jsonSerialKey in jsonSerializableFields) {
          expected[jsonSerialKey] = generatorConfigDefaultJson[jsonSerialKey];
        }

        expect(_ConfigLogger.configurations.first.toJson(), expected);
      },
    );
  });
}

Future<String> _runForElementNamed(JsonSerializable config, String name) async {
  final generator = JsonSerializableGenerator(config: config);
  return generateForElement(generator, _libraryReader, name);
}

void _registerTests(JsonSerializable generator) {
  Future<String> runForElementNamed(String name) =>
      _runForElementNamed(generator, name);

  group('explicit toJson', () {
    test('nullable', () async {
      final output = await _runForElementNamed(
          const JsonSerializable(), 'TrivialNestedNullable');

      const expected = r'''
Map<String, dynamic> _$TrivialNestedNullableToJson(
        TrivialNestedNullable instance) =>
    <String, dynamic>{
      'child': instance.child?.toJson(),
      'otherField': instance.otherField,
    };
''';

      expect(output, expected);
    });
    test('non-nullable', () async {
      final output = await _runForElementNamed(
          const JsonSerializable(), 'TrivialNestedNonNullable');

      const expected = r'''
Map<String, dynamic> _$TrivialNestedNonNullableToJson(
        TrivialNestedNonNullable instance) =>
    <String, dynamic>{
      'child': instance.child.toJson(),
      'otherField': instance.otherField,
    };
''';

      expect(output, expected);
    });
  });

  group('valid inputs', () {
    test('class with fromJson() constructor with optional parameters',
        () async {
      final output = await runForElementNamed('FromJsonOptionalParameters');

      expect(output, contains('ChildWithFromJson.fromJson'));
    });

    test('class with child json-able object', () async {
      final output = await runForElementNamed('ParentObject');

      expect(
          output,
          contains("ChildObject.fromJson(json['child'] "
              'as Map<String, dynamic>)'));
    });

    test('class with child json-able object - anyMap', () async {
      final output = await _runForElementNamed(
          const JsonSerializable(anyMap: true), 'ParentObject');

      expect(output, contains("ChildObject.fromJson(json['child'] as Map)"));
    });

    test('class with child list of json-able objects', () async {
      final output = await runForElementNamed('ParentObjectWithChildren');

      expect(output, contains('.toList()'));
      expect(output, contains('ChildObject.fromJson'));
    });

    test('class with child list of dynamic objects is left alone', () async {
      final output =
          await runForElementNamed('ParentObjectWithDynamicChildren');

      expect(output, contains('children = json[\'children\'] as List;'));
    });
  });

  group('includeIfNull', () {
    test('some', () async {
      final output = await runForElementNamed('IncludeIfNullAll');
      expect(output, isNot(contains(generatedLocalVarName)));
      expect(output, isNot(contains(toJsonMapHelperName)));
    });
  });
}

class _ConfigLogger implements TypeHelper<TypeHelperContextWithConfig> {
  static final configurations = <JsonSerializable>[];

  const _ConfigLogger();

  @override
  Object deserialize(DartType targetType, String expression,
      TypeHelperContextWithConfig context) {
    configurations.add(context.config);
    return null;
  }

  @override
  Object serialize(DartType targetType, String expression,
      TypeHelperContextWithConfig context) {
    configurations.add(context.config);
    return null;
  }
}
