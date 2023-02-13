import 'package:diox/diox.dart';

/// More examples see https://github.com/cfug/diox/blob/main/example
void main() async {
  final dio = Dio();
  final response = await dio.get('https://pub.dev');
  print(response.data);
}
