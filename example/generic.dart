import 'package:dio/dio.dart';

main() async {
  Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://httpbin.org/",
      method: "GET",
    ),
  );

  Response response;
  // No generic type, the ResponseType will work.
  response = await dio.get("/get");
  print(response.data is Map);
  // Specify the generic type(Map)
  response = await dio.get<Map>("/get");
  print(response.data is Map);

  // Specify the generic type(String)
  response = await dio.get<String>("/get");
  print(response.data is String);
  // Specify the ResponseType as ResponseType.plain
  response =
      await dio.get("/get", options: Options(responseType: ResponseType.plain));
  print(response.data is String);

  // the content of "https://baidu.com" is a html file, So it can't be convert to Map type,
  // it will cause a FormatException.
  response = await dio.get<Map>("https://baidu.com").catchError(print);

  // This works well.
  response = await dio.get("https://baidu.com");
  print("done");
  // This works well too.
  response = await dio.get<String>("https://baidu.com");
  print("done");
  // This is the recommended way.
  var r = await dio.get<String>("https://baidu.com");
  print(r.data.length);
}
