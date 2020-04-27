// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:dio/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group("json media type test", () {
    test("#test some json types", () async {
      expect(isJsonMime("application/json"), true);
      expect(isJsonMime("application/json; charset=utf-8"), true);
      expect(isJsonMime("application/problem+json"), true);
      expect(isJsonMime("application/hal+json"), true);
      expect(isJsonMime("application/hal+xml"), false);
      expect(isJsonMime("application/vnd.github+json"), true);
      expect(isJsonMime("application/vnd.hal+json"), true);
      expect(isJsonMime("application/activity+json"), true);
      expect(isJsonMime("application/ld+json"), true);
      expect(isJsonMime("application/geo+json"), true);
      expect(isJsonMime("application/vcard+json"), true);
    });
  });
}
