import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void showProgress(received, total) {
  if (total != -1) {
    print((received / total * 100).toStringAsFixed(0) + '%');
  }
}

Future<FormData> formData1() async {
  return FormData.fromMap({
    'name': 'wendux',
    'age': 25,
    'file': await MultipartFile.fromFile(
      './example/xx.png',
      filename: 'xx.png',
    ),
    'files': [
      await MultipartFile.fromFile(
        './example/upload.txt',
        filename: 'upload.txt',
      ),
      MultipartFile.fromFileSync(
        './example/upload.txt',
        filename: 'upload.txt',
      ),
    ]
  });
}

Future<FormData> formData2() async {
  final formData = FormData();

  formData.fields
    ..add(
      MapEntry(
        'name',
        'wendux',
      ),
    )
    ..add(
      MapEntry(
        'age',
        '25',
      ),
    );

  formData.files.add(
    MapEntry(
      'file',
      await MultipartFile.fromFile(
        './example/xx.png',
        filename: 'xx.png',
      ),
    ),
  );

  formData.files.addAll([
    MapEntry(
      'files',
      await MultipartFile.fromFile(
        './example/upload.txt',
        filename: 'upload.txt',
      ),
    ),
    MapEntry(
      'files',
      MultipartFile.fromFileSync(
        './example/upload.txt',
        filename: 'upload.txt',
      ),
    ),
  ]);
  return formData;
}

Future<FormData> formData3() async {
  return FormData.fromMap({
    'file': await MultipartFile.fromFile(
      './example/upload.txt',
      filename: 'uploadfile',
    ),
  });
}

/// FormData will create readable "multipart/form-data" streams.
/// It can be used to submit forms and file uploads to http server.
void main() async {
  final dio = Dio();
  dio.options.baseUrl = 'http://localhost:3000/';
  dio.interceptors.add(LogInterceptor());
  // dio.interceptors.add(LogInterceptor(requestBody: true));
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) {
        // Proxy all request to localhost:8888
        return 'PROXY localhost:8888';
      };
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    },
  );
  Response response;

  final data1 = await formData1();
  final data2 = await formData2();
  final bytes1 = await data1.readAsBytes();
  final bytes2 = await data2.readAsBytes();
  assert(bytes1.length == bytes2.length);

  final data3 = await formData3();
  print(utf8.decode(await data3.readAsBytes()));

  response = await dio.post(
    //"/upload",
    'http://localhost:3000/upload',
    data: data3,
    onSendProgress: (received, total) {
      if (total != -1) {
        print('${(received / total * 100).toStringAsFixed(0)}%');
      }
    },
  );
  print(response);
}
