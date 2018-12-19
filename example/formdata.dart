import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
main() async {
  var dio = new Dio();
  //dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  FormData formData = new FormData.from({
    "name": "wendux",
    "age": 25,
    "file": new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
    "file2": new UploadFileInfo.fromBytes(utf8.encode("hello world"), "word.txt"),
    // In PHP the key must endwith "[]", ("files[]")
    //"files[]": [
    //   new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
    // ]
    "files": [
      new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"),
      new UploadFileInfo(new File("./example/upload.txt"), "upload.txt")
    ]
  });

  FormData formData2 = new FormData.from({
    "name": "wendux",
    "age": 25,
    "file": new UploadFileInfo(new File("/Users/duwen/Downloads/YoudaoNote.dmg"), "YoudaoNote.dmg"),
  });

  //Response response = await dio.post("/token", data: formData);
  Response response = await dio.post("http://localhost:3000/upload", data: formData2);
  print(response.statusCode);
  //Response response = await dio.post("http://localhost/ds/test", data: formData);
  print(response.data);
}

