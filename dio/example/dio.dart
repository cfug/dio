import 'package:dio2/dio2.dart';

/// More examples see https://github.com/flutterchina/dio/tree/master/example
void main() async {
  var dio = Dio();
  final response = await dio.get('https://google.com');
  print(response.data);
}
