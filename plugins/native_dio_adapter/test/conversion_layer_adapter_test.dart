import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:native_dio_adapter/src/conversion_layer_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'client_mock.dart';

void main() {
  test('close', () {
    final mock = CloseClientMock();
    final cla = ConversionLayerAdapter(mock);

    cla.close();

    expect(mock.closeWasCalled, true);
  });

  test('close with force', () {
    final mock = CloseClientMock();
    final cla = ConversionLayerAdapter(mock);

    cla.close(force: true);

    expect(mock.closeWasCalled, true);
  });

  test('headers', () async {
    final mock = ClientMock()..response = StreamedResponse(Stream.empty(), 200);
    final cla = ConversionLayerAdapter(mock);

    await cla.fetch(
      RequestOptions(path: '', headers: {'foo': 'bar'}),
      Stream.empty(),
      null,
    );

    expect(mock.request?.headers, {'foo': 'bar'});
  });

  test('download stream', () async {
    final mock = ClientMock()
      ..response = StreamedResponse(
          Stream.fromIterable(<Uint8List>[
            Uint8List.fromList([10, 1]),
            Uint8List.fromList([1, 4]),
            Uint8List.fromList([5, 1]),
            Uint8List.fromList([1, 1]),
            Uint8List.fromList([2, 4]),
          ]),
          200);
    final cla = ConversionLayerAdapter(mock);

    final resp = await cla.fetch(
      RequestOptions(path: ''),
      null,
      null,
    );

    expect(await resp.stream.length, 5);
  });
}
