import '../dio_exception.dart';
import '../dio_mixin.dart';
import '../options.dart';
import '../response.dart';

/// [LogInterceptor] is used to print logs during network requests.
/// It should be the last interceptor added,
/// otherwise modifications by following interceptors will not be logged.
/// This is because the execution of interceptors is in the order of addition.
///
/// **Note**
/// When used in Flutter, make sure to use `debugPrint` to print logs.
/// Alternatively `dart:developer`'s `log` function can also be used.
///
/// ```dart
/// dio.interceptors.add(
///   LogInterceptor(
///     logPrint: (o) => debugPrint(o.toString()),
///   ),
/// );
/// ```
class LogInterceptor extends Interceptor {
  LogInterceptor({
    this.request = true,
    this.requestUrl = true,
    this.requestHeader = true,
    this.requestBody = false,
    this.responseUrl = true,
    this.responseHeader = true,
    this.responseBody = false,
    this.error = true,
    this.logPrint = _debugPrint,
  });

  /// Print request [RequestOptions]
  bool request;

  /// Print request URL [RequestOptions.uri]
  bool requestUrl;

  /// Print request headers [RequestOptions.headers]
  bool requestHeader;

  /// Print request data [RequestOptions.data]
  bool requestBody;

  /// Print [Response.realUri]
  bool responseUrl;

  /// Print [Response.headers]
  bool responseHeader;

  /// Print [Response.data]
  bool responseBody;

  /// Print error message
  bool error;

  /// Log printer; defaults print log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file, for example:
  /// ```dart
  ///  final file=File("./log.txt");
  ///  final sink=file.openWrite();
  ///  dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
  ///  ...
  ///  await sink.close();
  /// ```
  void Function(Object object) logPrint;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _printRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _printResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (error) {
      logPrint('*** DioException ***:');
      logPrint('uri: ${err.requestOptions.uri}');
      logPrint('$err');
      if (err.response != null) {
        _printResponse(err.response!);
      }
      logPrint('');
    }

    handler.next(err);
  }

  void _printRequest(RequestOptions options) {
    if (!request && !requestUrl && !requestHeader && !requestBody) {
      return;
    }

    if (requestUrl) {
      logPrint('*** Request ***');
      _printKV('uri', options.uri);
    }

    if (request) {
      _printKV('method', options.method);
      _printKV('responseType', options.responseType.toString());
      _printKV('followRedirects', options.followRedirects);
      _printKV('persistentConnection', options.persistentConnection);
      _printKV('connectTimeout', options.connectTimeout);
      _printKV('sendTimeout', options.sendTimeout);
      _printKV('receiveTimeout', options.receiveTimeout);
      _printKV(
        'receiveDataWhenStatusError',
        options.receiveDataWhenStatusError,
      );
      _printKV('extra', options.extra);
    }

    if (requestHeader) {
      logPrint('headers:');
      options.headers.forEach((key, v) => _printKV(' $key', v));
    }

    if (requestBody) {
      logPrint('data:');
      _printAll(options.data);
    }

    logPrint('');
  }

  void _printResponse(Response response) {
    if (!responseUrl && !responseHeader && !responseBody) {
      return;
    }

    if (responseUrl) {
      logPrint('*** Response ***');
      _printKV('uri', response.realUri);
    }

    if (responseHeader) {
      _printKV('statusCode', response.statusCode);
      if (response.statusMessage != null) {
        _printKV('statusMessage', response.statusMessage);
      }
      if (response.redirects.isNotEmpty) {
        _printKV('redirects', response.redirects);
      }

      logPrint('headers:');
      response.headers.forEach((key, v) => _printKV(' $key', v.join('\r\n\t')));
    }

    if (responseBody) {
      logPrint('Response Text:');
      _printAll(response.toString());
    }

    logPrint('');
  }

  void _printKV(String key, Object? v) {
    logPrint('$key: $v');
  }

  void _printAll(Object? msg) {
    msg.toString().split('\n').forEach(logPrint);
  }
}

void _debugPrint(Object? object) {
  assert(() {
    print(object);
    return true;
  }());
}
