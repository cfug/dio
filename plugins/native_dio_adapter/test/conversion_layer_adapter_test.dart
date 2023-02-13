import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:native_dio_adapter/src/conversion_layer_adapter.dart';
import 'package:test/test.dart';

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
}
