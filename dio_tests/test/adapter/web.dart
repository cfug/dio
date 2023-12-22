import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

final List<HttpClientAdapter> adapters = [
  BrowserHttpClientAdapter(),
];
