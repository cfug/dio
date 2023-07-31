// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart' show alwaysThrows, required;
import 'package:source_gen/source_gen.dart';

import 'helper_core.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);

DartObject _jsonKeyAnnotation(FieldElement element) =>
    _jsonKeyChecker.firstAnnotationOf(element) ??
    (element.getter == null
        ? null
        : _jsonKeyChecker.firstAnnotationOf(element.getter));

ConstantReader jsonKeyAnnotation(FieldElement element) =>
    ConstantReader(_jsonKeyAnnotation(element));

/// Returns `true` if [element] is annotated with [JsonKey].
bool hasJsonKeyAnnotation(FieldElement element) =>
    _jsonKeyAnnotation(element) != null;

final _upperCase = RegExp('[A-Z]');

String kebabCase(String input) => _fixCase(input, '-');

String snakeCase(String input) => _fixCase(input, '_');

String pascalCase(String input) {
  if (input.isEmpty) {
    return '';
  }

  return input[0].toUpperCase() + input.substring(1);
}

String _fixCase(String input, String separator) =>
    input.replaceAllMapped(_upperCase, (match) {
      var lower = match.group(0).toLowerCase();

      if (match.start > 0) {
        lower = '$separator$lower';
      }

      return lower;
    });

@alwaysThrows
void throwUnsupported(FieldElement element, String message) =>
    throw InvalidGenerationSourceError(
        'Error with `@JsonKey` on `${element.name}`. $message',
        element: element);

FieldRename _fromDartObject(ConstantReader reader) => reader.isNull
    ? null
    : enumValueForDartObject(
        reader.objectValue,
        FieldRename.values,
        (f) => f.toString().split('.')[1],
      );

T enumValueForDartObject<T>(
  DartObject source,
  List<T> items,
  String Function(T) name,
) =>
    items.singleWhere((v) => source.getField(name(v)) != null);

/// Return an instance of [JsonSerializable] corresponding to a the provided
/// [reader].
JsonSerializable _valueForAnnotation(ConstantReader reader) => JsonSerializable(
      anyMap: reader.read('anyMap').literalValue as bool,
      checked: reader.read('checked').literalValue as bool,
      createFactory: reader.read('createFactory').literalValue as bool,
      createToJson: reader.read('createToJson').literalValue as bool,
      disallowUnrecognizedKeys:
          reader.read('disallowUnrecognizedKeys').literalValue as bool,
      explicitToJson: reader.read('explicitToJson').literalValue as bool,
      fieldRename: _fromDartObject(reader.read('fieldRename')),
      genericArgumentFactories:
          reader.read('genericArgumentFactories').literalValue as bool,
      ignoreUnannotated: reader.read('ignoreUnannotated').literalValue as bool,
      includeIfNull: reader.read('includeIfNull').literalValue as bool,
      nullable: reader.read('nullable').literalValue as bool,
    );

/// Returns a [JsonSerializable] with values from the [JsonSerializable]
/// instance represented by [reader].
///
/// For fields that are not defined in [JsonSerializable] or `null` in [reader],
/// use the values in [config].
///
/// Note: if [JsonSerializable.genericArgumentFactories] is `false` for [reader]
/// and `true` for [config], the corresponding field in the return value will
/// only be `true` if [classElement] has type parameters.
JsonSerializable mergeConfig(
  JsonSerializable config,
  ConstantReader reader, {
  @required ClassElement classElement,
}) {
  final annotation = _valueForAnnotation(reader);

  return JsonSerializable(
    anyMap: annotation.anyMap ?? config.anyMap,
    checked: annotation.checked ?? config.checked,
    createFactory: annotation.createFactory ?? config.createFactory,
    createToJson: annotation.createToJson ?? config.createToJson,
    disallowUnrecognizedKeys:
        annotation.disallowUnrecognizedKeys ?? config.disallowUnrecognizedKeys,
    explicitToJson: annotation.explicitToJson ?? config.explicitToJson,
    fieldRename: annotation.fieldRename ?? config.fieldRename,
    genericArgumentFactories: annotation.genericArgumentFactories ??
        (classElement.typeParameters.isNotEmpty &&
            config.genericArgumentFactories),
    ignoreUnannotated: annotation.ignoreUnannotated ?? config.ignoreUnannotated,
    includeIfNull: annotation.includeIfNull ?? config.includeIfNull,
    nullable: annotation.nullable ?? config.nullable,
  );
}

bool isEnum(DartType targetType) =>
    targetType is InterfaceType && targetType.element.isEnum;

final _enumMapExpando = Expando<Map<FieldElement, dynamic>>();

