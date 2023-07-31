// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'generic_argument_factories.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class GenericClassWithHelpers<T, S> {
  final T value;

  final List<T> list;

  final Set<S> someSet;

  GenericClassWithHelpers(
    this.value,
    this.list,
    this.someSet,
  );

  factory GenericClassWithHelpers.fromJson(
    Map<String, dynamic> json,
    T Function(Object json) fromJsonT,
    S Function(Object json) fromJsonS,
  ) =>
      _$GenericClassWithHelpersFromJson(json, fromJsonT, fromJsonS);

  Map<String, dynamic> toJson(
    Object Function(T value) toJsonT,
    Object Function(S value) toJsonS,
  ) =>
      _$GenericClassWithHelpersToJson(this, toJsonT, toJsonS);
}

@JsonSerializable()
class ConcreteClass {
  final GenericClassWithHelpers<int, String> value;

  final GenericClassWithHelpers<double, BigInt> value2;

  ConcreteClass(this.value, this.value2);

  factory ConcreteClass.fromJson(Map<String, dynamic> json) =>
      _$ConcreteClassFromJson(json);

  Map<String, dynamic> toJson() => _$ConcreteClassToJson(this);
}
