// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'simple_object.g.dart';

@JsonSerializable(anyMap: true)
class SimpleObject {
  final int value;

  SimpleObject(this.value);

  factory SimpleObject.fromJson(Map json) => _$SimpleObjectFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleObjectToJson(this);
}
