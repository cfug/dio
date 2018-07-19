import 'dart:io';
import 'package:dio/dio.dart';


main() async {
  var dio = new Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.options.connectTimeout = 5000; //5s
  dio.options.receiveTimeout=5000;
  dio.options.headers = {
    'user-agent': 'dio',
    'common-header': 'xx'
  };

  var u=new Uri(scheme: "https", host: "www.baidu.com", queryParameters: {
    "xx":"xx",
    "yy":"dd"
  });

  print(u);

  // Add request interceptor
  dio.interceptor.request.onSend = (Options options) async {
    // return ds.resolve(new Response(data:"xxx"));
    // return ds.reject(new DioError(message: "eh"));
    return options;
  };

  Response response = await dio.get("https://www.google.com/");
  print(response.data);

  // Download a file
  response = await dio.download(
      "https://www.google.com/", "./xx.html", onProgress: (received, total) {
    print('$received,$total');
  });

  // Create a FormData
  FormData formData = new FormData.from({
    "name": "wendux",
    "age": 25,
    "file": new UploadFileInfo(new File("./example/upload.txt"), "upload.txt")
  });

  // Send FormData
  response = await dio.post("/test", data: formData);
  print(response);

  response = await dio.post("/test",
    data: {
      "id": 8,
      "info": {
        "name": "wendux",
        "age": 25
      }
    },
    // Send data with "application/x-www-form-urlencoded" format
    options: new Options(
        contentType: ContentType.parse("application/x-www-form-urlencoded")),
  );
  print(response.data);
}
