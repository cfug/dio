import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';

void main() {
  final dio = Dio();
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  dio.interceptors.add(LogInterceptor());
  dio.get('https://httpbun.com/status/200');
}
