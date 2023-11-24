@TestOn('vm')
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.com/';
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: Duration(seconds: 30)),
    );
  });

  test('catch DioException when connectTimeout', () {
    dio.options.connectTimeout = Duration(milliseconds: 3);

    expectLater(
      dio.get('/drip-lines?delay=2'),
      allOf(
        throwsA(isA<DioException>()),
        throwsA(predicate((DioException e) =>
            e.type == DioExceptionType.connectionTimeout &&
            e.message!.contains('0:00:00.003000'))),
      ),
    );
  });

  test('catch DioException when receiveTimeout', () {
    dio.options.receiveTimeout = Duration(milliseconds: 10);

    expectLater(
      dio.get(
        '/bytes/${1024 * 1024 * 20}',
        options: Options(responseType: ResponseType.stream),
      ),
      allOf([
        throwsA(isA<DioException>()),
        throwsA(
          predicate<DioException>(
            (e) => e.type == DioExceptionType.receiveTimeout,
          ),
        ),
        throwsA(
          predicate<DioException>((e) => e.message!.contains('0:00:00.010000')),
        ),
      ]),
    );
  });
}
