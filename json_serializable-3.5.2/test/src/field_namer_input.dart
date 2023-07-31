part of '_json_serializable_test_input.dart';

@ShouldGenerate(r'''
Map<String, dynamic> _$FieldNamerNoneToJson(FieldNamerNone instance) =>
    <String, dynamic>{
      'theField': instance.theField,
      'NAME_OVERRIDE': instance.nameOverride,
    };
''')
@JsonSerializable(fieldRename: FieldRename.none, createFactory: false)
class FieldNamerNone {
  String theField;

  @JsonKey(name: 'NAME_OVERRIDE')
  String nameOverride;
}

@ShouldGenerate(r'''
Map<String, dynamic> _$FieldNamerKebabToJson(FieldNamerKebab instance) =>
    <String, dynamic>{
      'the-field': instance.theField,
      'NAME_OVERRIDE': instance.nameOverride,
    };
''')
@JsonSerializable(fieldRename: FieldRename.kebab, createFactory: false)
class FieldNamerKebab {
  String theField;

  @JsonKey(name: 'NAME_OVERRIDE')
  String nameOverride;
}

@ShouldGenerate(r'''
Map<String, dynamic> _$FieldNamerPascalToJson(FieldNamerPascal instance) =>
    <String, dynamic>{
      'TheField': instance.theField,
      'NAME_OVERRIDE': instance.nameOverride,
    };
''')
@JsonSerializable(fieldRename: FieldRename.pascal, createFactory: false)
class FieldNamerPascal {
  String theField;

  @JsonKey(name: 'NAME_OVERRIDE')
  String nameOverride;
}

@ShouldGenerate(r'''
Map<String, dynamic> _$FieldNamerSnakeToJson(FieldNamerSnake instance) =>
    <String, dynamic>{
      'the_field': instance.theField,
      'NAME_OVERRIDE': instance.nameOverride,
    };
''')
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class FieldNamerSnake {
  String theField;

  @JsonKey(name: 'NAME_OVERRIDE')
  String nameOverride;
}
