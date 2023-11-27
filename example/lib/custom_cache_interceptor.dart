import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  final _cache = <Uri, Response>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final response = _cache[options.uri];
    if (options.extra['refresh'] == true) {
      print('${options.uri}: force refresh, ignore cache! \n');
      return handler.next(options);
    } else if (response != null) {
      print('cache hit: ${options.uri} \n');
      return handler.resolve(response);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _cache[response.requestOptions.uri] = response;
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    print('onError: $error');
    super.onError(error, handler);
  }
}

void main() async {
  final dio = Dio();
  dio.options.baseUrl = 'https://pub.dev';
  dio.interceptors
    ..add(CacheInterceptor())
    ..add(LogInterceptor(requestHeader: false, responseHeader: false));

  await dio.get('/'); // second request
  await dio.get('/'); // Will hit cache
  // Force refresh
  await dio.get('/', options: Options(extra: {'refresh': true}));
}
