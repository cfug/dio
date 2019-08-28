import 'package:dio/dio.dart';

main() async {
  const String URL_NOT_FIND = "https://wendux.github.io/xxxxx/";
  const String URL_NOT_FIND_1 = URL_NOT_FIND + "1";
  const String URL_NOT_FIND_2 = URL_NOT_FIND + "2";
  const String URL_NOT_FIND_3 = URL_NOT_FIND + "3";
  Dio dio = Dio();
  dio.options.baseUrl = "http://httpbin.org/";
  dio.interceptors.add(InterceptorsWrapper(onResponse: (Response response) {
    return response.data["data"]; //
  }, onError: (DioError e) async {
    if (e.response != null) {
      switch (e.response.request.path) {
        case URL_NOT_FIND:
          return e;
        case URL_NOT_FIND_1:
          // you can also return a HttpError directly.
          return dio.resolve("fake data");
        case URL_NOT_FIND_2:
          return Response(data: "fake data");
        case URL_NOT_FIND_3:
          return 'custom error info [${e.response.statusCode}]';
      }
    }
    return e;
  }));

  Response response;
  response = await dio.get("/get");
  assert(response.data["headers"] is Map);
  try {
    await dio.get(URL_NOT_FIND);
  } catch (e) {
    assert(e.response.statusCode == 404);
  }
  response = await dio.get(URL_NOT_FIND + "1");
  assert(response.data == "fake data");
  response = await dio.get(URL_NOT_FIND + "2");
  assert(response.data == "fake data");
  try {
    await dio.get(URL_NOT_FIND + "3");
  } catch (e) {
    assert(e.message == 'custom error info [404]');
  }
}
