import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void showDownloadProgress(received, total) {
  if (total != -1) {
    print((received / total * 100).toStringAsFixed(0) + "%");
  }
}

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
main() async {
  var dio = Dio();
  dio.options.baseUrl = "http://localhost:3000/";
 // dio.interceptors.add(LogInterceptor(requestBody: true));
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.findProxy = (uri) {
      //proxy all request to localhost:8888
      return "PROXY localhost:8888";
    };
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  };
  FormData formData = FormData.from({
    "test": "wendux",
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
    "test": "wendux",
    "age": 25,
    //"file":  UploadFileInfo( File("/Users/duwen/Downloads/YoudaoNote.dmg"), "YoudaoNote.dmg"),
    "file": UploadFileInfo(File("./example/upload.txt"), "upload.txt"),
    "file2": UploadFileInfo.fromBytes(utf8.encode("hello world"), "word.txt"),
  });

  Response response;
  //upload a video
  response = await dio.post(
    "/upload",
    data: FormData.from({
      "test":"haha",
      //"file": UploadFileInfo(File("./example/bee.mp4"), "bee.mp4"),
      //"file2": UploadFileInfo(File("./example/upload.txt"), "xx.text"),
    }),
    onSendProgress: (received, total) {
      if (total != -1) {
        print((received / total * 100).toStringAsFixed(0) + "%");
      }
    },
  );
//  response = await dio.post(
//    "/upload",
//    data: formData,
//    onSendProgress: showDownloadProgress,
//  );
//  response = await dio.post(
//    "/upload",
//    data: formData2,
//    cancelToken: CancelToken(),
//  );
}
