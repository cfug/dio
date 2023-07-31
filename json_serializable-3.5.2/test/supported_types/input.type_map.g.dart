// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.type_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleClass _$SimpleClassFromJson(Map<String, dynamic> json) {
  return SimpleClass(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  )..withDefault = json['withDefault'] as Map<String, dynamic> ?? {'a': 1};
}

Map<String, dynamic> _$SimpleClassToJson(SimpleClass instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
      'withDefault': instance.withDefault,
    };

SimpleClassBigIntToBigInt _$SimpleClassBigIntToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          BigInt.parse(k), e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToBigIntToJson(
        SimpleClassBigIntToBigInt instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };

SimpleClassDateTimeToBigInt _$SimpleClassDateTimeToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          DateTime.parse(k), e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToBigIntToJson(
        SimpleClassDateTimeToBigInt instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toIso8601String(), e?.toString())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toIso8601String(), e.toString())),
    };

SimpleClassDynamicToBigInt _$SimpleClassDynamicToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToBigIntToJson(
        SimpleClassDynamicToBigInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassEnumTypeToBigInt _$SimpleClassEnumTypeToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k),
          e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(
          _$enumDecode(_$EnumTypeEnumMap, k), BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToBigIntToJson(
        SimpleClassEnumTypeToBigInt instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e?.toString())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e.toString())),
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$EnumTypeEnumMap = {
  EnumType.alpha: 'alpha',
  EnumType.beta: 'beta',
  EnumType.gamma: 'gamma',
  EnumType.delta: 'delta',
};

SimpleClassIntToBigInt _$SimpleClassIntToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(int.parse(k), e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToBigIntToJson(
        SimpleClassIntToBigInt instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };

SimpleClassObjectToBigInt _$SimpleClassObjectToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassObjectToBigIntToJson(
        SimpleClassObjectToBigInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassStringToBigInt _$SimpleClassStringToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassStringToBigIntToJson(
        SimpleClassStringToBigInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassUriToBigInt _$SimpleClassUriToBigIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToBigInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(Uri.parse(k), e == null ? null : BigInt.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), BigInt.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToBigIntToJson(
        SimpleClassUriToBigInt instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };

SimpleClassBigIntToBool _$SimpleClassBigIntToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e as bool),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e as bool),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToBoolToJson(
        SimpleClassBigIntToBool instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToBool _$SimpleClassDateTimeToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e as bool),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e as bool),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToBoolToJson(
        SimpleClassDateTimeToBool instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToBool _$SimpleClassDynamicToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as bool),
    ),
    Map<String, bool>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToBoolToJson(
        SimpleClassDynamicToBool instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToBool _$SimpleClassEnumTypeToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e as bool),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e as bool),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToBoolToJson(
        SimpleClassEnumTypeToBool instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToBool _$SimpleClassIntToBoolFromJson(Map<String, dynamic> json) {
  return SimpleClassIntToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e as bool),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e as bool),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToBoolToJson(
        SimpleClassIntToBool instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToBool _$SimpleClassObjectToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as bool),
    ),
    Map<String, bool>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassObjectToBoolToJson(
        SimpleClassObjectToBool instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToBool _$SimpleClassStringToBoolFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as bool),
    ),
    Map<String, bool>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassStringToBoolToJson(
        SimpleClassStringToBool instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToBool _$SimpleClassUriToBoolFromJson(Map<String, dynamic> json) {
  return SimpleClassUriToBool(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e as bool),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e as bool),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToBoolToJson(
        SimpleClassUriToBool instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToDateTime _$SimpleClassBigIntToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          BigInt.parse(k), e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToDateTimeToJson(
        SimpleClassBigIntToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.toIso8601String())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.toIso8601String())),
    };

SimpleClassDateTimeToDateTime _$SimpleClassDateTimeToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          DateTime.parse(k), e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToDateTimeToJson(
        SimpleClassDateTimeToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toIso8601String(), e?.toIso8601String())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toIso8601String(), e.toIso8601String())),
    };

