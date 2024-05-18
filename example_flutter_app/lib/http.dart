import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 3),
  ),
);
