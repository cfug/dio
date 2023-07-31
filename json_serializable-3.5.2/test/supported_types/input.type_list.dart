// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'enum_type.dart';

part 'input.type_list.g.dart';

@JsonSerializable()
class SimpleClass {
  final List value;

  @JsonKey(nullable: false)
  final List nullable;

  @JsonKey(defaultValue: [42, true, false, null])
  List withDefault;

  SimpleClass(
    this.value,
    this.nullable,
  );

  factory SimpleClass.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassToJson(this);
}

@JsonSerializable()
class SimpleClassBigInt {
  final List<BigInt> value;

  @JsonKey(nullable: false)
  final List<BigInt> nullable;

  SimpleClassBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassBool {
  final List<bool> value;

  @JsonKey(nullable: false)
  final List<bool> nullable;

  SimpleClassBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBoolToJson(this);
}

@JsonSerializable()
class SimpleClassDateTime {
  final List<DateTime> value;

  @JsonKey(nullable: false)
  final List<DateTime> nullable;

  SimpleClassDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassDouble {
  final List<double> value;

  @JsonKey(nullable: false)
  final List<double> nullable;

  SimpleClassDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassDuration {
  final List<Duration> value;

  @JsonKey(nullable: false)
  final List<Duration> nullable;

  SimpleClassDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDurationToJson(this);
}

@JsonSerializable()
class SimpleClassDynamic {
  final List<dynamic> value;

  @JsonKey(nullable: false)
  final List<dynamic> nullable;

  SimpleClassDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassEnumType {
  final List<EnumType> value;

  @JsonKey(nullable: false)
  final List<EnumType> nullable;

  SimpleClassEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassInt {
  final List<int> value;

  @JsonKey(nullable: false)
  final List<int> nullable;

  SimpleClassInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToJson(this);
}

@JsonSerializable()
class SimpleClassNum {
  final List<num> value;

  @JsonKey(nullable: false)
  final List<num> nullable;

  SimpleClassNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassNumToJson(this);
}

@JsonSerializable()
class SimpleClassObject {
  final List<Object> value;

  @JsonKey(nullable: false)
  final List<Object> nullable;

  SimpleClassObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToJson(this);
}

@JsonSerializable()
class SimpleClassString {
  final List<String> value;

  @JsonKey(nullable: false)
  final List<String> nullable;

  SimpleClassString(
    this.value,
    this.nullable,
  );

  factory SimpleClassString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToJson(this);
}

@JsonSerializable()
class SimpleClassUri {
  final List<Uri> value;

  @JsonKey(nullable: false)
  final List<Uri> nullable;

  SimpleClassUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToJson(this);
}
