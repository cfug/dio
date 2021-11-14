import 'options.dart';
import 'response.dart';

enum DioErrorType {
  /// It occurs when url is opened timeout.
  connectTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  ///It occurs when receiving timeout.
  receiveTimeout,

  /// When the server response, but with a incorrect status, such as 404, 503...
  response,

  /// When the request is cancelled, dio will throw a error with this type.
  cancel,

  /// Default error type, Some other Error. In this case, you can
  /// use the DioError.error if it is not null.
  other,
}

/// DioError describes the error info  when request failed.
class DioError implements Exception {
  DioError({
    required this.requestOptions,
    this.response,
    this.type = DioErrorType.other,
    this.error,
  });

  /// Request info.
  RequestOptions requestOptions;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response? response;

  DioErrorType type;

  /// The original error/exception object; It's usually not null when `type`
  /// is DioErrorType.other
  dynamic error;

  StackTrace? _stackTrace;

  set stackTrace(StackTrace? stack) => _stackTrace = stack;

  StackTrace? get stackTrace => _stackTrace;

  String get message => (error?.toString() ?? '');

  @override
  String toString() {
    var msg = 'DioError [$type]: $message';
    if (error is Error) {
      msg += '\n${(error as Error).stackTrace}';
    }
    if (_stackTrace != null) {
      msg += '\nSource stack:\n$stackTrace';
    }
    return msg;
  }
}
