import 'dart:io';
import 'package:dio/dio.dart';

main() async {
  var formData = new FormData.from({
    "param1": "-1",
    "param2": "-1",
    "param3": "-1",
    "param4": "-1",
    "param5": "-1",
    "param8":{
      "a":"b",
      "b":"c"
     },
    "music": new UploadFileInfo(new File("./example/bee.mp4"), "be.mp4"),
  });
  var v=File("./example/audio.m4a");
  print(v.lengthSync());
  var t= await formData.asBytesAsync();
  print("formStreamSize = ${t.length}");
  print("formData.length = ${formData.length}");
  print(formData.length==t.length);
  print(formData);
}
