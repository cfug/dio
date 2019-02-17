import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
main() async {
  var dio = Dio();
  dio.options.baseUrl = "http://localhost:3000/";
  FormData formData = FormData.from({
    "name": "wendux",
    "age": 25,
    "file": UploadFileInfo(File("./example/upload.txt"), "upload.txt"),
    "file2": UploadFileInfo.fromBytes(utf8.encode("hello world"), "word.txt"),
    // In PHP the key must endwith "[]", ("files[]")
    //"files[]": [
    //    UploadFileInfo( File("./example/upload.txt"), "upload.txt"),
    // ]
    "files": [
      UploadFileInfo(File("./example/upload.txt"), "upload.txt"),
      UploadFileInfo(File("./example/upload.txt"), "upload.txt")
    ]
  });

  FormData formData2 = FormData.from({
    "name": "wendux",
    "age": 25,
    //"file":  UploadFileInfo( File("/Users/duwen/Downloads/YoudaoNote.dmg"), "YoudaoNote.dmg"),
    "file": UploadFileInfo(File("./example/upload.txt"), "upload.txt"),
    "file2": UploadFileInfo.fromBytes(utf8.encode("hello world"), "word.txt"),
  });
  Response response;
  response = await dio.post("/upload", data: formData);
  response = await dio.post("/upload",
      data: formData2, cancelToken: CancelToken());
  print(response.statusCode);
  //Response response = await dio.post("http://localhost/ds/test", data: formData);
  print(response.data);
}
