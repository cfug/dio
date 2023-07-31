// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'enum_type.dart';

part 'input.type_set.g.dart';

@JsonSerializable()
class SimpleClass {
  final Set value;

  @JsonKey(nullable: false)
  final Set nullable;

  @JsonKey(defaultValue: {42, true, false, null})
  Set withDefault;

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
  final Set<BigInt> value;

  @JsonKey(nullable: false)
  final Set<BigInt> nullable;

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
  final Set<bool> value;

  @JsonKey(nullable: false)
  final Set<bool> nullable;

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
  final Set<DateTime> value;

  @JsonKey(nullable: false)
  final Set<DateTime> nullable;

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
  final Set<double> value;

  @JsonKey(nullable: false)
  final Set<double> nullable;

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
  final Set<Duration> value;

  @JsonKey(nullable: false)
  final Set<Duration> nullable;

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
  final Set<dynamic> value;

  @JsonKey(nullable: false)
  final Set<dynamic> nullable;

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
  final Set<EnumType> value;

  @JsonKey(nullable: false)
  final Set<EnumType> nullable;

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
  final Set<int> value;

  @JsonKey(nullable: false)
  final Set<int> nullable;

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
  final Set<num> value;

  @JsonKey(nullable: false)
  final Set<num> nullable;

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
  final Set<Object> value;

  @JsonKey(nullable: false)
  final Set<Object> nullable;

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
  final Set<String> value;

  @JsonKey(nullable: false)
  final Set<String> nullable;

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
  final Set<Uri> value;

  @JsonKey(nullable: false)
  final Set<Uri> nullable;

  SimpleClassUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToJson(this);
}
