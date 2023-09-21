import 'package:dio/dio.dart';
import 'package:dio_http_compatibility_layer/dio_http_compatibility_layer.dart';
import 'package:http/http.dart';

void main() {
  Dio().httpClientAdapter = ConversionLayerAdapter(Client());
}
