import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

final List<HttpClientAdapter> adapters = [
  BrowserHttpClientAdapter(),
];
