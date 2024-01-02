import 'package:dio/dio.dart';

class HttpService extends Dio {
  HttpService([super.baseOptions]) {
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
