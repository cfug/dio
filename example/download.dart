import 'dart:io';
import 'package:dio/dio.dart';

// In this example we download a image and listen the downloading progress.
main() async {
  var dio = new Dio();

  dio.onHttpClientCreate=(HttpClient client){
    client.idleTimeout = new Duration(seconds: 0);
  };

  // This is big file(about 200M)
  // var url = "http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg";

  // This is a image, about 4KB
  var url="https://flutter.io/images/flutter-mark-square-100.png";
  //var url="https://cdn.pixabay.com/photo/2018/09/03/23/56/sea-3652697_640.jpg?attachment";
  try {
    Response response=await dio.download(url,
      "./example/flutter.png",
      // Listen the download progress.
      onProgress: (received, total) {
        print((received / total * 100).toStringAsFixed(0) + "%");
      }
    );
    print(response.statusCode);
  } catch (e) {
    print(e);
  }
  print("download succeed!");
}
