import 'package:dio/dio.dart';

/// More examples see https://github.com/flutterchina/dio/tree/master/example
void main() async {
  final dio = Dio();
  final response = await dio.get('https://pub.dev');
  print(response.data);
}
