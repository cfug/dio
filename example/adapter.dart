import 'dart:async';
import 'package:dio/dio.dart';

class MyAdapter extends HttpClientAdapter {
  DefaultHttpClientAdapter defaultHttpClientAdapter =
      DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    Uri uri = options.uri;
    // hook requests to  google.com
    if (uri.host == "google.com") {
      return ResponseBody.fromString("Too young too simple!", 200);
    }
    return defaultHttpClientAdapter.fetch(options, requestStream, cancelFuture);
  }
}

main() async {
  var dio = new Dio();
  dio.httpClientAdapter = MyAdapter();
  Response response = await dio.get("https://google.com");
  print(response);
  response = await dio.get("https://baidu.com");
  print(response);
}
