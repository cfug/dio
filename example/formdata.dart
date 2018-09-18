import 'dart:io';
import 'package:dio/dio.dart';

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
main() async {
  var dio = new Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";

  FormData formData = new FormData.from({
    "name": "wendux",
    "age": 25,
    "file": new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
    // In PHP the key must endwith "[]", ("files[]")
    //"files[]": [
    //   new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
    // ]
    "files": [
      new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
      new UploadFileInfo(new File("./example/upload.txt"), "upload.txt")
    ]
  });
  //Response response = await dio.post("/token", data: formData);
  Response response = await dio.post("http://localhost/ds/test", data: formData);
  print(response.data);
}
