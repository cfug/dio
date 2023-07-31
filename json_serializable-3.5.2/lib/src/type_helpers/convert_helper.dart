// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../json_key_utils.dart';
import '../shared_checkers.dart';
import '../type_helper.dart';
import '../utils.dart';

/// Information used by [ConvertHelper] when handling `JsonKey`-annotated
/// fields with `toJson` or `fromJson` values set.
class ConvertData {
  final String name;
  final DartType paramType;

  ConvertData(this.name, this.paramType);
}

abstract class TypeHelperContextWithConvert extends TypeHelperContext {
  ConvertData get serializeConvertData;

  ConvertData get deserializeConvertData;
}

class ConvertHelper extends TypeHelper<TypeHelperContextWithConvert> {
  const ConvertHelper();

  @override
  String serialize(
    DartType targetType,
    String expression,
    TypeHelperContextWithConvert context,
  ) {
    final toJsonData = context.serializeConvertData;
    if (toJsonData == null) {
      return null;
    }

    logFieldWithConversionFunction(context.fieldElement);

    assert(toJsonData.paramType is TypeParameterType ||
        targetType.isAssignableTo(toJsonData.paramType));
    return '${toJsonData.name}($expression)';
  }

  @override
  String deserialize(
    DartType targetType,
    String expression,
    TypeHelperContextWithConvert context,
  ) {
    final fromJsonData = context.deserializeConvertData;
    if (fromJsonData == null) {
      return null;
    }

    logFieldWithConversionFunction(context.fieldElement);

    final asContent = asStatement(fromJsonData.paramType);
    return '${fromJsonData.name}($expression$asContent)';
  }
}
