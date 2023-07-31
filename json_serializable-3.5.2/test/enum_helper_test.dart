// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:test/test.dart';
import 'package:json_serializable/src/type_helpers/enum_helper.dart';

void main() {
  group('expression test', () {
    group('simple', () {
      for (final expression in [
        'hello',
        'HELLO',
        'hi_to',
        '_private',
        'weird_'
      ]) {
        test(expression, () {
          expect(simpleExpression.hasMatch(expression), isTrue);
        });
      }
    });

    group('not simple', () {
      for (final expression in ['nice[thing]', 'a.b']) {
        test(expression, () {
          expect(simpleExpression.hasMatch(expression), isFalse);
        });
      }
    });
  });
}