SimpleClassDynamicToDateTime _$SimpleClassDynamicToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToDateTimeToJson(
        SimpleClassDynamicToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toIso8601String())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.toIso8601String())),
    };

SimpleClassEnumTypeToDateTime _$SimpleClassEnumTypeToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k),
          e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(
          _$enumDecode(_$EnumTypeEnumMap, k), DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToDateTimeToJson(
        SimpleClassEnumTypeToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e?.toIso8601String())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e.toIso8601String())),
    };

SimpleClassIntToDateTime _$SimpleClassIntToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          int.parse(k), e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToDateTimeToJson(
        SimpleClassIntToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.toIso8601String())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.toIso8601String())),
    };

SimpleClassObjectToDateTime _$SimpleClassObjectToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassObjectToDateTimeToJson(
        SimpleClassObjectToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toIso8601String())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.toIso8601String())),
    };

SimpleClassStringToDateTime _$SimpleClassStringToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassStringToDateTimeToJson(
        SimpleClassStringToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toIso8601String())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.toIso8601String())),
    };

SimpleClassUriToDateTime _$SimpleClassUriToDateTimeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToDateTime(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          Uri.parse(k), e == null ? null : DateTime.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), DateTime.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToDateTimeToJson(
        SimpleClassUriToDateTime instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.toIso8601String())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.toIso8601String())),
    };

SimpleClassBigIntToDouble _$SimpleClassBigIntToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), (e as num)?.toDouble()),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToDoubleToJson(
        SimpleClassBigIntToDouble instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToDouble _$SimpleClassDateTimeToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), (e as num)?.toDouble()),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToDoubleToJson(
        SimpleClassDateTimeToDouble instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToDouble _$SimpleClassDynamicToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, (e as num)?.toDouble()),
    ),
    Map<String, double>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToDoubleToJson(
        SimpleClassDynamicToDouble instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToDouble _$SimpleClassEnumTypeToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          _$enumDecodeNullable(_$EnumTypeEnumMap, k), (e as num)?.toDouble()),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) =>
          MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToDoubleToJson(
        SimpleClassEnumTypeToDouble instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToDouble _$SimpleClassIntToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), (e as num)?.toDouble()),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToDoubleToJson(
        SimpleClassIntToDouble instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToDouble _$SimpleClassObjectToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, (e as num)?.toDouble()),
    ),
    Map<String, double>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassObjectToDoubleToJson(
        SimpleClassObjectToDouble instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToDouble _$SimpleClassStringToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, (e as num)?.toDouble()),
    ),
    Map<String, double>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassStringToDoubleToJson(
        SimpleClassStringToDouble instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToDouble _$SimpleClassUriToDoubleFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToDouble(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), (e as num)?.toDouble()),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), (e as num).toDouble()),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToDoubleToJson(
        SimpleClassUriToDouble instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToDuration _$SimpleClassBigIntToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          BigInt.parse(k), e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToDurationToJson(
        SimpleClassBigIntToDuration instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.inMicroseconds)),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.inMicroseconds)),
    };

SimpleClassDateTimeToDuration _$SimpleClassDateTimeToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k),
          e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToDurationToJson(
        SimpleClassDateTimeToDuration instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toIso8601String(), e?.inMicroseconds)),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toIso8601String(), e.inMicroseconds)),
    };

SimpleClassDynamicToDuration _$SimpleClassDynamicToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(k, e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToDurationToJson(
        SimpleClassDynamicToDuration instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.inMicroseconds)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.inMicroseconds)),
    };

SimpleClassEnumTypeToDuration _$SimpleClassEnumTypeToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k),
          e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(
          _$enumDecode(_$EnumTypeEnumMap, k), Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToDurationToJson(
        SimpleClassEnumTypeToDuration instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e?.inMicroseconds)),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e.inMicroseconds)),
    };

SimpleClassIntToDuration _$SimpleClassIntToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          int.parse(k), e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToDurationToJson(
        SimpleClassIntToDuration instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.inMicroseconds)),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.inMicroseconds)),
    };

