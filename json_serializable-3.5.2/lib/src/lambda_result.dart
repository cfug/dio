// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LambdaResult {
  final String expression;
  final String lambda;

  LambdaResult(this.expression, this.lambda);

  @override
  String toString() => '$lambda($expression)';

  static String process(Object subField, String closureArg) =>
      (subField is LambdaResult && closureArg == subField.expression)
          ? subField.lambda
          : '($closureArg) => $subField';
}
