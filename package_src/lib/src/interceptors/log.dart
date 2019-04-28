import '../interceptor.dart';
import '../options.dart';
import '../response.dart';
import '../dio_error.dart';
import 'dart:math' as math;

class LogInterceptor extends Interceptor {
  LogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.logSize = 2048,
  });

  /// Print request [Options]
  bool request;

  /// Print request header [Options.headers]
  bool requestHeader;

  /// Print request data [Options.data]
  bool requestBody;

  /// Print [Response.data]
  bool responseBody;

  /// Print [Response.headers]
  bool responseHeader;

  /// Print error message
  bool error;

  /// Log size per print
  final logSize;

  @override
  onRequest(RequestOptions options) {
    print('*** Request ***');
    printKV('uri', options.uri);

    if (request) {
      printKV('method', options.method);
      printKV('contentType', options.contentType?.toString());
      printKV('responseType', options.responseType?.toString());
      printKV('followRedirects', options.followRedirects);
      printKV('connectTimeout', options.connectTimeout);
      printKV('receiveTimeout', options.receiveTimeout);
      printKV('extra', options.extra);
    }
    if (requestHeader) {
      StringBuffer stringBuffer = new StringBuffer();
      options.headers.forEach((key, v) => stringBuffer.write('\n  $key:$v'));
      printKV('header', stringBuffer.toString());
      stringBuffer.clear();
    }
    if (requestBody) {
      print("data:");
      printAll(options.data);
    }
    print("");
  }

  @override
  onError(DioError err) {
    if (error) {
      print('*** DioError ***:');
      print(err);
      if (err.response != null) {
        _printResponse(err.response);
      }
    }
  }

  @override
  onResponse(Response response) {
    print("*** Response ***");
    _printResponse(response);
  }

  void _printResponse(Response response) {
    printKV('uri', response?.request?.uri);
    if (responseHeader) {
      printKV('statusCode', response.statusCode);
      if(response.isRedirect)
      printKV('redirect',response.realUri);
      print("headers:");
      print(" " + response?.headers?.toString()?.replaceAll("\n", "\n "));
    }
    if (responseBody) {
      print("Response Text:");
      printAll(response.toString());
    }
    print("");
  }

  printKV(String key, Object v) {
    print('$key: $v');
  }

  printAll(msg) {
    msg.toString().split("\n").forEach(_printAll);
  }

  _printAll(String msg) {
    int groups = (msg.length / logSize).ceil();
    for (int i = 0; i < groups; ++i) {
      print((i > 0 ? '<<Log follows the previous line: ' : '') +
          msg.substring(
              i * logSize, math.min<int>(i * logSize + logSize, msg.length)));
    }
  }
}
