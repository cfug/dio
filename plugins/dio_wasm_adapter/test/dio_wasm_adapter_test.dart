@TestOn('browser')
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_wasm_adapter/dio_wasm_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('with credentials', () async {
    final wasmAdapter = WasmHttpClientAdapter(withCredentials: true);
    final opts = RequestOptions();
    final testStream = Stream<Uint8List>.periodic(
      const Duration(seconds: 1),
      (x) => Uint8List(x),
    );
    final cancelFuture = opts.cancelToken?.whenCancel;

    wasmAdapter.fetch(opts, testStream, cancelFuture);
    expect(wasmAdapter.xhrs.every((e) => e.withCredentials == true), isTrue);
  });
}
