import 'dart:async';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'mock_adapter.dart';
import 'echo_adapter.dart';

class MyInterceptor extends Interceptor {
  int requestCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requestCount++;
    return super.onRequest(options, handler);
  }
}

void main() {
  group('#test Request Interceptor', () {
    Dio dio;

    test('#test interceptor chain', () async {
      dio = Dio();
      dio.options.baseUrl = EchoAdapter.mockBase;
      dio.httpClientAdapter = EchoAdapter();
      dio.interceptors
        ..add(InterceptorsWrapper(
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
                handler.reject(DioError(requestOptions: reqOpt, error: 3));
                break;
              case '/reject-next':
                handler.reject(
                  DioError(requestOptions: reqOpt, error: 4),
                  true,
                );
                break;
              case '/reject-next/reject':
                handler.reject(
                  DioError(requestOptions: reqOpt, error: 5),
                  true,
                );
                break;
              case '/reject-next-response':
                handler.reject(
                  DioError(requestOptions: reqOpt, error: 5),
                  true,
                );
                break;
              default:
                handler.next(reqOpt); //continue
            }
          },
          onResponse: (response, ResponseInterceptorHandler handler) {
            var options = response.requestOptions;
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
                handler.reject(DioError(
                  requestOptions: options,
                  error: '/resolve-next/reject',
                ));
                break;
              case '/resolve-next/reject-next':
                handler.reject(
                  DioError(requestOptions: options, error: ''),
                  true,
                );
                break;
              default:
                handler.next(response); //continue
            }
          },
          onError: (err, handler) {
            if (err.requestOptions.path == '/reject-next-response') {
              handler.resolve(Response(
                requestOptions: err.requestOptions,
                data: 100,
              ));
            } else if (err.requestOptions.path == '/resolve-next/reject-next') {
              err.error = 1;
              handler.next(err);
            } else {
              if (err.requestOptions.path == '/reject-next/reject') {
                handler.reject(err);
              } else {
                err.error++;
                handler.next(err);
              }
            }
          },
        ))
        ..add(InterceptorsWrapper(
          onRequest: (options, handler) => handler.next(options),
          onResponse: (response, handler) {
            var options = response.requestOptions;
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
              err.error++;
              handler.next(err);
            } else {
              err.error++;
              handler.next(err);
            }
          },
        ));
      var response = await dio.get('/resolve');
      assert(response.data == 1);
      response = await dio.get('/resolve-next');

      assert(response.data == 3);

      response = await dio.get('/resolve-next/always');
      assert(response.data == 4);

      response = await dio.post('/post', data: 'xxx');
      assert(response.data == 'xxx');

      response = await dio.get('/reject-next-response');
      assert(response.data == 100);

      expect(
        dio.get('/reject').catchError((e) => throw e.error),
        throwsA(3),
      );

      expect(
        dio.get('/reject-next').catchError((e) => throw e.error),
        throwsA(6),
      );

      expect(
        dio.get('/reject-next/reject').catchError((e) => throw e.error),
        throwsA(5),
      );

      expect(
        dio.get('/resolve-next/reject').catchError((e) => throw e.error),
        throwsA('/resolve-next/reject'),
      );

      expect(
        dio.get('/resolve-next/reject-next').catchError((e) => throw e.error),
        throwsA(2),
      );
    });

    test('unexpected error', () async {
      var dio = Dio();
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
            err.error = 'unexpected error';
            handler.next(err);
          },
        ),
      );

      expect(
        dio.get('/error').catchError((e) => throw e.error),
        throwsA('unexpected error'),
      );

      expect(
        dio.get('/').then((e) => throw e.requestOptions.path),
        throwsA('/xxx'),
      );
    });

    test('#test request interceptor', () async {
      dio = Dio();
      dio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = MockAdapter();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (
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
                .catchError((e) => handler.reject(e));
            break;
          case '/fakepath3':
            handler.reject(DioError(
              requestOptions: options,
              error: 'test error',
            ));
            break;
          case '/fakepath4':
            handler.reject(DioError(
              requestOptions: options,
              error: 'test error',
            ));
            break;
          case '/test?tag=1':
            {
              dio.get('/token').then((response) {
                options.headers['token'] = response.data['data']['token'];
                handler.next(options);
              });
              break;
            }
          default:
            handler.next(options); //continue
        }
      }));

      var response = await dio.get('/fakepath1');
      expect(response.data, 'fake data');

      response = await dio.get('/fakepath2');
      expect(response.data['errCode'], 0);

      expect(
        dio.get('/fakepath3').catchError((e) => throw e.message),
        throwsA('test error'),
      );
      expect(
        dio.get('/fakepath4').catchError((e) => throw e.message),
        throwsA('test error'),
      );

      response = await dio.get('/test');
      expect(response.data['errCode'], 0);
      response = await dio.get('/test?tag=1');
      expect(response.data['errCode'], 0);
    });
  });

  group('#test response interceptor', () {
    Dio dio;
    test('#test Response Interceptor', () async {
      const URL_NOT_FIND = '/404/';
      const URL_NOT_FIND_1 = URL_NOT_FIND + '1';
      const URL_NOT_FIND_2 = URL_NOT_FIND + '2';
      const URL_NOT_FIND_3 = URL_NOT_FIND + '3';

      dio = Dio();
      dio.httpClientAdapter = MockAdapter();
      dio.options.baseUrl = MockAdapter.mockBase;

      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          response.data = response.data['data'];
          handler.next(response);
        },
        onError: (DioError e, ErrorInterceptorHandler handler) {
          if (e.response?.requestOptions != null) {
            switch (e.response!.requestOptions.path) {
              case URL_NOT_FIND:
                return handler.next(e);
              case URL_NOT_FIND_1:
                return handler.resolve(
                  Response(
                    requestOptions: e.requestOptions,
                    data: 'fake data',
                  ),
                );
              case URL_NOT_FIND_2:
                return handler.resolve(
                  Response(
                    data: 'fake data',
                    requestOptions: e.requestOptions,
                  ),
                );
              case URL_NOT_FIND_3:
                return handler.next(
                  e..error = 'custom error info [${e.response!.statusCode}]',
                );
            }
          }
          handler.next(e);
        },
      ));
      var response = await dio.get('/test');
      expect(response.data['path'], '/test');
      expect(
        dio.get(URL_NOT_FIND).catchError((e) => throw e.response.statusCode),
        throwsA(404),
      );
      response = await dio.get(URL_NOT_FIND + '1');
      expect(response.data, 'fake data');
      response = await dio.get(URL_NOT_FIND + '2');
      expect(response.data, 'fake data');
      expect(
        dio.get(URL_NOT_FIND + '3').catchError((e) => throw e.message),
        throwsA('custom error info [404]'),
      );
    });
    test('multi response interceptor', () async {
      dio = Dio();
      dio.httpClientAdapter = MockAdapter();
      dio.options.baseUrl = MockAdapter.mockBase;
      dio.interceptors
        ..add(InterceptorsWrapper(
          onResponse: (resp, handler) {
            resp.data = resp.data['data'];
            handler.next(resp);
          },
        ))
        ..add(InterceptorsWrapper(
          onResponse: (resp, handler) {
            resp.data['extra_1'] = 'extra';
            handler.next(resp);
          },
        ))
        ..add(InterceptorsWrapper(
          onResponse: (resp, handler) {
            resp.data['extra_2'] = 'extra';
            handler.next(resp);
          },
        ));
      final resp = await dio.get('/test');
      expect(resp.data['path'], '/test');
      expect(resp.data['extra_1'], 'extra');
      expect(resp.data['extra_2'], 'extra');
    });
  });
  group('Interceptor request lock', () {
    test('test request lock', () async {
      String? csrfToken;
      final dio = Dio();
      var tokenRequestCounts = 0;
      // dio instance to request token
      final tokenDio = Dio();
      dio.options.baseUrl = tokenDio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = tokenDio.httpClientAdapter = MockAdapter();
      var myInter = MyInterceptor();
      dio.interceptors.add(myInter);
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (csrfToken == null) {
            dio.lock();
            tokenRequestCounts++;
            tokenDio.get('/token').then((d) {
              options.headers['csrfToken'] =
                  csrfToken = d.data['data']['token'];
              handler.next(options);
            }).catchError((e) {
              handler.reject(e, true);
            }).whenComplete(() {
              dio.unlock();
            }); // unlock the dio
          } else {
            options.headers['csrfToken'] = csrfToken;
            handler.next(options);
          }
        },
      ));

      var result = 0;
      void _onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        dio.get('/test?tag=1').then(_onResult),
        dio.get('/test?tag=2').then(_onResult),
        dio.get('/test?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
      assert(myInter.requestCount > 0);
      dio.interceptors[0] = myInter;
      dio.interceptors.clear();
      assert(dio.interceptors.isEmpty == true);
    });
  });

  group('Interceptor error lock', () {
    test('test error lock', () async {
      String? csrfToken;
      final dio = Dio();
      var tokenRequestCounts = 0;
      // dio instance to request token
      final tokenDio = Dio();
      dio.options.baseUrl = tokenDio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = tokenDio.httpClientAdapter = MockAdapter();
      dio.interceptors.add(
        InterceptorsWrapper(
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
                    .catchError((e) => handler.reject(e));
                return;
              }
              // update token and repeat
              // Lock to block the incoming request until the token updated
              dio.lock();
              dio.interceptors.responseLock.lock();
              dio.interceptors.errorLock.lock();
              tokenRequestCounts++;
              tokenDio.get('/token').then((d) {
                //update csrfToken
                options.headers['csrfToken'] =
                    csrfToken = d.data['data']['token'];
              }).whenComplete(() {
                dio.unlock();
                dio.interceptors.responseLock.unlock();
                dio.interceptors.errorLock.unlock();
              }).then((e) {
                //repeat
                dio
                    .fetch(options)
                    .then(handler.resolve)
                    .catchError((e) => handler.reject(e));
              });
            } else {
              handler.next(error);
            }
          },
        ),
      );

      var result = 0;
      void _onResult(d) {
        if (tokenRequestCounts > 0) ++result;
      }

      await Future.wait([
        dio.get('/test-auth?tag=1').then(_onResult),
        dio.get('/test-auth?tag=2').then(_onResult),
        dio.get('/test-auth?tag=3').then(_onResult)
      ]);
      expect(tokenRequestCounts, 1);
      expect(result, 3);
    });
  });
}
