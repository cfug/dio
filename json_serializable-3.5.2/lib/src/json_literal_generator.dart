// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class JsonLiteralGenerator extends GeneratorForAnnotation<JsonLiteral> {
  const JsonLiteralGenerator();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (p.isAbsolute(annotation.read('path').stringValue)) {
      throw ArgumentError(
          '`annotation.path` must be relative path to the source file.');
    }

    final sourcePathDir = p.dirname(buildStep.inputId.path);
    final fileId = AssetId(buildStep.inputId.package,
        p.join(sourcePathDir, annotation.read('path').stringValue));
    final content = json.decode(await buildStep.readAsString(fileId));

    final asConst = annotation.read('asConst').boolValue;

    final thing = jsonLiteralAsDart(content).toString();
    final marked = asConst ? 'const' : 'final';

    return '$marked _\$${element.name}JsonLiteral = $thing;';
  }
}

/// Returns a [String] representing a valid Dart literal for [value].
String jsonLiteralAsDart(dynamic value) {
  if (value == null) return 'null';

  if (value is String) return escapeDartString(value);

  if (value is double) {
    if (value.isNaN) {
      return 'double.nan';
    }

    if (value.isInfinite) {
      if (value.isNegative) {
        return 'double.negativeInfinity';
      }
      return 'double.infinity';
    }
  }

  if (value is bool || value is num) return value.toString();

  if (value is List) {
    final listItems = value.map(jsonLiteralAsDart).join(', ');
    return '[$listItems]';
  }

  if (value is Set) {
    final listItems = value.map(jsonLiteralAsDart).join(', ');
    return '{$listItems}';
  }

  if (value is Map) return jsonMapAsDart(value);

  throw StateError(
      'Should never get here – with ${value.runtimeType} - `$value`.');
}

String jsonMapAsDart(Map value) {
  final buffer = StringBuffer()..write('{');

  var first = true;
  value.forEach((k, v) {
    if (first) {
      first = false;
    } else {
      buffer.writeln(',');
    }
    buffer
      ..write(escapeDartString(k as String))
      ..write(': ')
      ..write(jsonLiteralAsDart(v));
  });

  buffer.write('}');

  return buffer.toString();
}
