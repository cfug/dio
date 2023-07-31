// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.type_double.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleClass _$SimpleClassFromJson(Map<String, dynamic> json) {
  return SimpleClass(
    (json['value'] as num)?.toDouble(),
    (json['nullable'] as num).toDouble(),
  )..withDefault = (json['withDefault'] as num)?.toDouble() ?? 3.14;
}

Map<String, dynamic> _$SimpleClassToJson(SimpleClass instance) =>
    <String, dynamic>{
      'value': instance.value,
      'nullable': instance.nullable,
      'withDefault': instance.withDefault,
    };
