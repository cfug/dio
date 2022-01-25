// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() async {
  test('#test FormData', () async {
    var fm = FormData.fromMap({
      'name': 'wendux',
      'age': 25,
      'file': MultipartFile.fromString('hello world.', headers: {
        'test': <String>['a']
      }),
      'files': [
        await MultipartFile.fromFile(
          '../dio/test/_testfile',
          filename: '1.txt',
          headers: {
            'test': <String>['b']
          },
        ),
        MultipartFile.fromFileSync(
          '../dio/test/_testfile',
          filename: '2.txt',
          headers: {
            'test': <String>['c']
          },
        ),
      ]
    });
    var fmStr = await fm.readAsBytes();
    var f = File('../dio/test/_formdata');
    var content = f.readAsStringSync();
    content = content.replaceAll('--dio-boundary-3788753558', fm.boundary);
    var actual = utf8.decode(fmStr, allowMalformed: true);

    actual = actual.replaceAll('\r\n', '\n');
    content = content.replaceAll('\r\n', '\n');

    expect(actual, content);
    expect(fm.readAsBytes(), throwsA(const TypeMatcher<StateError>()));

    var fm1 = FormData();
    fm1.fields.add(MapEntry('name', 'wendux'));
    fm1.fields.add(MapEntry('age', '25'));
    fm1.files.add(MapEntry(
      'file',
      MultipartFile.fromString('hello world.', headers: {
        'test': <String>['a']
      }),
    ));
    fm1.files.add(MapEntry(
      'files',
      await MultipartFile.fromFile('../dio/test/_testfile',
          filename: '1.txt',
          headers: {
            'test': <String>['b']
          }),
    ));
    fm1.files.add(MapEntry(
      'files',
      await MultipartFile.fromFile('../dio/test/_testfile',
          filename: '2.txt',
          headers: {
            'test': <String>['c']
          }),
    ));
    assert(fmStr.length == fm1.length);
  });
}
