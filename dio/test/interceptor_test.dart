import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio/src/interceptors/imply_content_type.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

class MyInterceptor extends Interceptor {
  int requestCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requestCount++;
    return super.onRequest(options, handler);
  }
}

void main() {
  group('Request Interceptor', () {
    test('interceptor chain', () async {
      final dio = Dio();
      dio.options.baseUrl = EchoAdapter.mockBase;
      dio.httpClientAdapter = EchoAdapter();
      dio.interceptors
        ..add(
          InterceptorsWrapper(
            onRequest: (reqOpt, handler) {
              switch (reqOpt.path) {
                case '/resolve':
                  handler.resolve(Response(requestOptions: reqOpt, data: 1));
                  break;
                case '/resolve-next':
                  handler.resolve(
                    Response(requestOptions: reqOpt, data: 2),
                    true,
                  );
                  break;
                case '/resolve-next/always':
                  handler.resolve(
                    Response(requestOptions: reqOpt, data: 2),
                    true,
                  );
                  break;
                case '/resolve-next/reject':
                  handler.resolve(
                    Response(requestOptions: reqOpt, data: 2),
                    true,
                  );
                  break;
                case '/resolve-next/reject-next':
                  handler.resolve(
                    Response(requestOptions: reqOpt, data: 2),
                    true,
                  );
                  break;
                case '/reject':
                  handler
                      .reject(DioException(requestOptions: reqOpt, error: 3));
                  break;
                case '/reject-next':
                  handler.reject(
                    DioException(requestOptions: reqOpt, error: 4),
                    true,
                  );
                  break;
                case '/reject-next/reject':
                  handler.reject(
                    DioException(requestOptions: reqOpt, error: 5),
                    true,
                  );
                  break;
                case '/reject-next-response':
                  handler.reject(
                    DioException(requestOptions: reqOpt, error: 5),
                    true,
                  );
                  break;
                default:
                  handler.next(reqOpt); //continue
              }
            },
            onResponse: (response, ResponseInterceptorHandler handler) {
              final options = response.requestOptions;
              switch (options.path) {
                case '/resolve':
                  throw 'unexpected1';
                case '/resolve-next':
                  response.data++;
                  handler.resolve(response); //3
                  break;
                case '/resolve-next/always':
                  response.data++;
                  handler.next(response); //3
                  break;
                case '/resolve-next/reject':
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      error: '/resolve-next/reject',
                    ),
                  );
                  break;
                case '/resolve-next/reject-next':
                  handler.reject(
                    DioException(requestOptions: options, error: ''),
                    true,
                  );
                  break;
                default:
                  handler.next(response); //continue
              }
            },
            onError: (err, handler) {
              if (err.requestOptions.path == '/reject-next-response') {
                handler.resolve(
                  Response(
                    requestOptions: err.requestOptions,
                    data: 100,
                  ),
                );
              } else if (err.requestOptions.path ==
                  '/resolve-next/reject-next') {
                handler.next(err.copyWith(error: 1));
              } else {
                if (err.requestOptions.path == '/reject-next/reject') {
                  handler.reject(err);
                } else {
                  int count = err.error as int;
                  count++;
                  handler.next(err.copyWith(error: count));
                }
              }
            },
          ),
        )
        ..add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.next(options),
            onResponse: (response, handler) {
              final options = response.requestOptions;
              switch (options.path) {
                case '/resolve-next/always':
                  response.data++;
                  handler.next(response); //4
                  break;
                default:
                  handler.next(response); //continue
              }
            },
            onError: (err, handler) {
              if (err.requestOptions.path == '/resolve-next/reject-next') {
                int count = err.error as int;
                count++;
                handler.next(err.copyWith(error: count));
              } else {
                int count = err.error as int;
                count++;
                handler.next(err.copyWith(error: count));
              }
            },
          ),
        );
      Response response = await dio.get('/resolve');
      expect(response.data, 1);
      response = await dio.get('/resolve-next');

      expect(response.data, 3);

      response = await dio.get('/resolve-next/always');
      expect(response.data, 4);

      response = await dio.post('/post', data: 'xxx');
      expect(response.data, 'xxx');

      response = await dio.get('/reject-next-response');
      expect(response.data, 100);

      expect(
        dio.get('/reject').catchError((e) => throw e.error as num),
        throwsA(3),
      );

      expect(
        dio.get('/reject-next').catchError((e) => throw e.error as num),
        throwsA(6),
      );

      expect(
        dio.get('/reject-next/reject').catchError((e) => throw e.error as num),
        throwsA(5),
      );

      expect(
        dio
            .get('/resolve-next/reject')
            .catchError((e) => throw e.error as Object),
        throwsA('/resolve-next/reject'),
      );

      expect(
        dio
            .get('/resolve-next/reject-next')
            .catchError((e) => throw e.error as num),
        throwsA(2),
      );
    });

    test('unexpected error', () async {
      final dio = Dio();
      dio.options.baseUrl = EchoAdapter.mockBase;
      dio.httpClientAdapter = EchoAdapter();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (reqOpt, handler) {
            if (reqOpt.path == '/error') {
              throw 'unexpected';
            }
            handler.next(reqOpt.copyWith(path: '/xxx'));
          },
          onError: (err, handler) {
            handler.next(err.copyWith(error: 'unexpected error'));
          },
        ),
      );

      expect(
        dio.get('/error').catchError((e) => throw e.error as String),
        throwsA('unexpected error'),
      );

      expect(
        dio.get('/').then((e) => throw e.requestOptions.path),
        throwsA('/xxx'),
      );
    });

    test('request interceptor', () async {
      final dio = Dio();
      dio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = MockAdapter();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (
            RequestOptions options,
            RequestInterceptorHandler handler,
          ) {
            switch (options.path) {
              case '/fakepath1':
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: 'fake data',
                  ),
                );
                break;
              case '/fakepath2':
                dio
                    .get('/test')
                    .then(handler.resolve)
                    .catchError((e) => handler.reject(e as DioException));
                break;
              case '/fakepath3':
                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'test error',
                  ),
                );
                break;
              case '/fakepath4':
                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'test error',
                  ),
                );
                break;
              case '/test?tag=1':
                dio.get('/token').then((response) {
                  options.headers['token'] = response.data['data']['token'];
                  handler.next(options);
                });
                break;
              default:
                handler.next(options); //continue
            }
          },
        ),
      );

      Response response = await dio.get('/fakepath1');
      expect(response.data, 'fake data');

      response = await dio.get('/fakepath2');
      expect(response.data['errCode'], 0);

      expect(
        dio.get('/fakepath3'),
        throwsA(
          isA<DioException>()
              .having((e) => e.message, 'message', null)
              .having((e) => e.type, 'error type', DioExceptionType.unknown),
        ),
      );
      expect(
        dio.get('/fakepath4'),
        throwsA(
          isA<DioException>()
              .having((e) => e.message, 'message', null)
              .having((e) => e.type, 'error type', DioExceptionType.unknown),
        ),
      );

      response = await dio.get('/test');
      expect(response.data['errCode'], 0);
      response = await dio.get('/test?tag=1');
      expect(response.data['errCode'], 0);
    });

    group(ImplyContentTypeInterceptor, () {
      Dio createDio() {
        final dio = Dio();
        dio.options.baseUrl = EchoAdapter.mockBase;
        dio.httpClientAdapter = EchoAdapter();
        return dio;
      }

      test('is enabled by default', () async {
        final dio = createDio();
        expect(
          dio.interceptors.whereType<ImplyContentTypeInterceptor>(),
          isNotEmpty,
        );
      });

      test('can be removed with the helper method', () async {
        final dio = createDio();
        dio.interceptors.removeImplyContentTypeInterceptor();
        expect(
          dio.interceptors.whereType<ImplyContentTypeInterceptor>(),
          isEmpty,
        );
      });

      test('ignores null data', () async {
        final dio = createDio();
        final response = await dio.get('/echo');
        expect(response.requestOptions.contentType, isNull);
      });

      test('does not override existing content type', () async {
        final dio = createDio();
        final response = await dio.get(
          '/echo',
          data: 'hello',
          options: Options(headers: {'Content-Type': 'text/plain'}),
        );
        expect(response.requestOptions.contentType, 'text/plain');
      });

      test('ignores unsupported data type', () async {
        final dio = createDio();
        final response = await dio.get('/echo', data: 42);
        expect(response.requestOptions.contentType, isNull);
      });

      test('sets application/json for String instances', () async {
        final dio = createDio();
        final response = await dio.get('/echo', data: 'hello');
        expect(response.requestOptions.contentType, 'application/json');
      });

      test('sets application/json for Map instances', () async {
        final dio = createDio();
        final response = await dio.get('/echo', data: {'hello': 'there'});
        expect(response.requestOptions.contentType, 'application/json');
      });

      test('sets application/json for List<Map> instances', () async {
        final dio = createDio();
        final response = await dio.get(
          '/echo',
          data: [
            {'hello': 'here'},
            {'hello': 'there'}
          ],
        );
        expect(response.requestOptions.contentType, 'application/json');
      });

      test('sets multipart/form-data for FormData instances', () async {
        final dio = createDio();
        final response = await dio.get(
          '/echo',
          data: FormData.fromMap({'hello': 'there'}),
        );
        expect(
          response.requestOptions.contentType?.split(';').first,
          'multipart/form-data',
        );
      });
    });
  });

  group('response interceptor', () {
    Dio dio;
    test('Response Interceptor', () async {
      const urlNotFound = '/404/';
      const urlNotFound1 = '${urlNotFound}1';
      const urlNotFound2 = '${urlNotFound}2';
      const urlNotFound3 = '${urlNotFound}3';

      dio = Dio();
      dio.httpClientAdapter = MockAdapter();
      dio.options.baseUrl = MockAdapter.mockBase;

      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            response.data = response.data['data'];
            handler.next(response);
          },
          onError: (DioException e, ErrorInterceptorHandler handler) {
            if (e.response?.requestOptions != null) {
              switch (e.response!.requestOptions.path) {
                case urlNotFound:
                  return handler.next(e);
                case urlNotFound1:
                  return handler.resolve(
                    Response(
                      requestOptions: e.requestOptions,
                      data: 'fake data',
                    ),
                  );
                case urlNotFound2:
                  return handler.resolve(
                    Response(
                      data: 'fake data',
                      requestOptions: e.requestOptions,
                    ),
                  );
                case urlNotFound3:
                  return handler.next(
                    e.copyWith(
                      error: 'custom error info [${e.response!.statusCode}]',
                    ),
                  );
              }
            }
            handler.next(e);
          },
        ),
      );
      Response response = await dio.get('/test');
      expect(response.data['path'], '/test');
      expect(
        dio
            .get(urlNotFound)
            .catchError((e) => throw (e as DioException).response!.statusCode!),
        throwsA(404),
      );
      response = await dio.get('${urlNotFound}1');
      expect(response.data, 'fake data');
      response = await dio.get('${urlNotFound}2');
      expect(response.data, 'fake data');
      expect(
        dio.get('${urlNotFound}3').catchError((e) => throw e as DioException),
        throwsA(isA<DioException>()),
      );
    });
    test('multi response interceptor', () async {
      dio = Dio();
      dio.httpClientAdapter = MockAdapter();
      dio.options.baseUrl = MockAdapter.mockBase;
      dio.interceptors
        ..add(
          InterceptorsWrapper(
            onResponse: (resp, handler) {
              resp.data = resp.data['data'];
              handler.next(resp);
            },
          ),
        )
        ..add(
          InterceptorsWrapper(
            onResponse: (resp, handler) {
              resp.data['extra_1'] = 'extra';
              handler.next(resp);
            },
          ),
        )
        ..add(
          InterceptorsWrapper(
            onResponse: (resp, handler) {
              resp.data['extra_2'] = 'extra';
              handler.next(resp);
            },
          ),
        );
      final resp = await dio.get('/test');
      expect(resp.data['path'], '/test');
      expect(resp.data['extra_1'], 'extra');
      expect(resp.data['extra_2'], 'extra');
    });
  });

  group('Error Interceptor', () {
    test('handled when request cancelled', () async {
      final cancelToken = CancelToken();
      DioException? iError, qError;
      final dio = Dio()
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase
        ..interceptors.add(
          InterceptorsWrapper(
            onError: (DioException e, ErrorInterceptorHandler handler) {
              iError = e;
              handler.next(e);
            },
          ),
        )
        ..interceptors.add(
          QueuedInterceptorsWrapper(
            onError: (DioException e, ErrorInterceptorHandler handler) {
              qError = e;
              handler.next(e);
            },
          ),
        );
      Future.delayed(const Duration(seconds: 1)).then((_) {
        cancelToken.cancel('test');
      });
      await dio
          .get('/test-timeout', cancelToken: cancelToken)
          .then((_) {}, onError: (_) {});
      expect(iError, isA<DioException>());
      expect(qError, isA<DioException>());
    });
  });

  group('QueuedInterceptor', () {
    test('requests ', () async {
      String? csrfToken;
      final dio = Dio();
      int tokenRequestCounts = 0;
      // dio instance to request token
      final tokenDio = Dio();
      dio.options.baseUrl = tokenDio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = tokenDio.httpClientAdapter = MockAdapter();
      final myInter = MyInterceptor();
      dio.interceptors.add(myInter);
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            if (csrfToken == null) {
              tokenRequestCounts++;
              tokenDio.get('/token').then((d) {
                options.headers['csrfToken'] =
                    csrfToken = d.data['data']['token'] as String;
                handler.next(options);
              }).catchError((e) {
                handler.reject(e as DioException, true);
              });
            } else {
              options.headers['csrfToken'] = csrfToken;
              handler.next(options);
            }
          },
        ),
      );

      int result = 0;
      void onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        dio.get('/test?tag=1').then(onResult),
        dio.get('/test?tag=2').then(onResult),
        dio.get('/test?tag=3').then(onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
      expect(myInter.requestCount, predicate((int e) => e > 0));
      dio.interceptors[0] = myInter;
      dio.interceptors.clear();
      expect(dio.interceptors.isEmpty, true);
    });

    test('error', () async {
      String? csrfToken;
      final dio = Dio();
      int tokenRequestCounts = 0;
      // dio instance to request token
      final tokenDio = Dio();
      dio.options.baseUrl = tokenDio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = tokenDio.httpClientAdapter = MockAdapter();
      dio.interceptors.add(
        QueuedInterceptorsWrapper(
          onRequest: (opt, handler) {
            opt.headers['csrfToken'] = csrfToken;
            handler.next(opt);
          },
          onError: (error, handler) {
            // Assume 401 stands for token expired
            if (error.response?.statusCode == 401) {
              final options = error.response!.requestOptions;
              // If the token has been updated, repeat directly.
              if (csrfToken != options.headers['csrfToken']) {
                options.headers['csrfToken'] = csrfToken;
                //repeat
                dio
                    .fetch(options)
                    .then(handler.resolve)
                    .catchError((e) => handler.reject(e as DioException));
                return;
              }
              // update token and repeat
              tokenRequestCounts++;
              tokenDio.get('/token').then((d) {
                //update csrfToken
                options.headers['csrfToken'] =
                    csrfToken = d.data['data']['token'] as String;
              }).then((e) {
                //repeat
                dio
                    .fetch(options)
                    .then(handler.resolve)
                    .catchError((e) => handler.reject(e as DioException));
              });
            } else {
              handler.next(error);
            }
          },
        ),
      );

      int result = 0;
      void onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        dio.get('/test-auth?tag=1').then(onResult),
        dio.get('/test-auth?tag=2').then(onResult),
        dio.get('/test-auth?tag=3').then(onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
    });
  });

  test('Size of Interceptors', () {
    final interceptors = Dio().interceptors;
    expect(interceptors.length, equals(1));
    expect(interceptors, isNotEmpty);
    interceptors.add(InterceptorsWrapper());
    expect(interceptors.length, equals(2));
    expect(interceptors, isNotEmpty);
    interceptors.clear();
    expect(interceptors.length, equals(0));
    expect(interceptors, isEmpty);
  });
}
