import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  final dio = Dio();
  dio.options.baseUrl = 'https://httpbin.org/';
  test('stream', () async {
    Response r;
    const str = 'hello 😌';
    final bytes = utf8.encode(str).toList();
    final stream = Stream.fromIterable(bytes.map((e) => [e]));
    r = await dio.put(
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

  test('file stream', () async {
    final f = File('../dio/test/test.jpg');
    final r = await dio.put(
      '/put',
      data: f.openRead(),
      options: Options(
        contentType: 'image/jpeg',
        headers: {
          Headers.contentLengthHeader: f.lengthSync(), // set content-length
        },
      ),
    );
    final img = base64Encode(f.readAsBytesSync());
    expect(r.data['data'], 'data:application/octet-stream;base64,$img');
  }, testOn: "vm");

  test('file stream<Uint8List>', () async {
    final f = File('../dio/test/test.jpg');
    final r = await dio.put(
      '/put',
      data: f.readAsBytes().asStream(),
      options: Options(
        contentType: 'image/jpeg',
        headers: {
          Headers.contentLengthHeader: f.lengthSync(), // set content-length
        },
      ),
    );
    final img = base64Encode(f.readAsBytesSync());
    expect(r.data['data'], 'data:application/octet-stream;base64,$img');
  }, testOn: "vm");
}
