import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

class MyAdapter extends HttpClientAdapter {
  DefaultHttpClientAdapter _adapter = DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    Uri uri = options.uri;
    // hook requests to  google.com
    if (uri.host == "google.com") {
      return ResponseBody.fromString("Too young too simple!", 200);
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

main() async {
  var dio = Dio();
  dio.httpClientAdapter = MyAdapter();
  Response response = await dio.get("https://google.com");
  print(response);
  response = await dio.get("https://baidu.com");
  print(response);
}
