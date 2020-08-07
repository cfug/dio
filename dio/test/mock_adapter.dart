import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

class MockAdapter extends HttpClientAdapter {
  static const String mockHost = "mockserver";
  static const String mockBase = "http://$mockHost";
  DefaultHttpClientAdapter _adapter = DefaultHttpClientAdapter();

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
          break;
        case "/test-auth":
          {
            return Future.delayed(Duration(milliseconds: 300), () {
              if (options.headers['csrfToken'] == null) {
                return ResponseBody.fromString(
                  jsonEncode({
                    "errCode": -1,
                    "data": {"path": uri.path}
                  }),
                  401,
                  headers: {
                    Headers.contentTypeHeader: [Headers.jsonContentType],
                  },
                );
              }
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
            });
          }
          break;
        case "/download":
          return Future.delayed(Duration(milliseconds: 300), () {
            return ResponseBody(
              File("./README.md").openRead().cast<Uint8List>(),
              200,
              headers: {
                Headers.contentLengthHeader: [
                  File("./README.md").lengthSync().toString()
                ],
              },
            );
          });
          break;

        case "/token":
          {
            var t = "ABCDEFGHIJKLMN".split("")..shuffle();
            return ResponseBody.fromBytes(
              utf8.encode(jsonEncode({
                "errCode": 0,
                "data": {"token": t.join()}
              })),
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
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
