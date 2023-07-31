// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '_json_serializable_test_input.dart';

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  '`defaultValue` is `Symbol`, it must be a literal.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithSymbol {
  @JsonKey(defaultValue: #symbol)
  Object field;

  DefaultWithSymbol();
}

int _function() => 42;

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  '`defaultValue` is `Function`, it must be a literal.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithFunction {
  @JsonKey(defaultValue: _function)
  Object field;

  DefaultWithFunction();
}

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  '`defaultValue` is `Type`, it must be a literal.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithType {
  @JsonKey(defaultValue: Object)
  Object field;

  DefaultWithType();
}

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  '`defaultValue` is `Duration`, it must be a literal.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithConstObject {
  @JsonKey(defaultValue: Duration())
  Object field;

  DefaultWithConstObject();
}

enum Enum { value }

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  '`defaultValue` is `List > Enum`, it must be a literal.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithNestedEnum {
  @JsonKey(defaultValue: [Enum.value])
  Object field;

  DefaultWithNestedEnum();
}

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  'Cannot use `defaultValue` on a field with `nullable` false.',
  element: 'field',
)
@JsonSerializable()
class DefaultWithNonNullableField {
  @JsonKey(defaultValue: 42, nullable: false)
  Object field;

  DefaultWithNonNullableField();
}

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
  'Cannot use `defaultValue` on a field with `nullable` false.',
  element: 'field',
)
@JsonSerializable(nullable: false)
class DefaultWithNonNullableClass {
  @JsonKey(defaultValue: 42)
  Object field;

  DefaultWithNonNullableClass();
}

@ShouldGenerate(
  r'''
DefaultWithToJsonClass _$DefaultWithToJsonClassFromJson(
    Map<String, dynamic> json) {
  return DefaultWithToJsonClass()
    ..fieldDefaultValueToJson = DefaultWithToJsonClass._fromJson(
            json['fieldDefaultValueToJson'] as String) ??
        7;
}
''',
  expectedLogItems: [
    '''
The field `fieldDefaultValueToJson` has both `defaultValue` and `fromJson` defined which likely won't work for your scenario.
Instead of using `defaultValue`, set `nullable: false` and handle `null` in the `fromJson` function.'''
  ],
)
@JsonSerializable(createToJson: false)
class DefaultWithToJsonClass {
  @JsonKey(defaultValue: 7, fromJson: _fromJson)
  int fieldDefaultValueToJson;

  DefaultWithToJsonClass();

  static int _fromJson(String input) => 41;
}

@ShouldGenerate(
  r'''
DefaultWithDisallowNullRequiredClass
    _$DefaultWithDisallowNullRequiredClassFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      requiredKeys: const ['theField'], disallowNullValues: const ['theField']);
  return DefaultWithDisallowNullRequiredClass()
    ..theField = json['theField'] as int ?? 7;
}
''',
  expectedLogItems: [
    'The `defaultValue` on field `theField` will have no effect because both '
        '`disallowNullValue` and `required` are set to `true`.',
  ],
)
@JsonSerializable(createToJson: false)
class DefaultWithDisallowNullRequiredClass {
  @JsonKey(defaultValue: 7, disallowNullValue: true, required: true)
  int theField;

  DefaultWithDisallowNullRequiredClass();
}

@ShouldGenerate(r'''
DefaultDoubleConstants _$DefaultDoubleConstantsFromJson(
    Map<String, dynamic> json) {
  return DefaultDoubleConstants()
    ..defaultNan = (json['defaultNan'] as num)?.toDouble() ?? double.nan
    ..defaultNegativeInfinity =
        (json['defaultNegativeInfinity'] as num)?.toDouble() ??
            double.negativeInfinity
    ..defaultInfinity =
        (json['defaultInfinity'] as num)?.toDouble() ?? double.infinity
    ..defaultMinPositive =
        (json['defaultMinPositive'] as num)?.toDouble() ?? 5e-324
    ..defaultMaxFinite = (json['defaultMaxFinite'] as num)?.toDouble() ??
        1.7976931348623157e+308;
}
''')
@JsonSerializable(createToJson: false)
class DefaultDoubleConstants {
  @JsonKey(defaultValue: double.nan)
  double defaultNan;
  @JsonKey(defaultValue: double.negativeInfinity)
  double defaultNegativeInfinity;
  @JsonKey(defaultValue: double.infinity)
  double defaultInfinity;

  // Since these values can be represented as number literals, there is no
  // special handling. Including them here for completeness, though.
  @JsonKey(defaultValue: double.minPositive)
  double defaultMinPositive;
  @JsonKey(defaultValue: double.maxFinite)
  double defaultMaxFinite;

  DefaultDoubleConstants();
}
