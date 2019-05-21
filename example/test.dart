import 'dart:io';
import 'package:dio/dio.dart';

main() async {
  var dio = Dio();

  dio.interceptors.add(InterceptorsWrapper(onError: (e){
    print("xxxx");
    print(e);
  }));

  void _testDio() async {
    CancelToken token = CancelToken();
    var url = "https://github.com/flutterchina12121/dio";

    Future.delayed(const Duration(milliseconds: 0), () async {
      try {
        Response response = await dio.get(url, cancelToken: token);

        print("response");
        if (response.statusCode == 200) {
          print("request success");
        } else {
          print("request failed");
        }
      } catch (e) {

        print(e);
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      print("manual cancel");
      if (!token.isCancelled) {
        token.cancel();
      }
    });
  }

  await _testDio();
}
