@TestOn('browser')
import 'dart:typed_data';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('download stream', () async {
    final browserAdapter = BrowserHttpClientAdapter();
    final opts = RequestOptions(
      method: 'POST',
    );
    final testStream = Stream.fromIterable(<Uint8List>[
      Uint8List.fromList([10, 1]),
      Uint8List.fromList([1, 4]),
      Uint8List.fromList([5, 1]),
      Uint8List.fromList([1, 1]),
      Uint8List.fromList([2, 4]),
    ]);
    final cancelFuture = opts.cancelToken?.whenCancel;

    final response = await browserAdapter.fetch(opts, testStream, cancelFuture);
    expect(await response.stream.length, 1);
  });
}
