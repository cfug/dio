import 'package:dio/dio.dart';

var dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 3),
));
