import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

main() async {
//  var formData = new FormData.from({
//    "param1": "-1",
//    "param1": "-1",
//    "param2": "-1",
//    "param3": "-1",
//    "param4": "-1",
//    "param5": null,
//    "param8": {"a": "b", "b": "c"},
//    "dd":["X",4]
//    //"music": new UploadFileInfo(new File("./example/bee.mp4"), "be.mp4"),
//  });
//
//  //print(formData);
//
//  var t = await formData.asBytesAsync();
//  print("formStreamSize = ${t.length}");
//  print("formData.length = ${formData.length}");
//  print("asBytes.length = ${formData.asBytes().length}");
//  print(utf8.decode(t)==formData.toString());

  Response response;
  //upload a video
//  response = await Dio().post(
//    "http://localhost:3000/upload",
//    data: FormData.from({
//      "test":"haha",
//      "file": UploadFileInfo(File("./example/bee.mp4"), "bee.mp4"),
//      "file2": UploadFileInfo(File("./example/upload.txt"), "xx.text"),
//      "x":[5,"f"]
//    }),
//    onSendProgress: (received, total) {
//      if (total != -1) {
//        print((received / total * 100).toStringAsFixed(0) + "%");
//      }
//    },
//  );

  response = await Dio().get("https://google.com", options: Options(connectTimeout:1000));
  print(response);

}
