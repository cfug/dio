import 'dart:io';
import 'package:dio/dio.dart';

// In this example we download a image and listen the downloading progress.
main() async {
  var dio = new Dio();

  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.idleTimeout = new Duration(seconds: 0);
  };

  // This is big file(about 200M)
  // var url = "http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg";

  // This is a image, about 4KB
  var url = "https://flutter.io/assets/flutter-lockup-4cb0ee072ab312e59784d9fbf4fb7ad42688a7fdaea1270ccf6bbf4f34b7e03f.svg";
  //var url = "https://github.com/wendux/tt"; //404
  try {
    Response response = await dio.download(
      url,
      "./example/flutter.svg",
      onProgress: (received, total) {
        if (total != -1) {
          print((received / total * 100).toStringAsFixed(0) + "%");
        }
      },
      cancelToken: CancelToken(),
      options: Options(
        //receiveDataWhenStatusError: false,
        headers: {HttpHeaders.acceptEncodingHeader: "*"},
      ),
    );
    print("download succeed!");
  } catch (e) {
    print(e.response.data);
  }
}
