import 'package:dio/dio.dart';

void _callDefaultRequest() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor(request: false, responseHeader: false));
  dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        assert(options.queryParameters.isEmpty);
        return options;
      }
  ));
  await dio.get("https://google.com");
}

void _safeQueryEnabledByDefault() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor(request: false, responseHeader: false));
  dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        assert(options.queryParameters.isEmpty);
        return options;
      }
  ));
  await dio.get("https://google.com", queryParameters: {'something': null});
}

void _safeQueryDisabled() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor(request: false, responseHeader: false));
  dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        var queryParameters = options.queryParameters;
        assert(queryParameters.isNotEmpty);
        assert(queryParameters['something'] == null);
        return options;
      }
  ));
  await dio.get("https://google.com", queryParameters: {'something': null}, safeQuery: false);
}

main() async {
  _callDefaultRequest();
  _safeQueryEnabledByDefault();
  _safeQueryDisabled();
}
