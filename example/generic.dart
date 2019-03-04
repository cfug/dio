import 'package:dio/dio.dart';

main() async {
  Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0",
      method: "GET",
    ),
  );


  Response response;
  //No generic type, the ResponseType will work.
  response = await dio.get("/test");
  print(response.data is Map);
  Response<Map<String,dynamic>> r0= await dio.get("/test");
  print(r0.data.containsKey("errCode"));
  response = await dio.get<Map>("/test");
  print(response.data is Map);
  response = await dio.get<String>("/test");
  print(response.data is String);
  response = await dio.get("/test", options: Options(responseType: ResponseType.plain));
  print(response.data is String);

  // the content of "https://baidu.com" is a html file, So it can't be convert to Map type,
  // it will cause a FormatException.
  response = await dio.get<Map>("https://baidu.com").catchError(print);

  // This works well.
  response = await dio.get("https://baidu.com");
  // This works well too.
  response = await dio.get<String>("https://baidu.com");
  // This is the recommended way.
  Response<String> r = await dio.get<String>("https://baidu.com");
  print(r.data.length);
}
