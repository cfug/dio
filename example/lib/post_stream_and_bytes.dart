import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

void main() async {
  var dio = Dio(BaseOptions(
    connectTimeout: 5000,
    baseUrl: 'http://httpbin.org/',
  ));

  dio.interceptors.add(LogInterceptor(responseBody: true));

  // var file = File('./example/bee.mp4');
  //
  // // Sending stream
  // await dio.post('post',
  //   data: file.openRead(),
  //   options: Options(
  //     headers: {
  //       HttpHeaders.contentTypeHeader: ContentType.text.toString(),
  //       HttpHeaders.contentLengthHeader: file.lengthSync(),
  //      // HttpHeaders.authorizationHeader: 'Bearer $token',
  //     },
  //   ),
  // );

  // Sending bytes with Stream(Just an example, you can send json(Map) directly in action)
  var postData = utf8.encode('{"userName":"wendux"}');
  await dio.post(
    'post',
    data: Stream.fromIterable([postData]),
    onSendProgress: (a, b) => print(a),
    options: Options(
      headers: {
        HttpHeaders.contentLengthHeader: postData.length, // Set content-length
      },
    ),
  );
}