/// If [targetType] is an enum, returns a [Map] of the [FieldElement] instances
/// associated with the enum values mapped to the [String] values that represent
/// the serialized output.
///
/// By default, the [String] value is just the name of the enum value.
/// If the enum value is annotated with [JsonKey], then the `name` property is
/// used if it's set and not `null`.
///
/// If [targetType] is not an enum, `null` is returned.
Map<FieldElement, dynamic> enumFieldsMap(DartType targetType) {
  MapEntry<FieldElement, dynamic> _generateEntry(FieldElement fe) {
    final annotation =
        const TypeChecker.fromRuntime(JsonValue).firstAnnotationOfExact(fe);

    dynamic fieldValue;
    if (annotation == null) {
      fieldValue = fe.name;
    } else {
      final reader = ConstantReader(annotation);

      final valueReader = reader.read('value');

      if (valueReader.isString || valueReader.isNull || valueReader.isInt) {
        fieldValue = valueReader.literalValue;
      } else {
        final targetTypeCode = typeToCode(targetType);
        throw InvalidGenerationSourceError(
            'The `JsonValue` annotation on `$targetTypeCode.${fe.name}` does '
            'not have a value of type String, int, or null.',
            element: fe);
      }
    }

    final entry = MapEntry(fe, fieldValue);

    return entry;
  }

  if (targetType is InterfaceType && targetType.element.isEnum) {
    return _enumMapExpando[targetType] ??=
        Map<FieldElement, dynamic>.fromEntries(targetType.element.fields
            .where((p) => !p.isSynthetic)
            .map(_generateEntry));
  }
  return null;
}

/// If [targetType] is an enum, returns the [FieldElement] instances associated
/// with its values.
///
/// Otherwise, `null`.
Iterable<FieldElement> iterateEnumFields(DartType targetType) =>
    enumFieldsMap(targetType)?.keys;

/// Returns a quoted String literal for [value] that can be used in generated
/// Dart code.
String escapeDartString(String value) {
  var hasSingleQuote = false;
  var hasDoubleQuote = false;
  var hasDollar = false;
  var canBeRaw = true;

  value = value.replaceAllMapped(_escapeRegExp, (match) {
    final value = match[0];
    if (value == "'") {
      hasSingleQuote = true;
      return value;
    } else if (value == '"') {
      hasDoubleQuote = true;
      return value;
    } else if (value == r'$') {
      hasDollar = true;
      return value;
    }

    canBeRaw = false;
    return _escapeMap[value] ?? _getHexLiteral(value);
  });

  if (!hasDollar) {
    if (hasSingleQuote) {
      if (!hasDoubleQuote) {
        return '"$value"';
      }
      // something
    } else {
      // trivial!
      return "'$value'";
    }
  }

  if (hasDollar && canBeRaw) {
    if (hasSingleQuote) {
      if (!hasDoubleQuote) {
        // quote it with single quotes!
        return 'r"$value"';
      }
    } else {
      // quote it with single quotes!
      return "r'$value'";
    }
  }

  // The only safe way to wrap the content is to escape all of the
  // problematic characters - `$`, `'`, and `"`
  final string = value.replaceAll(_dollarQuoteRegexp, r'\');
  return "'$string'";
}

final _dollarQuoteRegexp = RegExp(r"""(?=[$'"])""");

/// A [Map] between whitespace characters & `\` and their escape sequences.
const _escapeMap = {
  '\b': r'\b', // 08 - backspace
  '\t': r'\t', // 09 - tab
  '\n': r'\n', // 0A - new line
  '\v': r'\v', // 0B - vertical tab
  '\f': r'\f', // 0C - form feed
  '\r': r'\r', // 0D - carriage return
  '\x7F': r'\x7F', // delete
  r'\': r'\\' // backslash
};

final _escapeMapRegexp = _escapeMap.keys.map(_getHexLiteral).join();

/// A [RegExp] that matches whitespace characters that should be escaped and
/// single-quote, double-quote, and `$`
final _escapeRegExp = RegExp('[\$\'"\\x00-\\x07\\x0E-\\x1F$_escapeMapRegexp]');

/// Given single-character string, return the hex-escaped equivalent.
String _getHexLiteral(String input) {
  final rune = input.runes.single;
  final value = rune.toRadixString(16).toUpperCase().padLeft(2, '0');
  return '\\x$value';
}

extension DartTypeExtension on DartType {
  bool isAssignableTo(DartType other) =>
      // If the library is `null`, treat it like dynamic => `true`
      element.library == null ||
      element.library.typeSystem.isAssignableTo(this, other);
}
