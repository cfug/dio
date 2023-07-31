import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class ConfigurationImplicitDefaults {
  int field;
}

@JsonSerializable(
  anyMap: false,
  checked: false,
  createFactory: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: false,
  fieldRename: FieldRename.none,
  ignoreUnannotated: false,
  includeIfNull: true,
  nullable: true,
  genericArgumentFactories: false,
)
class ConfigurationExplicitDefaults {
  int field;
}

@JsonSerializable(createFactory: false)
class IncludeIfNullAll {
  @JsonKey(includeIfNull: true)
  int number;
  String str;
}

@JsonSerializable(createToJson: false)
class FromJsonOptionalParameters {
  final ChildWithFromJson child;

  FromJsonOptionalParameters(this.child);
}

class ChildWithFromJson {
  //ignore: avoid_unused_constructor_parameters
  ChildWithFromJson.fromJson(json, {initValue = false});
}

@JsonSerializable()
class ParentObject {
  int number;
  String str;
  ChildObject child;
}

@JsonSerializable()
class ChildObject {
  int number;
  String str;
}

@JsonSerializable()
class ParentObjectWithChildren {
  int number;
  String str;
  List<ChildObject> children;
}

@JsonSerializable()
class ParentObjectWithDynamicChildren {
  int number;
  String str;
  List<dynamic> children;
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class TrivialNestedNullable {
  TrivialNestedNullable child;
  int otherField;
}

@JsonSerializable(createFactory: false, nullable: false, explicitToJson: true)
class TrivialNestedNonNullable {
  TrivialNestedNonNullable child;
  int otherField;
}
