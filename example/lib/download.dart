import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

// In this example we download a image and listen the downloading progress.
void main() async {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor());
  // This is big file(about 200M)
  //   final url = "http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg";

  final url =
      'https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0/docs/imgs/book.jpg';

  // final url = "https://www.baidu.com/img/bdlogo.gif";
  await download1(dio, url, './example/book.jpg');
  await download1(dio, url, (Headers headers) => './example/book1.jpg');
  await download2(dio, url, './example/book2.jpg');
}

Future download1(Dio dio, String url, savePath) async {
  final cancelToken = CancelToken();
  try {
    await dio.download(
      url,
      savePath,
      onReceiveProgress: showDownloadProgress,
      cancelToken: cancelToken,
    );
  } catch (e) {
    print(e);
  }
}

//Another way to downloading small file
Future download2(Dio dio, String url, String savePath) async {
  try {
    final response = await dio.get(
      url,
      onReceiveProgress: showDownloadProgress,
      //Received data with List<int>
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: Duration.zero,
      ),
    );
    print(response.headers);
    final file = File(savePath);
    final raf = file.openSync(mode: FileMode.write);
    // response.data is List<int> type
    raf.writeFromSync(response.data);
    await raf.close();
  } catch (e) {
    print(e);
  }
}

void showDownloadProgress(received, total) {
  if (total != -1) {
    print((received / total * 100).toStringAsFixed(0) + '%');
  }
}
