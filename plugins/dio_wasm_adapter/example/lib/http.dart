import 'package:dio/dio.dart';
import 'package:dio_wasm_adapter/dio_wasm_adapter.dart';

///replace [Dio] with [createDio]
final dio = createDio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 3),
  ),
);
