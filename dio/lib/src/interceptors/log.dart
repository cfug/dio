import 'dart:async';

import '../dio_error.dart';
import '../interceptor.dart';
import '../options.dart';
import '../response.dart';

/// [LogInterceptor] is used to print logs during network requests.
/// It's better to add [LogInterceptor] to the tail of the interceptor queue,
/// otherwise the changes made in the interceptor behind A will not be printed out.
/// This is because the execution of interceptors is in the order of addition.
class LogInterceptor extends Interceptor {
  LogInterceptor({
    this.request = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.logPrint = print,
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

  /// Log printer; defaults print log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file, for example:
  ///```dart
  ///  var file=File("./log.txt");
  ///  var sink=file.openWrite();
  ///  dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
  ///  ...
  ///  await sink.close();
  ///```
  void Function(Object object) logPrint;

  @override
  Future onRequest(RequestOptions options) async {
    logPrint('*** Request ***');
    printKV('uri', options.uri);

    if (request) {
      printKV('method', options.method);
      printKV('contentType', options.contentType);
      printKV('responseType', options.responseType?.toString());
      printKV('followRedirects', options.followRedirects);
      printKV('connectTimeout', options.connectTimeout);
      printKV('receiveTimeout', options.receiveTimeout);
      printKV('extra', options.extra);
    }
    if (requestHeader) {
      StringBuffer stringBuffer = StringBuffer();
      options.headers.forEach((key, v) => stringBuffer.write('\n  $key:$v'));
      printKV('headers', stringBuffer.toString());
      stringBuffer.clear();
    }
    if (requestBody) {
      logPrint("data:");
      printAll(options.data);
    }
    logPrint("");
  }

  @override
  Future onError(DioError err) async {
    if (error) {
      logPrint('*** DioError ***:');
      logPrint("uri: ${err.request.uri}");
      logPrint("$err");
      if (err.response != null) {
        _printResponse(err.response);
      }
      logPrint("");
    }
  }

  @override
  Future onResponse(Response response) async {
    logPrint("*** Response ***");
    _printResponse(response);
  }

  void _printResponse(Response response) {
    printKV('uri', response?.request?.uri);
    if (responseHeader) {
      printKV('statusCode', response.statusCode);
      if (response.isRedirect == true) {
        printKV('redirect', response.realUri);
      }
      logPrint("headers:");
      logPrint(" " + response?.headers?.toString()?.replaceAll("\n", "\n "));
    }
    if (responseBody) {
      logPrint("Response Text:");
      printAll(response.toString());
    }
    logPrint("");
  }

  printKV(String key, Object v) {
    logPrint('$key: $v');
  }

  printAll(msg) {
    msg.toString().split("\n").forEach(logPrint);
  }
}
