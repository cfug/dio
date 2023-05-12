import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  group(HttpClientAdapter, () {
    test(
        'IOHttpClientAdapter.onHttpClientCreate is only executed once per request',
        () async {
      int onHttpClientCreateInvokeCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = IOHttpClientAdapter(onHttpClientCreate: (client) {
        onHttpClientCreateInvokeCount++;
        return client;
      });
      await dio.get('https://pub.dev');
      expect(onHttpClientCreateInvokeCount <= 1, isTrue);
    });
  });
}
