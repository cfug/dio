import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

// In this example we download a image and listen the downloading progress.
void main() async {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor());
  final url = 'https://pub.dev/static/hash-rhob5slb/img/pub-dev-logo.svg';
  await download1(dio, url, './example/pub-dev-logo.svg');
  await download1(dio, url, (headers) => './example/pub-dev-logo-1.svg');
  await download1(dio, url, (headers) async => './example/pub-dev-logo-2.svg');
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
