// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '_json_serializable_test_input.dart';

@ShouldThrow(
  '''
Could not generate `fromJson` code for `result` because of type `TResult` (type parameter).
To support type parameters (generic types) you can:
$converterOrKeyInstructions
* Set `JsonSerializable.genericArgumentFactories` to `true`
  https://pub.dev/documentation/json_annotation/latest/json_annotation/JsonSerializable/genericArgumentFactories.html''',
  element: 'result',
)
@JsonSerializable()
class Issue713<TResult> {
  List<TResult> result;
}

@ShouldGenerate(r'''
GenericClass<T, S> _$GenericClassFromJson<T extends num, S>(
    Map<String, dynamic> json) {
  return GenericClass<T, S>()
    ..fieldObject = _dataFromJson(json['fieldObject'])
    ..fieldDynamic = _dataFromJson(json['fieldDynamic'])
    ..fieldInt = _dataFromJson(json['fieldInt'])
    ..fieldT = _dataFromJson(json['fieldT'])
    ..fieldS = _dataFromJson(json['fieldS']);
}

Map<String, dynamic> _$GenericClassToJson<T extends num, S>(
        GenericClass<T, S> instance) =>
    <String, dynamic>{
      'fieldObject': _dataToJson(instance.fieldObject),
      'fieldDynamic': _dataToJson(instance.fieldDynamic),
      'fieldInt': _dataToJson(instance.fieldInt),
      'fieldT': _dataToJson(instance.fieldT),
      'fieldS': _dataToJson(instance.fieldS),
    };
''')
@JsonSerializable()
class GenericClass<T extends num, S> {
  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  Object fieldObject;

  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  dynamic fieldDynamic;

  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  int fieldInt;

  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  T fieldT;

  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  S fieldS;

  GenericClass();
}

T _dataFromJson<T extends num>(Object input) => null;

Object _dataToJson<T extends num>(T input) => null;

@ShouldGenerate(
  r'''
GenericArgumentFactoriesFlagWithoutGenericType
    _$GenericArgumentFactoriesFlagWithoutGenericTypeFromJson(
        Map<String, dynamic> json) {
  return GenericArgumentFactoriesFlagWithoutGenericType();
}

Map<String, dynamic> _$GenericArgumentFactoriesFlagWithoutGenericTypeToJson(
        GenericArgumentFactoriesFlagWithoutGenericType instance) =>
    <String, dynamic>{};
''',
  expectedLogItems: [
    'The class `GenericArgumentFactoriesFlagWithoutGenericType` is annotated '
        'with `JsonSerializable` field `genericArgumentFactories: true`. '
        '`genericArgumentFactories: true` only affects classes with type '
        'parameters. For classes without type parameters, the option is '
        'ignored.',
  ],
)
@JsonSerializable(genericArgumentFactories: true)
class GenericArgumentFactoriesFlagWithoutGenericType {}
