import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class MockAdapter extends HttpClientAdapter {
  static const String mockHost = "mockserver";
  static const String mockBase = "http://$mockHost";
  DefaultHttpClientAdapter _defaultHttpClientAdapter =
      DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>> requestStream, Future cancelFuture) async {
    Uri uri = options.uri;
    if (uri.host == mockHost) {
      switch (uri.path) {
        case "/test":
          return ResponseBody.fromString(
            jsonEncode({
              "errCode": 0,
              "data": {"path": uri.path}
            }),
            200,
            headers: DioHttpHeaders.fromMap({
              HttpHeaders.contentTypeHeader: ContentType.json,
            }),
          );
        case "/download":
          return ResponseBody(
            File("./README.md").openRead(),
            200,
            headers: DioHttpHeaders.fromMap({
              HttpHeaders.contentLengthHeader: File("./README.md").lengthSync(),
            }),
          );

        case "/token":
          {
            var t = "ABCDEFGHIJKLMN".split("")..shuffle();
            return ResponseBody.fromString(
              jsonEncode({
                "errCode": 0,
                "data": {"token": t.join()}
              }),
              200,
              headers: DioHttpHeaders.fromMap({
                HttpHeaders.contentTypeHeader: ContentType.json,
              }),
            );
          }
        default:
          return ResponseBody.fromString("", 404, headers: DioHttpHeaders());
      }
    }
    return _defaultHttpClientAdapter.fetch(
        options, requestStream, cancelFuture);
  }
}
