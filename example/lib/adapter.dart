import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class MyAdapter implements HttpClientAdapter {
  final HttpClientAdapter _adapter = HttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    // hook requests to  google.com
    if (uri.host == 'google.com') {
      return ResponseBody.fromString('Too young too simple!', 200);
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

void main() async {
  final dio = Dio();
  dio.httpClientAdapter = MyAdapter();
  Response response = await dio.get('https://google.com');
  print(response);
  response = await dio.get('https://baidu.com');
  print(response);
}
