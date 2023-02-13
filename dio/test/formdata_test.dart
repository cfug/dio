@TestOn('vm')
import 'dart:convert';
import 'dart:io';

import 'package:diox/diox.dart';
import 'package:test/test.dart';

void main() async {
  test('FormData', () async {
    final fm = FormData.fromMap({
      'name': 'wendux',
      'age': 25,
      'path': '/图片空间/地址',
      'file': MultipartFile.fromString('hello world.', headers: {
        'test': <String>['a']
      }),
      'files': [
        await MultipartFile.fromFile(
          'test/mock/_testfile',
          filename: '1.txt',
          headers: {
            'test': <String>['b']
          },
        ),
        MultipartFile.fromFileSync(
          'test/mock/_testfile',
          filename: '2.txt',
          headers: {
            'test': <String>['c']
          },
        ),
      ]
    });
    final fmStr = await fm.readAsBytes();
    final f = File('test/mock/_formdata');
    String content = f.readAsStringSync();
    content = content.replaceAll('--dio-boundary-3788753558', fm.boundary);
    String actual = utf8.decode(fmStr, allowMalformed: true);

    actual = actual.replaceAll('\r\n', '\n');
    content = content.replaceAll('\r\n', '\n');

    expect(actual, content);
    expect(fm.readAsBytes(), throwsA(const TypeMatcher<StateError>()));

    final fm1 = FormData();
    fm1.fields.add(MapEntry('name', 'wendux'));
    fm1.fields.add(MapEntry('age', '25'));
    fm1.fields.add(MapEntry('path', '/图片空间/地址'));
    fm1.files.add(MapEntry(
      'file',
      MultipartFile.fromString('hello world.', headers: {
        'test': <String>['a']
      }),
    ));
    fm1.files.add(MapEntry(
      'files',
      await MultipartFile.fromFile(
        'test/mock/_testfile',
        filename: '1.txt',
        headers: {
          'test': <String>['b'],
        },
      ),
    ));
    fm1.files.add(MapEntry(
      'files',
      await MultipartFile.fromFile(
        'test/mock/_testfile',
        filename: '2.txt',
        headers: {
          'test': <String>['c'],
        },
      ),
    ));
    expect(fmStr.length, fm1.length);
  });
}
