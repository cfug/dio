import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    connectTimeout: Duration(seconds: 3),
  ),
);
