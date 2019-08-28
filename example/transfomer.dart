import 'dart:async';
import 'package:dio/dio.dart';

/// If the request data is a `List` type, the [DefaultTransformer] will send data
/// by calling its `toString()` method. However, normally the List object is
/// not expected for request data( mostly need Map ). So we provide a custom
/// [Transformer] that will throw error when request data is a `List` type.

class MyTransformer extends DefaultTransformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data is List<String>) {
      throw DioError(error: "Can't send List to sever directly");
    } else {
      return super.transformRequest(options);
    }
  }

  /// The [Options] doesn't contain the cookie info. we add the cookie
  /// info to [Options.extra], and you can retrieve it in [ResponseInterceptor]
  /// and [Response] with `response.request.extra["cookies"]`.
  @override
  Future transformResponse(
      RequestOptions options, ResponseBody response) async {
    options.extra["self"] = 'XX';
    return super.transformResponse(options, response);
  }
}

main() async {
  var dio = Dio();
  // Use custom Transformer
  dio.transformer = MyTransformer();

  Response response = await dio.get("https://www.baidu.com");
  print(response.request.extra["self"]);

  try {
    await dio.post("https://www.baidu.com", data: ["1", "2"]);
  } catch (e) {
    print(e);
  }
  print("xxx");
}
