import 'package:meta/meta.dart';

import '../compute/compute.dart';
import '../dio_error.dart';
import '../dio_mixin.dart';
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
  ///  final file=File("./log.txt");
  ///  final sink=file.openWrite();
  ///  dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
  ///  ...
  ///  await sink.close();
  ///```
  void Function(Object object) logPrint;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    compute(printRequest, options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    compute(printResponse, response);
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (error) {
      compute(printError, err);
    }
    handler.next(err);
  }

  @internal
  void printRequest(RequestOptions options) {
    final sb = StringBuffer();
    sb.writeln('*** Request ***');
    sb.writeln(composeKV('uri', options.uri));
    if (request) {
      sb.writeln(composeKV('method', options.method));
      sb.writeln(composeKV('responseType', options.responseType.toString()));
      sb.writeln(composeKV('followRedirects', options.followRedirects));
      sb.writeln(
        composeKV('persistentConnection', options.persistentConnection),
      );
      sb.writeln(composeKV('connectTimeout', options.connectTimeout));
      sb.writeln(composeKV('sendTimeout', options.sendTimeout));
      sb.writeln(composeKV('receiveTimeout', options.receiveTimeout));
      sb.writeln(
        composeKV(
          'receiveDataWhenStatusError',
          options.receiveDataWhenStatusError,
        ),
      );
      sb.writeln(composeKV('extra', options.extra));
    }
    if (requestHeader) {
      sb.writeln('Headers:');
      options.headers.forEach((key, v) => sb.writeln(composeKV(' $key', v)));
    }
    if (requestBody) {
      sb.writeln('Data:');
      sb.writeln(options.data);
    }
    sb.writeln();
    logPrint(sb.toString());
  }

  @internal
  void printResponse(Response response) {
    final sb = StringBuffer();
    sb.writeln('*** Response ***');
    sb.writeln(composeKV('uri', response.requestOptions.uri));
    if (responseHeader) {
      sb.writeln(composeKV('statusCode', response.statusCode));
      if (response.isRedirect == true) {
        sb.writeln(composeKV('redirect', response.realUri));
      }
      sb.writeln('Headers:');
      response.headers.forEach((key, v) => sb.writeln(composeKV(' $key', v)));
    }
    if (responseBody) {
      sb.writeln('Response (in text):');
      sb.writeln(response.toString());
    }
    sb.writeln();
    logPrint(sb.toString());
  }

  @internal
  void printError(DioError error) {
    final sb = StringBuffer();
    sb.writeln('*** DioError ***');
    sb.writeln(composeKV('uri', error.requestOptions.uri));
    sb.writeln(composeKV('error', error));
    if (error.response != null) {
      final response = error.response!;
      if (responseHeader) {
        sb.writeln(composeKV('statusCode', response.statusCode));
        if (response.isRedirect == true) {
          sb.writeln(composeKV('redirect', response.realUri));
        }
        sb.writeln('Headers:');
        response.headers.forEach(
          (key, v) => sb.writeln(composeKV(' $key', v)),
        );
      }
      if (responseBody) {
        sb.writeln('Response (in text):');
        sb.writeln(response.toString());
      }
    }
    sb.writeln();
    logPrint(sb.toString());
  }

  @internal
  String composeKV(String key, Object? value) {
    return '$key: $value';
  }
}
