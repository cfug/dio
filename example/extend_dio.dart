import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

class HttpService extends DioForNative {
  HttpService([BaseOptions? baseOptions]) : super(baseOptions) {
    options
      ..baseUrl = 'http://httpbin.org/'
      ..contentType = Headers.jsonContentType;
  }
}

void main() async {
  var httpService = HttpService();
  var res = await httpService.post('/post', data: {'a': 5});
  assert(res.request.headers[Headers.contentTypeHeader]==Headers.jsonContentType);
}
