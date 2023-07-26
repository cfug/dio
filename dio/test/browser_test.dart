@TestOn('browser')
import 'dart:typed_data';

import 'package:w_dio/browser.dart';
import 'package:w_dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('with credentials', () async {
    final browserAdapter = BrowserHttpClientAdapter(withCredentials: true);
    final opts = RequestOptions();
    final testStream = Stream<Uint8List>.periodic(
      Duration(seconds: 1),
      (x) => Uint8List(x),
    );
    final cancelFuture = opts.cancelToken?.whenCancel;

    browserAdapter.fetch(opts, testStream, cancelFuture);
    expect(browserAdapter.xhrs.every((e) => e.withCredentials == true), isTrue);
  });
}
