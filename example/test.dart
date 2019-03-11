import 'package:dio/dio.dart';

main() async {
  Dio dio = Dio();
  dio.interceptors.add(LogInterceptor(requestBody: true, requestHeader: true));
  dio.options.connectTimeout=5000;
  dio.options.receiveTimeout=5000;
  dio.get("https://flutterchina.club");

//    Response<List<int>> rs = await Dio().get<List<int>>(
//      'https://admin-test.shiguangkey.com/captcha.jpg',
//      options: Options(
//        responseType: ResponseType.bytes,
//      ),
//    );
//    print(rs.data);
//
//    Uri(queryParameters: {"age":15});

//  Response response = await dio.post('/index.php/Api/Public/Login', data: formData);
//  print(response.data.toString());
//  dio.get("https://google.com", queryParameters: {
//    "key": [1, 2, 3]
//  }).catchError((e){
//    print(e.request);
//  });

//  dio.interceptors.add(LogInterceptor(requestBody: true));
// Response response= await dio.post<String>("http://22786vp873.iok.la/weapp/uploadWxFile", data:
// FormData.from({
//  "file": UploadFileInfo.fromBytes(utf8.encode("hello"), "xx.txt", contentType: ContentType.text),
//  })
// );
// print(response);
}
