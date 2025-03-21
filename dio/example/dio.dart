import 'package:dio/dio.dart';

/// More examples see https://github.com/cfug/dio/tree/main/dio#examples
void main() async {
  final dio = Dio();
  final response = await dio.get('https://pub.dev');
  print(response.data);
}
