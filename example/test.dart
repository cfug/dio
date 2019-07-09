import 'dart:typed_data';

import 'package:dio/dio.dart';
void getHttp() async {
  try {
    Response response = await Dio().get("http://www.google.com");
    print(response);
  } catch (e) {
    print(e);
  }
}

main() async{
//  await getHttp();
//  Stream<Uint8List> t =Stream.empty();
//  Stream<List<int>> v=Stream.empty();
//  print(v is Stream<Uint8List>);
//  print (t is Stream<List<int>> );
//  print(t is Stream<Uint8List>);

  FormData formData = FormData();
  formData.add("vehicles", List.from(["one", "two"]));
  Response response = await Dio().post("http://www.google.com",data: formData);

}
