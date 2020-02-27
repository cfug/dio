import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'mock_adapter.dart';

class MyInterceptor extends Interceptor {
  int requestCount = 0;

  @override
  Future onRequest(RequestOptions options) {
    requestCount++;
    return super.onRequest(options);
  }
}

void main() {
  group('#test Request Interceptor', () {
    Dio dio;

    test('#test request interceptor', () async {
      dio = Dio();
      dio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = MockAdapter();
      dio.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) async {
        switch (options.path) {
          case '/fakepath1':
            return dio.resolve('fake data');
          case '/fakepath2':
            return dio.get('/test');
          case '/fakepath3':
            return dio.reject(
                'test error'); //you can also return a HttpError directly.
          case '/fakepath4':
            return DioError(
                error:
                    'test error'); // Here is equivalent to call dio.reject('test error')
          case '/test?tag=1':
            {
              Response response = await dio.get('/token');
              options.headers['token'] = response.data['data']['token'];
              return options;
            }
          default:
            return options; //continue
        }
      }));

      Response response = await dio.get('/fakepath1');
      expect(response.data, 'fake data');
      response = await dio.get('/fakepath2');
      expect(response.data['errCode'], 0);

      expect(dio.get('/fakepath3').catchError((e) => throw e.message),
          throwsA(equals('test error')));
      expect(dio.get('/fakepath4').catchError((e) => throw e.message),
          throwsA(equals('test error')));

      response = await dio.get('/test');
      expect(response.data['errCode'], 0);
      response = await dio.get('/test?tag=1');
      expect(response.data['errCode'], 0);
    });
  });

  test('#test Response Interceptor', () async {
    Dio dio;

    const String URL_NOT_FIND = '/404/';
    const String URL_NOT_FIND_1 = URL_NOT_FIND + '1';
    const String URL_NOT_FIND_2 = URL_NOT_FIND + '2';
    const String URL_NOT_FIND_3 = URL_NOT_FIND + '3';

    dio = Dio();
    dio.httpClientAdapter = MockAdapter();
    dio.options.baseUrl = MockAdapter.mockBase;

    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (Response response) {
        return response.data['data'];
      },
      onError: (e) {
        if (e.response != null) {
          switch (e.response.request.path) {
            case URL_NOT_FIND:
              return e;
            case URL_NOT_FIND_1:
              return dio.resolve(
                  'fake data'); // you can also return a HttpError directly.
            case URL_NOT_FIND_2:
              return Response(data: 'fake data');
            case URL_NOT_FIND_3:
              return 'custom error info [${e.response.statusCode}]';
          }
        }
        return e;
      },
    ));
    Response response = await dio.get('/test');
    expect(response.data['path'], '/test');
    expect(dio.get(URL_NOT_FIND).catchError((e) => throw e.response.statusCode),
        throwsA(equals(404)));
    response = await dio.get(URL_NOT_FIND + '1');
    expect(response.data, 'fake data');
    response = await dio.get(URL_NOT_FIND + '2');
    expect(response.data, 'fake data');
    expect(dio.get(URL_NOT_FIND + '3').catchError((e) => throw e.message),
        throwsA(equals('custom error info [404]')));
  });

  group('Interceptor lock', () {
    test('test', () async {
      String csrfToken;
      Dio dio = Dio();
      int tokenRequestCounts = 0;
      // dio instance to request token
      Dio tokenDio = Dio();
      dio.options.baseUrl = tokenDio.options.baseUrl = MockAdapter.mockBase;
      dio.httpClientAdapter = tokenDio.httpClientAdapter = MockAdapter();
      var myInter = MyInterceptor();
      dio.interceptors.add(myInter);
      dio.interceptors
          .add(InterceptorsWrapper(onRequest: (RequestOptions options) {
        if (csrfToken == null) {
          dio.lock();
          tokenRequestCounts++;
          return tokenDio.get('/token').then((d) {
            options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
            return options;
          }).whenComplete(() => dio.unlock()); // unlock the dio
        } else {
          options.headers['csrfToken'] = csrfToken;
          return options;
        }
      }));

      int result = 0;
      _onResult(d) {
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
}
