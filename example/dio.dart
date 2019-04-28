import 'dart:io';
import 'package:dio/dio.dart';

main() async {
  var dio = Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.options.connectTimeout = 5000; //5s
  dio.options.receiveTimeout = 5000;
  dio.options.validateStatus=(int status){
    return status >0;
  } ;
  dio.options.headers = {
    HttpHeaders.userAgentHeader: 'dio',
    'common-header': 'xx',
  };

// Or you can create dio instance and config it as follow:
//  var dio = Dio(BaseOptions(
//    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
//    connectTimeout: 5000,
//    receiveTimeout: 5000,
//    headers: {
//      HttpHeaders.userAgentHeader: 'dio',
//      'common-header': 'xx',
//    },
//  ));

  dio.interceptors
    ..add(InterceptorsWrapper(
      onRequest: (Options options) {
        // return ds.resolve( Response(data:"xxx"));
        // return ds.reject( DioError(message: "eh"));
        return options;
      },
    ))
    ..add(LogInterceptor(responseBody: false)); //Open log;

  Response response = await dio.get("https://www.google.com/");

  // Download a file
  response = await dio.download(
    "https://www.google.com/",
    "./example/xx.html",
    queryParameters: {"a": 1},
    onReceiveProgress: (received, total) {
      if (total != -1) {
        print('$received,$total');
      }
    },
  );

  // Create a FormData
  FormData formData = FormData.from({
    "age": 25,
    "file": UploadFileInfo(File("./example/upload.txt"), "upload.txt")
  });

  // Send FormData
  response = await dio.post("/test", data: formData);
  print(response);

  response = await dio.post(
    "/test",
    data: {
      "id": 8,
      "info": {"name": "wendux", "age": 25}
    },
    // Send data with "application/x-www-form-urlencoded" format
    options: Options(
      contentType: ContentType.parse("application/x-www-form-urlencoded"),
    ),
  );
  print(response.data);
}