SimpleClassObjectToDuration _$SimpleClassObjectToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(k, e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassObjectToDurationToJson(
        SimpleClassObjectToDuration instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.inMicroseconds)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.inMicroseconds)),
    };

SimpleClassStringToDuration _$SimpleClassStringToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(k, e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassStringToDurationToJson(
        SimpleClassStringToDuration instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.inMicroseconds)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, e.inMicroseconds)),
    };

SimpleClassUriToDuration _$SimpleClassUriToDurationFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToDuration(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          Uri.parse(k), e == null ? null : Duration(microseconds: e as int)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), Duration(microseconds: e as int)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToDurationToJson(
        SimpleClassUriToDuration instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), e?.inMicroseconds)),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), e.inMicroseconds)),
    };

SimpleClassBigIntToDynamic _$SimpleClassBigIntToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToDynamic(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToDynamicToJson(
        SimpleClassBigIntToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToDynamic _$SimpleClassDateTimeToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToDynamic(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToDynamicToJson(
        SimpleClassDateTimeToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToDynamic _$SimpleClassDynamicToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToDynamic(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassDynamicToDynamicToJson(
        SimpleClassDynamicToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToDynamic _$SimpleClassEnumTypeToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToDynamic(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToDynamicToJson(
        SimpleClassEnumTypeToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToDynamic _$SimpleClassIntToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToDynamic(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToDynamicToJson(
        SimpleClassIntToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToDynamic _$SimpleClassObjectToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToDynamic(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassObjectToDynamicToJson(
        SimpleClassObjectToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToDynamic _$SimpleClassStringToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToDynamic(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassStringToDynamicToJson(
        SimpleClassStringToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToDynamic _$SimpleClassUriToDynamicFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToDynamic(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToDynamicToJson(
        SimpleClassUriToDynamic instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToEnumType _$SimpleClassBigIntToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(BigInt.parse(k), _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToEnumTypeToJson(
        SimpleClassBigIntToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
    };

SimpleClassDateTimeToEnumType _$SimpleClassDateTimeToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          DateTime.parse(k), _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToEnumTypeToJson(
        SimpleClassDateTimeToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toIso8601String(), _$EnumTypeEnumMap[e])),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toIso8601String(), _$EnumTypeEnumMap[e])),
    };

SimpleClassDynamicToEnumType _$SimpleClassDynamicToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToEnumTypeToJson(
        SimpleClassDynamicToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
    };

SimpleClassEnumTypeToEnumType _$SimpleClassEnumTypeToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k),
          _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k),
          _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToEnumTypeToJson(
        SimpleClassEnumTypeToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], _$EnumTypeEnumMap[e])),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(_$EnumTypeEnumMap[k], _$EnumTypeEnumMap[e])),
    };

SimpleClassIntToEnumType _$SimpleClassIntToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(int.parse(k), _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToEnumTypeToJson(
        SimpleClassIntToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
    };

SimpleClassObjectToEnumType _$SimpleClassObjectToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassObjectToEnumTypeToJson(
        SimpleClassObjectToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
    };

SimpleClassStringToEnumType _$SimpleClassStringToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassStringToEnumTypeToJson(
        SimpleClassStringToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k, _$EnumTypeEnumMap[e])),
    };

SimpleClassUriToEnumType _$SimpleClassUriToEnumTypeFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToEnumType(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(Uri.parse(k), _$enumDecodeNullable(_$EnumTypeEnumMap, e)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), _$enumDecode(_$EnumTypeEnumMap, e)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToEnumTypeToJson(
        SimpleClassUriToEnumType instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toString(), _$EnumTypeEnumMap[e])),
    };

SimpleClassBigIntToInt _$SimpleClassBigIntToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e as int),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e as int),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToIntToJson(
        SimpleClassBigIntToInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToInt _$SimpleClassDateTimeToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e as int),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e as int),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToIntToJson(
        SimpleClassDateTimeToInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToInt _$SimpleClassDynamicToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as int),
    ),
    Map<String, int>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToIntToJson(
        SimpleClassDynamicToInt instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToInt _$SimpleClassEnumTypeToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e as int),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e as int),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToIntToJson(
        SimpleClassEnumTypeToInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToInt _$SimpleClassIntToIntFromJson(Map<String, dynamic> json) {
  return SimpleClassIntToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e as int),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e as int),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToIntToJson(
        SimpleClassIntToInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToInt _$SimpleClassObjectToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as int),
    ),
    Map<String, int>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassObjectToIntToJson(
        SimpleClassObjectToInt instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToInt _$SimpleClassStringToIntFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as int),
    ),
    Map<String, int>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassStringToIntToJson(
        SimpleClassStringToInt instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToInt _$SimpleClassUriToIntFromJson(Map<String, dynamic> json) {
  return SimpleClassUriToInt(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e as int),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e as int),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToIntToJson(
        SimpleClassUriToInt instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToNum _$SimpleClassBigIntToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e as num),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e as num),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToNumToJson(
        SimpleClassBigIntToNum instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToNum _$SimpleClassDateTimeToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e as num),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e as num),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToNumToJson(
        SimpleClassDateTimeToNum instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToNum _$SimpleClassDynamicToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as num),
    ),
    Map<String, num>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToNumToJson(
        SimpleClassDynamicToNum instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToNum _$SimpleClassEnumTypeToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e as num),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e as num),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToNumToJson(
        SimpleClassEnumTypeToNum instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToNum _$SimpleClassIntToNumFromJson(Map<String, dynamic> json) {
  return SimpleClassIntToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e as num),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e as num),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToNumToJson(
        SimpleClassIntToNum instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToNum _$SimpleClassObjectToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as num),
    ),
    Map<String, num>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassObjectToNumToJson(
        SimpleClassObjectToNum instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToNum _$SimpleClassStringToNumFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as num),
    ),
    Map<String, num>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassStringToNumToJson(
        SimpleClassStringToNum instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToNum _$SimpleClassUriToNumFromJson(Map<String, dynamic> json) {
  return SimpleClassUriToNum(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e as num),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e as num),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToNumToJson(
        SimpleClassUriToNum instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToObject _$SimpleClassBigIntToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToObject(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToObjectToJson(
        SimpleClassBigIntToObject instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToObject _$SimpleClassDateTimeToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToObject(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToObjectToJson(
        SimpleClassDateTimeToObject instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToObject _$SimpleClassDynamicToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToObject(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassDynamicToObjectToJson(
        SimpleClassDynamicToObject instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToObject _$SimpleClassEnumTypeToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToObject(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToObjectToJson(
        SimpleClassEnumTypeToObject instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToObject _$SimpleClassIntToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToObject(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToObjectToJson(
        SimpleClassIntToObject instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToObject _$SimpleClassObjectToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToObject(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassObjectToObjectToJson(
        SimpleClassObjectToObject instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToObject _$SimpleClassStringToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToObject(
    json['value'] as Map<String, dynamic>,
    json['nullable'] as Map<String, dynamic>,
  );
}

Map<String, dynamic> _$SimpleClassStringToObjectToJson(
        SimpleClassStringToObject instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToObject _$SimpleClassUriToObjectFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToObject(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToObjectToJson(
        SimpleClassUriToObject instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToString _$SimpleClassBigIntToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(BigInt.parse(k), e as String),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), e as String),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToStringToJson(
        SimpleClassBigIntToString instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassDateTimeToString _$SimpleClassDateTimeToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(DateTime.parse(k), e as String),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), e as String),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToStringToJson(
        SimpleClassDateTimeToString instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toIso8601String(), e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toIso8601String(), e)),
    };

SimpleClassDynamicToString _$SimpleClassDynamicToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    Map<String, String>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToStringToJson(
        SimpleClassDynamicToString instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassEnumTypeToString _$SimpleClassEnumTypeToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k), e as String),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), e as String),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToStringToJson(
        SimpleClassEnumTypeToString instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e)),
    };

SimpleClassIntToString _$SimpleClassIntToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassIntToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(int.parse(k), e as String),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), e as String),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToStringToJson(
        SimpleClassIntToString instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassObjectToString _$SimpleClassObjectToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    Map<String, String>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassObjectToStringToJson(
        SimpleClassObjectToString instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassStringToString _$SimpleClassStringToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    Map<String, String>.from(json['nullable'] as Map),
  );
}

Map<String, dynamic> _$SimpleClassStringToStringToJson(
        SimpleClassStringToString instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
    };

SimpleClassUriToString _$SimpleClassUriToStringFromJson(
    Map<String, dynamic> json) {
  return SimpleClassUriToString(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(Uri.parse(k), e as String),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), e as String),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToStringToJson(
        SimpleClassUriToString instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k.toString(), e)),
      'nullable': instance.nullable.map((k, e) => MapEntry(k.toString(), e)),
    };

SimpleClassBigIntToUri _$SimpleClassBigIntToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassBigIntToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(BigInt.parse(k), e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(BigInt.parse(k), Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassBigIntToUriToJson(
        SimpleClassBigIntToUri instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };

SimpleClassDateTimeToUri _$SimpleClassDateTimeToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDateTimeToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          DateTime.parse(k), e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(DateTime.parse(k), Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDateTimeToUriToJson(
        SimpleClassDateTimeToUri instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(k.toIso8601String(), e?.toString())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(k.toIso8601String(), e.toString())),
    };

SimpleClassDynamicToUri _$SimpleClassDynamicToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassDynamicToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassDynamicToUriToJson(
        SimpleClassDynamicToUri instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassEnumTypeToUri _$SimpleClassEnumTypeToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassEnumTypeToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(_$enumDecodeNullable(_$EnumTypeEnumMap, k),
          e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) =>
          MapEntry(_$enumDecode(_$EnumTypeEnumMap, k), Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassEnumTypeToUriToJson(
        SimpleClassEnumTypeToUri instance) =>
    <String, dynamic>{
      'value': instance.value
          ?.map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e?.toString())),
      'nullable': instance.nullable
          .map((k, e) => MapEntry(_$EnumTypeEnumMap[k], e.toString())),
    };

SimpleClassIntToUri _$SimpleClassIntToUriFromJson(Map<String, dynamic> json) {
  return SimpleClassIntToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(int.parse(k), e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(int.parse(k), Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassIntToUriToJson(
        SimpleClassIntToUri instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };

SimpleClassObjectToUri _$SimpleClassObjectToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassObjectToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassObjectToUriToJson(
        SimpleClassObjectToUri instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassStringToUri _$SimpleClassStringToUriFromJson(
    Map<String, dynamic> json) {
  return SimpleClassStringToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassStringToUriToJson(
        SimpleClassStringToUri instance) =>
    <String, dynamic>{
      'value': instance.value?.map((k, e) => MapEntry(k, e?.toString())),
      'nullable': instance.nullable.map((k, e) => MapEntry(k, e.toString())),
    };

SimpleClassUriToUri _$SimpleClassUriToUriFromJson(Map<String, dynamic> json) {
  return SimpleClassUriToUri(
    (json['value'] as Map<String, dynamic>)?.map(
      (k, e) =>
          MapEntry(Uri.parse(k), e == null ? null : Uri.parse(e as String)),
    ),
    (json['nullable'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(Uri.parse(k), Uri.parse(e as String)),
    ),
  );
}

Map<String, dynamic> _$SimpleClassUriToUriToJson(
        SimpleClassUriToUri instance) =>
    <String, dynamic>{
      'value':
          instance.value?.map((k, e) => MapEntry(k.toString(), e?.toString())),
      'nullable':
          instance.nullable.map((k, e) => MapEntry(k.toString(), e.toString())),
    };
