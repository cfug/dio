import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

void main() async {
  var dio = Dio();
  //  dio instance to request token
  var tokenDio = Dio();
  dio.options.baseUrl = 'http://www.dtworkroom.com/doris/1/2.0.0/';
  tokenDio.options = dio.options;
  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) {
      print('send request：path:${options.path}，baseURL:${options.baseUrl}');
      if (csrfToken == null) {
        print('no token，request token firstly...');
        tokenDio.get('/token').then((d) {
          options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
          print('request token succeed, value: ' + d.data['data']['token']);
          print(
              'continue to perform request：path:${options.path}，baseURL:${options.path}');
          handler.next(options);
        }).catchError(
          (error, stackTrace) {
            handler.reject(error, true);
          },
          test: (e) => e is DioError,
        );
      } else {
        options.headers['csrfToken'] = csrfToken;
        return handler.next(options);
      }
    },
    onError: (error, handler) {
      //print(error);
      // Assume 401 stands for token expired
      if (error.response?.statusCode == 401) {
        var options = error.response!.requestOptions;
        // If the token has been updated, repeat directly.
        if (csrfToken != options.headers['csrfToken']) {
          options.headers['csrfToken'] = csrfToken;
          //repeat
          dio.fetch(options).then(
            (r) {
              handler.resolve(r);
            },
            onError: (e) {
              handler.reject(e);
            },
          );
          return;
        }
        tokenDio.get('/token').then((d) {
          //update csrfToken
          options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
        }).then((e) {
          //repeat
          dio.fetch(options).then(
            (r) {
              handler.resolve(r);
            },
            onError: (e) {
              handler.reject(e);
            },
          );
        });
        return;
      }
      return handler.next(error);
    },
  ));

  FutureOr<void> _onResult(d) {
    print('request ok!: $d');
  }

  dio.httpClientAdapter = tokenDio.httpClientAdapter = _MockAdapter();

  await Future.wait([
    dio.get('test?tag=1').then(_onResult),
    dio.get('test?tag=2').then(_onResult),
    dio.get('test?tag=3').then(_onResult),
  ]);
}

String? csrfToken;

final _kRandom = Random(0);

var _tag2InvokeCount = 0;

class _MockAdapter extends HttpClientAdapter {
  ResponseBody jsonBody(Object? obj) {
    return ResponseBody.fromString(
      jsonEncode(obj),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    final relativePath =
        options.uri.path.substring(Uri.parse(options.baseUrl).path.length);
    print([
      '[mock]',
      'uri: ${options.uri},',
      'path: $relativePath,',
    ].join(' '));

    await Future.delayed(Duration(milliseconds: _kRandom.nextInt(1000)));

    switch (relativePath) {
      case 'token':
        return jsonBody({
          'data': {'token': 'mock-token'}
        });
      case 'test':
        final tag = options.uri.queryParameters['tag'];
        final isTag2 = tag == '2';
        if (isTag2) {
          switch (++_tag2InvokeCount) {
            case 1:
              return ResponseBody.fromString('', 401);
            case 2:
              return ResponseBody.fromString('', 500);
          }
        }
        return jsonBody({
          'data': {
            'tag': tag,
            if (isTag2) 'count': _tag2InvokeCount,
          }
        });
    }
    return ResponseBody.fromString('text', 404);
  }

  @override
  void close({bool force = false}) {}
}
