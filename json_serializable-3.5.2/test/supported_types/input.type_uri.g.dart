// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.type_uri.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimpleClass _$SimpleClassFromJson(Map<String, dynamic> json) {
  return SimpleClass(
    json['value'] == null ? null : Uri.parse(json['value'] as String),
    Uri.parse(json['nullable'] as String),
  );
}

Map<String, dynamic> _$SimpleClassToJson(SimpleClass instance) =>
    <String, dynamic>{
      'value': instance.value?.toString(),
      'nullable': instance.nullable.toString(),
    };
