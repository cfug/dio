import 'package:dio/dio.dart';

void main() async {
  var dio = Dio();
  dio.options.baseUrl = 'http://httpbin.org/';
  dio.options.connectTimeout = 5000;
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
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
          DioError(
            requestOptions: options,
            error: 'test error',
          ),
        );
      default:
        return handler.next(options); //continue
    }
  }));
  Response response;
  response = await dio.get('/fakepath1');
  assert(response.data == 'fake data');
  response = await dio.get('/fakepath2');
  assert(response.data['headers'] is Map);
  try {
    response = await dio.get('/fakepath3');
  } on DioError catch (e) {
    print(1);
    assert(e.message == 'test error');
    assert(e.response == null);
  }
  response = await dio.get('/get');
  assert(response.data['headers'] is Map);
  try {
    await dio.get('xsddddd');
  } on DioError catch (e) {
    assert(e.response!.statusCode == 404);
  }
}
