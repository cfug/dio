import 'package:dio/dio.dart';
import 'package:dio_compatibility_layer/dio_compatibility_layer.dart';
import 'package:http/http.dart';

void main() async {
  // Start in the `http` world. You can use `http`, `cronet_http`,
  // `cupertino_http` and other `http` compatible packages.
  final httpClient = Client();

  // Make the `httpClient` compatible via the `ConversionLayerAdapter` class.
  final dioAdapter = ConversionLayerAdapter(httpClient);

  // Make dio use the `httpClient` via the conversion layer.
  final dio = Dio()..httpClientAdapter = dioAdapter;

  // Make a request.
  final response = await dio.get<dynamic>('https://dart.dev');
  print(response);
}
