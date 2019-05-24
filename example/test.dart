import 'dart:io';
import 'package:dio/dio.dart';

main() async {
  var dio = Dio();
//  try {
//    await dio.get("https://wendux.github.io/xsddddd");
//    print("success");
//  } on DioError catch (e) {
//    print(e is Error);
//    print(e is Exception);
//  }

  var formData = new FormData.from({
    "param1": "-1",
    "param2": "-1",
    "param3": "-1",
    "param4": "-1",
    "param5": "-1",
    "music": new UploadFileInfo(new File("./example/xx.png"), "audio.m4a"),
  });
  var t= await formData.asBytesAsync();
  print(formData.length==t.length);

}
