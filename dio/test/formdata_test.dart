import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

void main() async {
  group(FormData, () {
    test(
      'complex',
      () async {
        final fm = FormData.fromMap({
          'name': 'wendux',
          'age': 25,
          'path': '/图片空间/地址',
          'file': MultipartFile.fromString(
            'hello world.',
            headers: {
              'test': <String>['a'],
            },
          ),
          'files': [
            await MultipartFile.fromFile(
              'test/mock/_testfile',
              filename: '1.txt',
              headers: {
                'test': <String>['b'],
              },
            ),
            MultipartFile.fromFileSync(
              'test/mock/_testfile',
              filename: '2.txt',
              headers: {
                'test': <String>['c'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
            MultipartFile.fromBytes(
              utf8.encode('hello world again.').toList(),
              filename: '3.txt',
              headers: {
                'test': <String>['d'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
          ],
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
        fm1.fields.add(const MapEntry('name', 'wendux'));
        fm1.fields.add(const MapEntry('age', '25'));
        fm1.fields.add(const MapEntry('path', '/图片空间/地址'));
        fm1.files.add(
          MapEntry(
            'file',
            MultipartFile.fromString(
              'hello world.',
              headers: {
                'test': <String>['a'],
              },
            ),
          ),
        );
        fm1.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              'test/mock/_testfile',
              filename: '1.txt',
              headers: {
                'test': <String>['b'],
              },
            ),
          ),
        );
        fm1.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              'test/mock/_testfile',
              filename: '2.txt',
              headers: {
                'test': <String>['c'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
          ),
        );
        fm1.files.add(
          MapEntry(
            'files',
            MultipartFile.fromBytes(
              utf8.encode('hello world again.'),
              filename: '3.txt',
              headers: {
                'test': <String>['d'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
          ),
        );
        expect(fmStr.length, fm1.length);
      },
      testOn: 'vm',
    );

    test(
      'complex cloning FormData object',
      () async {
        final fm = FormData.fromMap({
          'name': 'wendux',
          'age': 25,
          'path': '/图片空间/地址',
          'file': MultipartFile.fromString(
            'hello world.',
            headers: {
              'test': <String>['a'],
            },
          ),
          'files': [
            await MultipartFile.fromFile(
              'test/mock/_testfile',
              filename: '1.txt',
              headers: {
                'test': <String>['b'],
              },
            ),
            MultipartFile.fromFileSync(
              'test/mock/_testfile',
              filename: '2.txt',
              headers: {
                'test': <String>['c'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
            MultipartFile.fromBytes(
              utf8.encode('hello world again.'),
              filename: '3.txt',
              headers: {
                'test': <String>['d'],
              },
              contentType: DioMediaType.parse('text/plain'),
            ),
          ],
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

        final fm1 = fm.clone();
        expect(fm1.isFinalized, false);
        final fm1Str = await fm1.readAsBytes();
        expect(fmStr.length, fm1Str.length);
        expect(fm1.isFinalized, true);
        expect(fm1 != fm, true);
        expect(fm1.files[0].value.filename, fm.files[0].value.filename);
        expect(fm1.fields, fm.fields);
        expect(fm1.boundary, fm.boundary);
      },
      testOn: 'vm',
    );

    test('encodes maps correctly', () async {
      final fd = FormData.fromMap(
        {
          'items': [
            {'name': 'foo', 'value': 1},
            {'name': 'bar', 'value': 2},
          ],
          'api': {
            'dest': '/',
            'data': {
              'a': 1,
              'b': 2,
              'c': 3,
            },
          },
        },
        ListFormat.multiCompatible,
      );

      final data = await fd.readAsBytes();
      final result = utf8.decode(data, allowMalformed: true);

      expect(result, contains('name="items[0][name]"'));
      expect(result, contains('name="items[0][value]"'));

      expect(result, contains('name="items[1][name]"'));
      expect(result, contains('name="items[1][value]"'));
      expect(result, contains('name="items[1][value]"'));

      expect(result, contains('name="api[dest]"'));
      expect(result, contains('name="api[data][a]"'));
      expect(result, contains('name="api[data][b]"'));
      expect(result, contains('name="api[data][c]"'));
    });

    test('encodes dynamic Map correctly', () async {
      final dynamicData = <dynamic, dynamic>{
        'a': 1,
        'b': 2,
        'c': 3,
      };

      final request = {
        'api': {
          'dest': '/',
          'data': dynamicData,
        },
      };

      final fd = FormData.fromMap(request);
      final data = await fd.readAsBytes();
      final result = utf8.decode(data, allowMalformed: true);
      expect(result, contains('name="api[dest]"'));
      expect(result, contains('name="api[data][a]"'));
      expect(result, contains('name="api[data][b]"'));
      expect(result, contains('name="api[data][c]"'));
    });

    test('posts maps correctly', () async {
      final fd = FormData.fromMap(
        {
          'items': [
            {'name': 'foo', 'value': 1},
            {'name': 'bar', 'value': 2},
          ],
          'api': {
            'dest': '/',
            'data': {
              'a': 1,
              'b': 2,
              'c': 3,
            },
          },
        },
        ListFormat.multiCompatible,
      );

      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      final response = await dio.post(
        '/post',
        data: fd,
      );

      final result = response.data;
      expect(result, contains('name="items[0][name]"'));
      expect(result, contains('name="items[0][value]"'));

      expect(result, contains('name="items[1][name]"'));
      expect(result, contains('name="items[1][value]"'));
      expect(result, contains('name="items[1][value]"'));

      expect(result, contains('name="api[dest]"'));
      expect(result, contains('name="api[data][a]"'));
      expect(result, contains('name="api[data][b]"'));
      expect(result, contains('name="api[data][c]"'));
    });

    test('posts maps with a null value item correctly', () async {
      final fd = FormData.fromMap(
        {
          'items': [
            {'name': 'foo', 'value': 1},
            {'name': 'bar', 'value': 2},
            {'name': 'null', 'value': null},
          ],
        },
        ListFormat.multiCompatible,
      );

      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      final response = await dio.post(
        '/post',
        data: fd,
      );

      expect(fd.fields[5].value, '');

      final result = response.data;
      expect(result, contains('name="items[0][name]"'));
      expect(result, contains('name="items[0][value]"'));

      expect(result, contains('name="items[1][name]"'));
      expect(result, contains('name="items[1][value]"'));

      expect(result, contains('name="items[2][name]"'));
      expect(result, contains('name="items[2][value]"'));
    });

    test('has the correct boundary', () async {
      final fd1 = FormData();
      expect(fd1.boundary, matches(RegExp(r'dio-boundary-\d{10}')));
      const name = 'test-boundary';
      final fd2 = FormData(boundaryName: name);
      expect(fd2.boundary, matches(RegExp('$name-\\d{10}')));
      expect(fd2.boundary.length, name.length + 11);
      final fd3 = FormData.fromMap(
        {'test-key': 'test-value'},
        ListFormat.multi,
        false,
        name,
      );
      final fd3Data = utf8.decode(await fd3.readAsBytes()).trim();
      expect(fd3Data, matches(RegExp('.*--$name-\\d{10}--\\s?\$')));
    });
  });
}
