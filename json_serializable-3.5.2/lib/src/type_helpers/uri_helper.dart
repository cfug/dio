// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../type_helper.dart';
import 'to_from_string.dart';

class UriHelper extends TypeHelper {
  const UriHelper();

  @override
  String serialize(
    DartType targetType,
    String expression,
    TypeHelperContext context,
  ) =>
      uriString.serialize(targetType, expression, context.nullable);

  @override
  String deserialize(
    DartType targetType,
    String expression,
    TypeHelperContext context,
  ) =>
      uriString.deserialize(targetType, expression, context.nullable, false);
}
