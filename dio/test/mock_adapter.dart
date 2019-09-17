import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

class MockAdapter extends HttpClientAdapter {
  static const String mockHost = "mockserver";
  static const String mockBase = "http://$mockHost";
  DefaultHttpClientAdapter _adapter =
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
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        case "/download":
          return ResponseBody(
            File("./README.md").openRead(),
            200,
            headers: {
              Headers.contentLengthHeader: [File("./README.md").lengthSync().toString()],
            },
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
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
        default:
          return ResponseBody.fromString("", 404);
      }
    }
    return _adapter.fetch(
        options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
