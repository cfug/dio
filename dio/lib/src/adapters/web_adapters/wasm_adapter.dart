import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../dio/dio_for_browser.dart';

final _err = UnsupportedError(
  'If you want to build with WASM, Please see package [dio_wasm_adapter].',
);

HttpClientAdapter createWebAdapter() => _WasmHttpClientAdapter();

/// Empty [HttpClientAdapter]'s implements for WASM.
///
/// **Why we need this?** We want to create a [DioForBrowser] for WASM, but
/// we need to use conditionally import to avoid `dart:html` be dependent
/// when compile-time.
class _WasmHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {
    throw _err;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw _err;
  }
}
