import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  var url = 'http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg';
  var savePath = './example/HBuilder.9.0.2.macosx_64.dmg';

//  var url = "https://www.baidu.com/img/bdlogo.gif";
//  var savePath = "./example/bg.gif";

  await downloadWithChunks(url, savePath, onReceiveProgress: (received, total) {
    if (total != -1) {
      print('${(received / total * 100).floor()}%');
    }
  });
}

/// Downloading by spiting as file in chunks
Future downloadWithChunks(
  url,
  savePath, {
  ProgressCallback? onReceiveProgress,
}) async {
  const firstChunkSize = 102;
  const maxChunk = 3;

  var total = 0;
  var dio = Dio();
  var progress = <int>[];

  void Function(int, int) createCallback(no) {
    return (int received, int _) {
      progress[no] = received;
      if (onReceiveProgress != null && total != 0) {
        onReceiveProgress(progress.reduce((a, b) => a + b), total);
      }
    };
  }

  Future<Response> downloadChunk(url, start, end, no) async {
    progress.add(0);
    --end;
    return dio.download(
      url,
      savePath + 'temp$no',
      onReceiveProgress: createCallback(no),
      options: Options(
        headers: {'range': 'bytes=$start-$end'},
      ),
    );
  }

  Future mergeTempFiles(chunk) async {
    var f = File(savePath + 'temp0');
    var ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
    for (var i = 1; i < chunk; ++i) {
      var _f = File(savePath + 'temp$i');
      await ioSink.addStream(_f.openRead());
      await _f.delete();
    }
    await ioSink.close();
    await f.rename(savePath);
  }

  var response = await downloadChunk(url, 0, firstChunkSize, 0);
  if (response.statusCode == 206) {
    total = int.parse(response.headers
        .value(HttpHeaders.contentRangeHeader)!
        .split('/')
        .last);
    var reserved =
        total - int.parse(response.headers.value(Headers.contentLengthHeader)!);
    var chunk = (reserved / firstChunkSize).ceil() + 1;
    if (chunk > 1) {
      var chunkSize = firstChunkSize;
      if (chunk > maxChunk + 1) {
        chunk = maxChunk + 1;
        chunkSize = (reserved / maxChunk).ceil();
      }
      var futures = <Future>[];
      for (var i = 0; i < maxChunk; ++i) {
        var start = firstChunkSize + i * chunkSize;
        futures.add(downloadChunk(url, start, start + chunkSize, i + 1));
      }
      await Future.wait(futures);
    }
    await mergeTempFiles(chunk);
  }
}
