import 'dart:io';
import 'package:dio/dio.dart';

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
main() async {
  var dio = new Dio();
  //dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.options.baseUrl = "http://localhost/ds/test";
//  dio.onHttpClientCreate = (HttpClient client) {
//    client.idleTimeout=new Duration(seconds: 0);
//    client.findProxy = (uri) {
//      //proxy all request to localhost:8888
//      return "PROXY localhost:8888";
//    };
//  };
  FormData formData = new FormData.from({
    "name": "haha",
    "file": new UploadFileInfo(new File("./example/flutter.png"), "flutter.png")
  });
  try {
    Response response = await dio.post("", data: formData);
    print(response.data);
  }catch(e){
    print(e.response.data);
  }
}
