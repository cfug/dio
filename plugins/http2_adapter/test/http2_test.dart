import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() {
  test('adds one to input values', () async {
    var dio = Dio()
      ..options.baseUrl = "https://www.ustc.edu.cn/"
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10,
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );

    Response<String> response;
    response = await dio.get("?xx=6");
    assert(response.statusCode == 200);
    response = await dio.get(
      "nkjnjknjn.html",
      options: Options(validateStatus: (status) => true),
    );
    assert(response.statusCode == 404);
  });

  test("request with payload", () async {
    final dio = Dio()
      ..options.baseUrl = "https://postman-echo.com/"
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: 10,
      ));

    final res = await dio.post("post", data: "TEST");
    assert(res.data["data"] == "TEST");
  });
}
