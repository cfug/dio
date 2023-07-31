// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

class GenericConverter<T> implements JsonConverter<T, Map<String, dynamic>> {
  const GenericConverter();

  @override
  T fromJson(Map<String, dynamic> json) => null;

  @override
  Map<String, dynamic> toJson(T object) => {};
}

class TrivialNumber {
  final int value;

  TrivialNumber(this.value);
}

class TrivialNumberConverter implements JsonConverter<TrivialNumber, int> {
  static const instance = TrivialNumberConverter();

  const TrivialNumberConverter();

  @override
  TrivialNumber fromJson(int json) => TrivialNumber(json);

  @override
  int toJson(TrivialNumber object) => object?.value;
}

class BigIntStringConverter implements JsonConverter<BigInt, String> {
  const BigIntStringConverter();

  @override
  BigInt fromJson(String json) => json == null ? null : BigInt.parse(json);

  @override
  String toJson(BigInt object) => object?.toString();
}

const durationConverter = DurationMillisecondConverter();

class DurationMillisecondConverter implements JsonConverter<Duration, int> {
  const DurationMillisecondConverter();

  @override
  Duration fromJson(int json) =>
      json == null ? null : Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object?.inMilliseconds;
}

class EpochDateTimeConverter implements JsonConverter<DateTime, int> {
  const EpochDateTimeConverter();

  @override
  DateTime fromJson(int json) =>
      json == null ? null : DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object?.millisecondsSinceEpoch;
}
