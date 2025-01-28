import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../util.dart';

void uploadTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  test('Uint8List should not be transformed', () async {
    final bytes = Uint8List.fromList(List.generate(10, (index) => index));
    final transformer = dio.transformer = _TestTransformer();
    final r = await dio.put(
      '/put',
      data: bytes,
    );
    expect(transformer.requestTransformed, isFalse);
    expect(r.statusCode, 200);
  });

  test('List<int> should be transformed', () async {
    final ints = List.generate(10, (index) => index);
    final transformer = dio.transformer = _TestTransformer();
    final r = await dio.put(
      '/put',
      data: ints,
    );
    expect(transformer.requestTransformed, isTrue);
    expect(r.data['data'], ints.toString());
  });

  test('stream', () async {
    const str = 'hello 😌';
    final bytes = utf8.encode(str).toList();
    final stream = Stream.fromIterable(bytes.map((e) => [e]));
    final r = await dio.put(
      '/put',
      data: stream,
      options: Options(
        contentType: Headers.textPlainContentType,
        headers: {
          Headers.contentLengthHeader: bytes.length, // set content-length
        },
      ),
    );
    expect(r.data['data'], str);
  });

  test(
    'file stream',
    () async {
      final tmp = Directory.systemTemp.createTempSync('dio_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final f = File(p.join(tmp.path, 'flutter.png'));
      f.createSync();
      f.writeAsBytesSync(base64Decode(_flutterLogPngBase64));

      final contentLength = f.lengthSync();
      final r = await dio.put(
        '/put',
        data: f.openRead(),
        options: Options(
          contentType: 'image/png',
          headers: {
            Headers.contentLengthHeader: contentLength,
          },
        ),
      );
      expect(r.data['headers']['Content-Length'], contentLength.toString());

      final img = base64Encode(f.readAsBytesSync());
      expect(r.data['data'], img);
    },
    testOn: 'vm',
  );

  test(
    'file stream<Uint8List>',
    () async {
      final tmp = Directory.systemTemp.createTempSync('dio_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final f = File(p.join(tmp.path, 'flutter.png'));
      f.createSync();
      f.writeAsBytesSync(base64Decode(_flutterLogPngBase64));

      final contentLength = f.lengthSync();
      final r = await dio.put(
        '/put',
        data: f.readAsBytes().asStream(),
        options: Options(
          contentType: 'image/png',
          headers: {
            Headers.contentLengthHeader: contentLength,
          },
        ),
      );
      expect(r.data['headers']['Content-Length'], contentLength.toString());

      final img = base64Encode(f.readAsBytesSync());
      expect(r.data['data'], img);
    },
    testOn: 'vm',
  );

  test('send progress', () async {
    final data = ['aaaa', 'hello 😌', 'dio is a dart http client'];
    final stream = Stream.fromIterable(data.map((e) => e.codeUnits));
    final expanded = data.expand((element) => element.codeUnits);
    bool fullFilled = false;
    final _ = await dio.put(
      '/put',
      data: stream,
      onSendProgress: (a, b) {
        expect(b, expanded.length);
        expect(a <= b, isTrue);
        if (a == b) {
          fullFilled = true;
        }
      },
      options: Options(
        contentType: Headers.textPlainContentType,
        headers: {
          Headers.contentLengthHeader: expanded.length, // set content-length
        },
      ),
    );
    expect(fullFilled, isTrue);
  });
}

class _TestTransformer extends BackgroundTransformer {
  bool requestTransformed = false;

  @override
  Future<String> transformRequest(RequestOptions options) async {
    requestTransformed = true;
    return super.transformRequest(options);
  }
}

const _flutterLogPngBase64 =
    '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';
