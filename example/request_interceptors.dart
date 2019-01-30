import 'package:dio/dio.dart';

main() async {
  Dio dio = new Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (RequestOptions options){
      switch (options.path) {
        case "/fakepath1":
          return dio.resolve("fake data");
        case "/fakepath2":
          return dio.get("/test");
        case "/fakepath3":
        // You can also return a HttpError directly.
          return dio.reject("test error");
        case "fakepath4":
        // Here is equivalent to call dio.reject("test error")
          return new DioError(
              message: "test error");
        case "/test?tag=1":
          {
            //Response response = await dio.get("/token");
            //options.headers["token"] = response.data["data"]["token"];
            return options;
          }
        default:
          return options; //continue
      }
    }
  ));
  Response response = await dio.get("/fakepath1");
  assert(response.data == "fake data");
  response = await dio.get("/fakepath2");
  assert(response.data["errCode"] == 0);

  try {
    response = await dio.get("/fakepath3");
  } on DioError catch (e) {
    assert(e.message == "test error");
    assert(e.response == null);
  }
  try {
    response = await dio.get("/fakepath4");
  } on DioError catch (e) {
    assert(e.message == "test error");
    assert(e.response == null);
  }
  response = await dio.get("/test");
  assert(response.data["errCode"] == 0);

  response = await dio.get("/test?tag=1");
  assert(response.data["errCode"] == 0);

  try {
    await dio.get("https://wendux.github.io/xsddddd");
  } on DioError catch (e) {
    assert(e.response.statusCode == 404);
  }
}
