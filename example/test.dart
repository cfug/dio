import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

main() async {
//  Dio dio = Dio();
//  dio.interceptors.add(LogInterceptor(requestBody: true, requestHeader: true));
//  dio.options.connectTimeout=5000;
//  dio.options.receiveTimeout=5000;
//  dio.getUri(Uri(scheme: "https",host:"flutterchina.club",queryParameters: {
//    "username":"zhangsan,lisi"
//  }));

  var request = new http.MultipartRequest("POST", Uri.parse("http://localhost:3000/upload"));
  request.fields['user'] = 'someone@somewhere.com';
  request.files.add(await http.MultipartFile.fromPath(
    'file',
    './example/upload.txt',
    contentType: new MediaType('application', 'octet-stream'),
  ));
  request.send().then((response) {
    if (response.statusCode == 200) print("Uploaded!");
  });

}
