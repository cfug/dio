// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

final jsonSerializableFields = generatorConfigDefaultJson.keys.toList();

final generatorConfigDefaultJson = Map<String, dynamic>.unmodifiable(
    const JsonSerializable().withDefaults().toJson());

final generatorConfigNonDefaultJson =
    Map<String, dynamic>.unmodifiable(const JsonSerializable(
  anyMap: true,
  checked: true,
  createFactory: false,
  createToJson: false,
  disallowUnrecognizedKeys: true,
  explicitToJson: true,
  fieldRename: FieldRename.kebab,
  ignoreUnannotated: true,
  includeIfNull: false,
  nullable: false,
  genericArgumentFactories: true,
).toJson());
