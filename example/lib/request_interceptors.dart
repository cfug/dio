import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  dio.options.baseUrl = 'https://httpbin.org/';
  dio.options.connectTimeout = Duration(seconds: 5);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        switch (options.path) {
          case '/fakepath1':
            return handler.resolve(
              Response(
                requestOptions: options,
                data: 'fake data',
              ),
            );
          case '/fakepath2':
            dio
                .get('/get')
                .then(handler.resolve)
                .catchError((e) => handler.reject(e));
            break;
          case '/fakepath3':
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'test error',
              ),
            );
          default:
            return handler.next(options); //continue
        }
      },
    ),
  );
  Response response;
  response = await dio.get('/fakepath1');
  assert(response.data == 'fake data');
  response = await dio.get('/fakepath2');
  assert(response.data['headers'] is Map);
  try {
    response = await dio.get('/fakepath3');
  } on DioException catch (e) {
    assert(e.message == 'test error');
    assert(e.response == null);
  }
  response = await dio.get('/get');
  assert(response.data['headers'] is Map);
  try {
    await dio.get('/status/404');
  } on DioException catch (e) {
    assert(e.response!.statusCode == 404);
  }
}
