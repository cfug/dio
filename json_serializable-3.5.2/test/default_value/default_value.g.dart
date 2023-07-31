// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefaultValue _$DefaultValueFromJson(Map<String, dynamic> json) {
  return DefaultValue()
    ..fieldBool = json['fieldBool'] as bool ?? true
    ..fieldString = json['fieldString'] as String ?? 'string'
    ..fieldInt = json['fieldInt'] as int ?? 42
    ..fieldDouble = (json['fieldDouble'] as num)?.toDouble() ?? 3.14
    ..fieldListEmpty = json['fieldListEmpty'] as List ?? []
    ..fieldSetEmpty = (json['fieldSetEmpty'] as List)?.toSet() ?? {}
    ..fieldMapEmpty = json['fieldMapEmpty'] as Map<String, dynamic> ?? {}
    ..fieldListSimple =
        (json['fieldListSimple'] as List)?.map((e) => e as int)?.toList() ??
            [1, 2, 3]
    ..fieldSetSimple =
        (json['fieldSetSimple'] as List)?.map((e) => e as String)?.toSet() ??
            {'entry1', 'entry2'}
    ..fieldMapSimple = (json['fieldMapSimple'] as Map<String, dynamic>)?.map(
          (k, e) => MapEntry(k, e as int),
        ) ??
        {'answer': 42}
    ..fieldMapListString =
        (json['fieldMapListString'] as Map<String, dynamic>)?.map(
              (k, e) =>
                  MapEntry(k, (e as List)?.map((e) => e as String)?.toList()),
            ) ??
            {
              'root': ['child']
            }
    ..fieldEnum =
        _$enumDecodeNullable(_$GreekEnumMap, json['fieldEnum']) ?? Greek.beta;
}

Map<String, dynamic> _$DefaultValueToJson(DefaultValue instance) {
  final val = <String, dynamic>{
    'fieldBool': instance.fieldBool,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fieldString', instance.fieldString);
  val['fieldInt'] = instance.fieldInt;
  val['fieldDouble'] = instance.fieldDouble;
  val['fieldListEmpty'] = instance.fieldListEmpty;
  val['fieldSetEmpty'] = instance.fieldSetEmpty?.toList();
  val['fieldMapEmpty'] = instance.fieldMapEmpty;
  val['fieldListSimple'] = instance.fieldListSimple;
  val['fieldSetSimple'] = instance.fieldSetSimple?.toList();
  val['fieldMapSimple'] = instance.fieldMapSimple;
  val['fieldMapListString'] = instance.fieldMapListString;
  val['fieldEnum'] = _$GreekEnumMap[instance.fieldEnum];
  return val;
}

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

const _$GreekEnumMap = {
  Greek.alpha: 'alpha',
  Greek.beta: 'beta',
  Greek.gamma: 'gamma',
  Greek.delta: 'delta',
};
