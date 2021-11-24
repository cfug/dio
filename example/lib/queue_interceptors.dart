import 'package:dio/dio.dart';

void main() async {
  var dio = Dio();
  dio.options.baseUrl = 'http://httpbin.org/status/';
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (
        RequestOptions requestOptions,
        RequestInterceptorHandler handler,
      ) {
        print(requestOptions.uri);
        Future.delayed(Duration(seconds: 2), () {
          handler.next(requestOptions);
        });
      },
    ),
  );
  print(
      'All of the requests enter the interceptor at once, rather than executing sequentially.');
  await makeRequests(dio);
  print(
      'All of the requests enter the interceptor sequentially by QueuedInterceptors');
  dio.interceptors
    ..clear()
    ..add(
      QueuedInterceptorsWrapper(
        onRequest: (
          RequestOptions requestOptions,
          RequestInterceptorHandler handler,
        ) {
          print(requestOptions.uri);
          Future.delayed(Duration(seconds: 2), () {
            handler.next(requestOptions);
          });
        },
      ),
    );
  await makeRequests(dio);
}

Future makeRequests(Dio dio) async {
  try {
    await Future.wait([
      dio.get('/200'),
      dio.get('/201'),
      dio.get('/201'),
    ]);
  } catch (e) {
    print(e);
  }
}
