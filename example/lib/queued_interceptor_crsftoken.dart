import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

void main() async {
  var dio = Dio();
  dio.httpClientAdapter = _MockAdapter();
  //  dio instance to request token
  dio.options.baseUrl = 'http://www.dtworkroom.com/doris/1/2.0.0/';
  dio.interceptors.add(false //
      ? LockTokenInterceptor(dio)
      : QueueTokenInterceptor(dio));

  await Future.wait([
    _log(dio.get('test?tag=1')),
    _log(dio.get('test?tag=2')),
    _log(dio.get('test?tag=3')),
  ]);
}

Future<void> _log<T>(Future<T> future) {
  return future.then<T?>((value) {
    print('request ok!: $value');
    return value;
  }).catchError((e, st) {
    print('request error: $e');
  });
}

String? csrfToken;

/// @see [Interceptors.requestLock]
/// @see [QueueTokenInterceptor]
@Deprecated('use QueueTokenInterceptor instead.')
class LockTokenInterceptor extends Interceptor {
  LockTokenInterceptor(this.dio) {
    tokenDio = Dio()
      ..options = dio.options
      ..httpClientAdapter = dio.httpClientAdapter;
  }
  final Dio dio;
  late final Dio tokenDio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('send request：path:${options.path}，baseURL:${options.baseUrl}');
    if (csrfToken == null) {
      print('no token，request token firstly...');
      dio.lock();
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
      ).whenComplete(() {
        dio.unlock();
      });
    } else {
      options.headers['csrfToken'] = csrfToken;
      return handler.next(options);
    }
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) {
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

      dio.lock();
      dio.interceptors.responseLock.lock();
      dio.interceptors.errorLock.lock();

      tokenDio.get('/token').then((d) {
        //update csrfToken
        options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
      }).whenComplete(() {
        dio.unlock();
        dio.interceptors.responseLock.unlock();
        dio.interceptors.errorLock.unlock();
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
  }
}

class QueueTokenInterceptor extends QueuedInterceptor {
  QueueTokenInterceptor(Dio dio) {
    tokenDio = Dio()
      ..options = dio.options
      ..httpClientAdapter = dio.httpClientAdapter;
  }
  late final Dio tokenDio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) {
    //print(error);
    // Assume 401 stands for token expired
    if (error.response?.statusCode == 401) {
      var options = error.response!.requestOptions;
      // If the token has been updated, repeat directly.
      if (csrfToken != options.headers['csrfToken']) {
        options.headers['csrfToken'] = csrfToken;
        //repeat
        tokenDio.fetch(options).then(
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
        //repeat, The current dio has been blocked and needs to be re-requested using another instance.
        tokenDio.fetch(options).then(
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
  }
}

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
