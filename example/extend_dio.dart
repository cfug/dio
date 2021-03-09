import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

class HttpService extends DioForNative {
  HttpService([BaseOptions? baseOptions]) : super(baseOptions) {
    options
      ..baseUrl = 'http://httpbin.org/'
      ..contentType = Headers.jsonContentType;
  }

  Future<String> echo(String data) {
    return post('/post', data: data).then((resp) => resp.data['data']);
  }
}

void main() async {
  var httpService = HttpService();
  var res = await httpService.echo('hello server!');
  print(res);
}
