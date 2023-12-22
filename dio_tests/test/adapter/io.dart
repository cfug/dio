import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

final List<HttpClientAdapter> adapters = [
  IOHttpClientAdapter(),
  Http2Adapter(null),
];
