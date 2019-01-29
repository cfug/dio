import 'package:dio/dio.dart';

main() async {
  const String URL_NOT_FIND = "https://wendux.github.io/xxxxx/";
  const String URL_NOT_FIND_1 = URL_NOT_FIND + "1";
  const String URL_NOT_FIND_2 = URL_NOT_FIND + "2";
  const String URL_NOT_FIND_3 = URL_NOT_FIND + "3";
  Dio dio = new Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.interceptors.add(InterceptorsWrapper(
    onResponse: (Response response) {
      return response.data["data"]; //
    },
    onError: (DioError e) async {
      if (e.response != null) {
        switch (e.response.request.path) {
          case URL_NOT_FIND:
            return e;
          case URL_NOT_FIND_1:
            return dio.resolve(
                "fake data"); // you can also return a HttpError directly.
          case URL_NOT_FIND_2:
            return new Response(data: "fake data");
          case URL_NOT_FIND_3:
            return 'custom error info [${e.response.statusCode}]';
        }
      }
      return e;
    }
  ));

  Response response;
  response = await dio.get("/test");
  assert(response.data["path"] == "/test");
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
