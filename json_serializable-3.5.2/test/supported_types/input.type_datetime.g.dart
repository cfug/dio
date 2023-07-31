// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.type_datetime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleClass _$SimpleClassFromJson(Map<String, dynamic> json) {
  return SimpleClass(
    json['value'] == null ? null : DateTime.parse(json['value'] as String),
    DateTime.parse(json['nullable'] as String),
  );
}

Map<String, dynamic> _$SimpleClassToJson(SimpleClass instance) =>
    <String, dynamic>{
      'value': instance.value?.toIso8601String(),
      'nullable': instance.nullable.toIso8601String(),
    };
