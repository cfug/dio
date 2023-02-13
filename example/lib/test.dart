import 'package:dio/dio.dart';

// void getHttp() async {
//   final dio = Dio();
//   dio.interceptors.add(LogInterceptor(responseBody: true));
//   dio.options.baseUrl = 'https://httpbin.org';
//   dio.options.headers = {'Authorization': 'Bearer '};
//   //dio.options.baseUrl = "http://localhost:3000";
//   final response = await dio.post(
//     '/post',
//     data: null,
//     options: Options(
//       contentType: Headers.jsonContentType,
//     ),
//   );
//   print(response);
// }
//
// void main() async {
//   getHttp();
// }

void main() async {
  final dio = Dio()..interceptors.add(ProblemInterceptor());
  await dio.get('https://baidu.com/');
}

class ProblemInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    throw Exception('Unexpected problem inside onResponse');
  }
}
