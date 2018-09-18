import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// If the request data is a `List` type, the [DefaultTransformer] will send data
/// by calling its `toString()` method. However, normally the List object is
/// not expected for request data( mostly need Map ). So we provide a custom
/// [Transformer] that will throw error when request data is a `List` type.

class MyTransformer extends DefaultTransformer {

  @override
  Future<String> transformRequest(Options options) async {
    if (options.data is List) {
      throw new DioError(message: "Can't send List to sever directly");
    } else {
      return super.transformRequest(options);
    }
  }

  /// The [Options] doesn't contain the cookie info. we add the cookie
  /// info to [Options.extra], and you can retrieve it in [ResponseInterceptor]
  /// and [Response] with `response.request.extra["cookies"]`.
  @override
  Future transformResponse(Options options, HttpClientResponse response) async {
    options.extra["cookies"] = response.cookies;
    return super.transformResponse(options, response);
  }

}

main() async {
  var dio = new Dio();
  // Use custom Transformer
  dio.transformer = new MyTransformer();

//  Response response = await dio.get("https://www.baidu.com");
//  print(response.request.extra["cookies"]);

  try {
    await dio.post("https://www.baidu.com", data: [1, 2]);
  } catch (e) {
    print(e);
  }
  print("xxx");
}