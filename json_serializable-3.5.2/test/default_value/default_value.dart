// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: annotate_overrides

import 'package:json_annotation/json_annotation.dart';

import 'default_value_interface.dart' as dvi hide Greek;
import 'default_value_interface.dart' show Greek;

part 'default_value.g.dart';

const _intValue = 42;

dvi.DefaultValue fromJson(Map<String, dynamic> json) =>
    _$DefaultValueFromJson(json);

@JsonSerializable()
class DefaultValue implements dvi.DefaultValue {
  @JsonKey(defaultValue: true)
  bool fieldBool;

  @JsonKey(defaultValue: 'string', includeIfNull: false)
  String fieldString;

  @JsonKey(defaultValue: _intValue)
  int fieldInt;

  @JsonKey(defaultValue: 3.14)
  double fieldDouble;

  @JsonKey(defaultValue: [])
  List fieldListEmpty;

  @JsonKey(defaultValue: <int>{})
  Set fieldSetEmpty;

  @JsonKey(defaultValue: {})
  Map fieldMapEmpty;

  @JsonKey(defaultValue: [1, 2, 3])
  List<int> fieldListSimple;

  @JsonKey(defaultValue: {'entry1', 'entry2'})
  Set<String> fieldSetSimple;

  @JsonKey(defaultValue: {'answer': 42})
  Map<String, int> fieldMapSimple;

  @JsonKey(defaultValue: {
    'root': ['child']
  })
  Map<String, List<String>> fieldMapListString;

  @JsonKey(defaultValue: Greek.beta)
  Greek fieldEnum;

  DefaultValue();

  factory DefaultValue.fromJson(Map<String, dynamic> json) =>
      _$DefaultValueFromJson(json);

  Map<String, dynamic> toJson() => _$DefaultValueToJson(this);
}
