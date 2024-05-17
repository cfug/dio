@TestOn('browser')
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_browser_adapter/dio_browser_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

class BrowserHttpClientAdapter with BrowserHttpClientAdapterMixin {
  BrowserHttpClientAdapter({this.withCredentials = false});

  @override
  bool withCredentials;
}

void main() {
  test('with credentials', () async {
    final browserAdapter = BrowserHttpClientAdapter(withCredentials: true);
    final opts = RequestOptions();
    final testStream = Stream<Uint8List>.periodic(
      const Duration(seconds: 1),
      (x) => Uint8List(x),
    );
    final cancelFuture = opts.cancelToken?.whenCancel;

    browserAdapter.fetch(opts, testStream, cancelFuture);
    expect(browserAdapter.xhrs.every((e) => e.withCredentials == true), isTrue);
  });
}
