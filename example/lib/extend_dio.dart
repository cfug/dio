import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class HttpService extends DioForNative {
  HttpService([BaseOptions? baseOptions]) : super(baseOptions) {
    options
      ..baseUrl = 'https://httpbin.org/'
      ..contentType = Headers.jsonContentType;
  }

  Future<String> echo(String data) {
    return post('/post', data: data).then((resp) => resp.data['data']);
  }
}

void main() async {
  final httpService = HttpService();
  final res = await httpService.echo('hello server!');
  print(res);
}
