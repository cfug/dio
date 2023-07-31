// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'enum_type.dart';

part 'input.type_map.g.dart';

@JsonSerializable()
class SimpleClass {
  final Map value;

  @JsonKey(nullable: false)
  final Map nullable;

  @JsonKey(defaultValue: {'a': 1})
  Map withDefault;

  SimpleClass(
    this.value,
    this.nullable,
  );

  factory SimpleClass.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToBigInt {
  final Map<BigInt, BigInt> value;

  @JsonKey(nullable: false)
  final Map<BigInt, BigInt> nullable;

  SimpleClassBigIntToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToBigInt {
  final Map<DateTime, BigInt> value;

  @JsonKey(nullable: false)
  final Map<DateTime, BigInt> nullable;

  SimpleClassDateTimeToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToBigInt {
  final Map<dynamic, BigInt> value;

  @JsonKey(nullable: false)
  final Map<dynamic, BigInt> nullable;

  SimpleClassDynamicToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToBigInt {
  final Map<EnumType, BigInt> value;

  @JsonKey(nullable: false)
  final Map<EnumType, BigInt> nullable;

  SimpleClassEnumTypeToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassIntToBigInt {
  final Map<int, BigInt> value;

  @JsonKey(nullable: false)
  final Map<int, BigInt> nullable;

  SimpleClassIntToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToBigInt {
  final Map<Object, BigInt> value;

  @JsonKey(nullable: false)
  final Map<Object, BigInt> nullable;

  SimpleClassObjectToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassStringToBigInt {
  final Map<String, BigInt> value;

  @JsonKey(nullable: false)
  final Map<String, BigInt> nullable;

  SimpleClassStringToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassUriToBigInt {
  final Map<Uri, BigInt> value;

  @JsonKey(nullable: false)
  final Map<Uri, BigInt> nullable;

  SimpleClassUriToBigInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToBigInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToBigIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToBigIntToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToBool {
  final Map<BigInt, bool> value;

  @JsonKey(nullable: false)
  final Map<BigInt, bool> nullable;

  SimpleClassBigIntToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToBool {
  final Map<DateTime, bool> value;

  @JsonKey(nullable: false)
  final Map<DateTime, bool> nullable;

  SimpleClassDateTimeToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToBool {
  final Map<dynamic, bool> value;

  @JsonKey(nullable: false)
  final Map<dynamic, bool> nullable;

  SimpleClassDynamicToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToBool {
  final Map<EnumType, bool> value;

  @JsonKey(nullable: false)
  final Map<EnumType, bool> nullable;

  SimpleClassEnumTypeToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassIntToBool {
  final Map<int, bool> value;

  @JsonKey(nullable: false)
  final Map<int, bool> nullable;

  SimpleClassIntToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToBool {
  final Map<Object, bool> value;

  @JsonKey(nullable: false)
  final Map<Object, bool> nullable;

  SimpleClassObjectToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassStringToBool {
  final Map<String, bool> value;

  @JsonKey(nullable: false)
  final Map<String, bool> nullable;

  SimpleClassStringToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassUriToBool {
  final Map<Uri, bool> value;

  @JsonKey(nullable: false)
  final Map<Uri, bool> nullable;

  SimpleClassUriToBool(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToBool.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToBoolFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToBoolToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToDateTime {
  final Map<BigInt, DateTime> value;

  @JsonKey(nullable: false)
  final Map<BigInt, DateTime> nullable;

  SimpleClassBigIntToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToDateTime {
  final Map<DateTime, DateTime> value;

  @JsonKey(nullable: false)
  final Map<DateTime, DateTime> nullable;

  SimpleClassDateTimeToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToDateTime {
  final Map<dynamic, DateTime> value;

  @JsonKey(nullable: false)
  final Map<dynamic, DateTime> nullable;

  SimpleClassDynamicToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToDateTime {
  final Map<EnumType, DateTime> value;

  @JsonKey(nullable: false)
  final Map<EnumType, DateTime> nullable;

  SimpleClassEnumTypeToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassIntToDateTime {
  final Map<int, DateTime> value;

  @JsonKey(nullable: false)
  final Map<int, DateTime> nullable;

  SimpleClassIntToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToDateTime {
  final Map<Object, DateTime> value;

  @JsonKey(nullable: false)
  final Map<Object, DateTime> nullable;

  SimpleClassObjectToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassStringToDateTime {
  final Map<String, DateTime> value;

  @JsonKey(nullable: false)
  final Map<String, DateTime> nullable;

  SimpleClassStringToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassUriToDateTime {
  final Map<Uri, DateTime> value;

  @JsonKey(nullable: false)
  final Map<Uri, DateTime> nullable;

  SimpleClassUriToDateTime(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToDateTime.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToDateTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToDateTimeToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToDouble {
  final Map<BigInt, double> value;

  @JsonKey(nullable: false)
  final Map<BigInt, double> nullable;

  SimpleClassBigIntToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToDouble {
  final Map<DateTime, double> value;

  @JsonKey(nullable: false)
  final Map<DateTime, double> nullable;

  SimpleClassDateTimeToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToDouble {
  final Map<dynamic, double> value;

  @JsonKey(nullable: false)
  final Map<dynamic, double> nullable;

  SimpleClassDynamicToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToDouble {
  final Map<EnumType, double> value;

  @JsonKey(nullable: false)
  final Map<EnumType, double> nullable;

  SimpleClassEnumTypeToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassIntToDouble {
  final Map<int, double> value;

  @JsonKey(nullable: false)
  final Map<int, double> nullable;

  SimpleClassIntToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToDouble {
  final Map<Object, double> value;

  @JsonKey(nullable: false)
  final Map<Object, double> nullable;

  SimpleClassObjectToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassStringToDouble {
  final Map<String, double> value;

  @JsonKey(nullable: false)
  final Map<String, double> nullable;

  SimpleClassStringToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassUriToDouble {
  final Map<Uri, double> value;

  @JsonKey(nullable: false)
  final Map<Uri, double> nullable;

  SimpleClassUriToDouble(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToDouble.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToDoubleFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToDoubleToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToDuration {
  final Map<BigInt, Duration> value;

  @JsonKey(nullable: false)
  final Map<BigInt, Duration> nullable;

  SimpleClassBigIntToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToDuration {
  final Map<DateTime, Duration> value;

  @JsonKey(nullable: false)
  final Map<DateTime, Duration> nullable;

  SimpleClassDateTimeToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToDuration {
  final Map<dynamic, Duration> value;

  @JsonKey(nullable: false)
  final Map<dynamic, Duration> nullable;

  SimpleClassDynamicToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToDuration {
  final Map<EnumType, Duration> value;

  @JsonKey(nullable: false)
  final Map<EnumType, Duration> nullable;

  SimpleClassEnumTypeToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassIntToDuration {
  final Map<int, Duration> value;

  @JsonKey(nullable: false)
  final Map<int, Duration> nullable;

  SimpleClassIntToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToDuration {
  final Map<Object, Duration> value;

  @JsonKey(nullable: false)
  final Map<Object, Duration> nullable;

  SimpleClassObjectToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassStringToDuration {
  final Map<String, Duration> value;

  @JsonKey(nullable: false)
  final Map<String, Duration> nullable;

  SimpleClassStringToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassUriToDuration {
  final Map<Uri, Duration> value;

  @JsonKey(nullable: false)
  final Map<Uri, Duration> nullable;

  SimpleClassUriToDuration(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToDuration.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToDurationFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToDurationToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToDynamic {
  final Map<BigInt, dynamic> value;

  @JsonKey(nullable: false)
  final Map<BigInt, dynamic> nullable;

  SimpleClassBigIntToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToDynamic {
  final Map<DateTime, dynamic> value;

  @JsonKey(nullable: false)
  final Map<DateTime, dynamic> nullable;

  SimpleClassDateTimeToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToDynamic {
  final Map<dynamic, dynamic> value;

  @JsonKey(nullable: false)
  final Map<dynamic, dynamic> nullable;

  SimpleClassDynamicToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToDynamic {
  final Map<EnumType, dynamic> value;

  @JsonKey(nullable: false)
  final Map<EnumType, dynamic> nullable;

  SimpleClassEnumTypeToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassIntToDynamic {
  final Map<int, dynamic> value;

  @JsonKey(nullable: false)
  final Map<int, dynamic> nullable;

  SimpleClassIntToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToDynamic {
  final Map<Object, dynamic> value;

  @JsonKey(nullable: false)
  final Map<Object, dynamic> nullable;

  SimpleClassObjectToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassStringToDynamic {
  final Map<String, dynamic> value;

  @JsonKey(nullable: false)
  final Map<String, dynamic> nullable;

  SimpleClassStringToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassUriToDynamic {
  final Map<Uri, dynamic> value;

  @JsonKey(nullable: false)
  final Map<Uri, dynamic> nullable;

  SimpleClassUriToDynamic(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToDynamic.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToDynamicFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToDynamicToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToEnumType {
  final Map<BigInt, EnumType> value;

  @JsonKey(nullable: false)
  final Map<BigInt, EnumType> nullable;

  SimpleClassBigIntToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToEnumType {
  final Map<DateTime, EnumType> value;

  @JsonKey(nullable: false)
  final Map<DateTime, EnumType> nullable;

  SimpleClassDateTimeToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToEnumType {
  final Map<dynamic, EnumType> value;

  @JsonKey(nullable: false)
  final Map<dynamic, EnumType> nullable;

  SimpleClassDynamicToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToEnumType {
  final Map<EnumType, EnumType> value;

  @JsonKey(nullable: false)
  final Map<EnumType, EnumType> nullable;

  SimpleClassEnumTypeToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassIntToEnumType {
  final Map<int, EnumType> value;

  @JsonKey(nullable: false)
  final Map<int, EnumType> nullable;

  SimpleClassIntToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToEnumType {
  final Map<Object, EnumType> value;

  @JsonKey(nullable: false)
  final Map<Object, EnumType> nullable;

  SimpleClassObjectToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassStringToEnumType {
  final Map<String, EnumType> value;

  @JsonKey(nullable: false)
  final Map<String, EnumType> nullable;

  SimpleClassStringToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassUriToEnumType {
  final Map<Uri, EnumType> value;

  @JsonKey(nullable: false)
  final Map<Uri, EnumType> nullable;

  SimpleClassUriToEnumType(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToEnumType.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToEnumTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToEnumTypeToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToInt {
  final Map<BigInt, int> value;

  @JsonKey(nullable: false)
  final Map<BigInt, int> nullable;

  SimpleClassBigIntToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToIntToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToInt {
  final Map<DateTime, int> value;

  @JsonKey(nullable: false)
  final Map<DateTime, int> nullable;

  SimpleClassDateTimeToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToIntToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToInt {
  final Map<dynamic, int> value;

  @JsonKey(nullable: false)
  final Map<dynamic, int> nullable;

  SimpleClassDynamicToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToIntToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToInt {
  final Map<EnumType, int> value;

  @JsonKey(nullable: false)
  final Map<EnumType, int> nullable;

  SimpleClassEnumTypeToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToIntToJson(this);
}

@JsonSerializable()
class SimpleClassIntToInt {
  final Map<int, int> value;

  @JsonKey(nullable: false)
  final Map<int, int> nullable;

  SimpleClassIntToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToIntToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToInt {
  final Map<Object, int> value;

  @JsonKey(nullable: false)
  final Map<Object, int> nullable;

  SimpleClassObjectToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToIntToJson(this);
}

@JsonSerializable()
class SimpleClassStringToInt {
  final Map<String, int> value;

  @JsonKey(nullable: false)
  final Map<String, int> nullable;

  SimpleClassStringToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToIntToJson(this);
}

@JsonSerializable()
class SimpleClassUriToInt {
  final Map<Uri, int> value;

  @JsonKey(nullable: false)
  final Map<Uri, int> nullable;

  SimpleClassUriToInt(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToInt.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToIntFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToIntToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToNum {
  final Map<BigInt, num> value;

  @JsonKey(nullable: false)
  final Map<BigInt, num> nullable;

  SimpleClassBigIntToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToNumToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToNum {
  final Map<DateTime, num> value;

  @JsonKey(nullable: false)
  final Map<DateTime, num> nullable;

  SimpleClassDateTimeToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToNumToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToNum {
  final Map<dynamic, num> value;

  @JsonKey(nullable: false)
  final Map<dynamic, num> nullable;

  SimpleClassDynamicToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToNumToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToNum {
  final Map<EnumType, num> value;

  @JsonKey(nullable: false)
  final Map<EnumType, num> nullable;

  SimpleClassEnumTypeToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToNumToJson(this);
}

@JsonSerializable()
class SimpleClassIntToNum {
  final Map<int, num> value;

  @JsonKey(nullable: false)
  final Map<int, num> nullable;

  SimpleClassIntToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToNumToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToNum {
  final Map<Object, num> value;

  @JsonKey(nullable: false)
  final Map<Object, num> nullable;

  SimpleClassObjectToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToNumToJson(this);
}

@JsonSerializable()
class SimpleClassStringToNum {
  final Map<String, num> value;

  @JsonKey(nullable: false)
  final Map<String, num> nullable;

  SimpleClassStringToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToNumToJson(this);
}

@JsonSerializable()
class SimpleClassUriToNum {
  final Map<Uri, num> value;

  @JsonKey(nullable: false)
  final Map<Uri, num> nullable;

  SimpleClassUriToNum(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToNum.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToNumFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToNumToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToObject {
  final Map<BigInt, Object> value;

  @JsonKey(nullable: false)
  final Map<BigInt, Object> nullable;

  SimpleClassBigIntToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToObject {
  final Map<DateTime, Object> value;

  @JsonKey(nullable: false)
  final Map<DateTime, Object> nullable;

  SimpleClassDateTimeToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToObject {
  final Map<dynamic, Object> value;

  @JsonKey(nullable: false)
  final Map<dynamic, Object> nullable;

  SimpleClassDynamicToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToObject {
  final Map<EnumType, Object> value;

  @JsonKey(nullable: false)
  final Map<EnumType, Object> nullable;

  SimpleClassEnumTypeToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassIntToObject {
  final Map<int, Object> value;

  @JsonKey(nullable: false)
  final Map<int, Object> nullable;

  SimpleClassIntToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToObject {
  final Map<Object, Object> value;

  @JsonKey(nullable: false)
  final Map<Object, Object> nullable;

  SimpleClassObjectToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassStringToObject {
  final Map<String, Object> value;

  @JsonKey(nullable: false)
  final Map<String, Object> nullable;

  SimpleClassStringToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassUriToObject {
  final Map<Uri, Object> value;

  @JsonKey(nullable: false)
  final Map<Uri, Object> nullable;

  SimpleClassUriToObject(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToObject.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToObjectToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToString {
  final Map<BigInt, String> value;

  @JsonKey(nullable: false)
  final Map<BigInt, String> nullable;

  SimpleClassBigIntToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToStringToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToString {
  final Map<DateTime, String> value;

  @JsonKey(nullable: false)
  final Map<DateTime, String> nullable;

  SimpleClassDateTimeToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToStringToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToString {
  final Map<dynamic, String> value;

  @JsonKey(nullable: false)
  final Map<dynamic, String> nullable;

  SimpleClassDynamicToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToStringToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToString {
  final Map<EnumType, String> value;

  @JsonKey(nullable: false)
  final Map<EnumType, String> nullable;

  SimpleClassEnumTypeToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToStringToJson(this);
}

@JsonSerializable()
class SimpleClassIntToString {
  final Map<int, String> value;

  @JsonKey(nullable: false)
  final Map<int, String> nullable;

  SimpleClassIntToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToStringToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToString {
  final Map<Object, String> value;

  @JsonKey(nullable: false)
  final Map<Object, String> nullable;

  SimpleClassObjectToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToStringToJson(this);
}

@JsonSerializable()
class SimpleClassStringToString {
  final Map<String, String> value;

  @JsonKey(nullable: false)
  final Map<String, String> nullable;

  SimpleClassStringToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToStringToJson(this);
}

@JsonSerializable()
class SimpleClassUriToString {
  final Map<Uri, String> value;

  @JsonKey(nullable: false)
  final Map<Uri, String> nullable;

  SimpleClassUriToString(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToString.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToStringFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToStringToJson(this);
}

@JsonSerializable()
class SimpleClassBigIntToUri {
  final Map<BigInt, Uri> value;

  @JsonKey(nullable: false)
  final Map<BigInt, Uri> nullable;

  SimpleClassBigIntToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassBigIntToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassBigIntToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassBigIntToUriToJson(this);
}

@JsonSerializable()
class SimpleClassDateTimeToUri {
  final Map<DateTime, Uri> value;

  @JsonKey(nullable: false)
  final Map<DateTime, Uri> nullable;

  SimpleClassDateTimeToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassDateTimeToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDateTimeToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDateTimeToUriToJson(this);
}

@JsonSerializable()
class SimpleClassDynamicToUri {
  final Map<dynamic, Uri> value;

  @JsonKey(nullable: false)
  final Map<dynamic, Uri> nullable;

  SimpleClassDynamicToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassDynamicToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassDynamicToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassDynamicToUriToJson(this);
}

@JsonSerializable()
class SimpleClassEnumTypeToUri {
  final Map<EnumType, Uri> value;

  @JsonKey(nullable: false)
  final Map<EnumType, Uri> nullable;

  SimpleClassEnumTypeToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassEnumTypeToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassEnumTypeToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassEnumTypeToUriToJson(this);
}

@JsonSerializable()
class SimpleClassIntToUri {
  final Map<int, Uri> value;

  @JsonKey(nullable: false)
  final Map<int, Uri> nullable;

  SimpleClassIntToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassIntToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassIntToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassIntToUriToJson(this);
}

@JsonSerializable()
class SimpleClassObjectToUri {
  final Map<Object, Uri> value;

  @JsonKey(nullable: false)
  final Map<Object, Uri> nullable;

  SimpleClassObjectToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassObjectToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassObjectToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassObjectToUriToJson(this);
}

@JsonSerializable()
class SimpleClassStringToUri {
  final Map<String, Uri> value;

  @JsonKey(nullable: false)
  final Map<String, Uri> nullable;

  SimpleClassStringToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassStringToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassStringToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassStringToUriToJson(this);
}

@JsonSerializable()
class SimpleClassUriToUri {
  final Map<Uri, Uri> value;

  @JsonKey(nullable: false)
  final Map<Uri, Uri> nullable;

  SimpleClassUriToUri(
    this.value,
    this.nullable,
  );

  factory SimpleClassUriToUri.fromJson(Map<String, dynamic> json) =>
      _$SimpleClassUriToUriFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleClassUriToUriToJson(this);
}
