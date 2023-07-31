// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_helper.dart';
import 'settings.dart';
import 'type_helper.dart';
import 'type_helpers/big_int_helper.dart';
import 'type_helpers/date_time_helper.dart';
import 'type_helpers/duration_helper.dart';
import 'type_helpers/json_helper.dart';
import 'type_helpers/uri_helper.dart';

class JsonSerializableGenerator
    extends GeneratorForAnnotation<JsonSerializable> {
  final Settings _settings;

  JsonSerializable get config => _settings.config;

  JsonSerializableGenerator.fromSettings(this._settings);

  /// Creates an instance of [JsonSerializableGenerator].
  ///
  /// If [typeHelpers] is not provided, the built-in helpers are used:
  /// [BigIntHelper], [DateTimeHelper], [DurationHelper], [JsonHelper], and
  /// [UriHelper].
  factory JsonSerializableGenerator({
    JsonSerializable config,
    List<TypeHelper> typeHelpers,
  }) =>
      JsonSerializableGenerator.fromSettings(Settings(
        config: config,
        typeHelpers: typeHelpers,
      ));

  /// Creates an instance of [JsonSerializableGenerator].
  ///
  /// [typeHelpers] provides a set of [TypeHelper] that will be used along with
  /// the built-in helpers:
  /// [BigIntHelper], [DateTimeHelper], [DurationHelper], [JsonHelper], and
  /// [UriHelper].
  factory JsonSerializableGenerator.withDefaultHelpers(
    Iterable<TypeHelper> typeHelpers, {
    JsonSerializable config,
  }) =>
      JsonSerializableGenerator(
        config: config,
        typeHelpers: List.unmodifiable(
          typeHelpers.followedBy(Settings.defaultHelpers),
        ),
      );

  @override
  Iterable<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@JsonSerializable` can only be used on classes.',
        element: element,
      );
    }

    final classElement = element as ClassElement;
    final helper = GeneratorHelper(_settings, classElement, annotation);
    return helper.generate();
  }
}
