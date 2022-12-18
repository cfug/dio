import 'package:diox/dio.dart';

final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 3),
));
