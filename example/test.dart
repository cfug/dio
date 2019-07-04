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
  await getHttp();
}
