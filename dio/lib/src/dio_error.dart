import 'options.dart';
import 'response.dart';

enum DioErrorType {
  /// Caused by a connection timeout.
  connectionTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  ///It occurs when receiving timeout.
  receiveTimeout,

  /// The [DioError] was caused by an incorrect status code as configured by
  /// [ValidateStatus].
  badResponse,

  /// When the request is cancelled, dio will throw a error with this type.
  requestCancelled,

  /// Caused for example by a `xhr.onError` or SocketExceptions.
  connectionError,

  /// Default error type, Some other Error. In this case, you can
  /// use the DioError.error if it is not null.
  unknown,
}

/// DioError describes the exception info when a request failed.
class DioError implements Exception {
  /// Prefer using one of the other constructors.
  /// They're most likely better fitting.
  DioError({
    required this.requestOptions,
    this.response,
    this.type = DioErrorType.unknown,
    this.error,
    this.stackTrace,
    this.message,
  });

  DioError.badResponse({
    required int statusCode,
    required this.requestOptions,
    required this.response,
  })  : type = DioErrorType.badResponse,
        message = 'The request returned an '
            'invalid status code of $statusCode';

  DioError.connectionTimeout({
    required Duration timeout,
    required this.requestOptions,
  })  : type = DioErrorType.connectionTimeout,
        message = 'The request connection took '
            'longer than $timeout. It was aborted.';

  DioError.sendTimeout({
    required Duration timeout,
    required this.requestOptions,
  })  : type = DioErrorType.sendTimeout,
        message = 'The request took '
            'longer than $timeout to send data. It was aborted.';

  DioError.receiveTimeout({
    required Duration timeout,
    required this.requestOptions,
  })  : type = DioErrorType.receiveTimeout,
        message = 'The request took '
            'longer than $timeout to receive data. It was aborted.';

  DioError.requestCancelled({
    required this.requestOptions,
    required Object? reason,
  })  : type = DioErrorType.requestCancelled,
        message = 'The request was cancelled.',
        error = reason;

  DioError.connectionError({
    required this.requestOptions,
    required String reason,
  })  : type = DioErrorType.connectionError,
        message = 'The connection errored: $reason';

  /// Request info.
  RequestOptions requestOptions;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response? response;

  DioErrorType type;

  /// The original error/exception object; It's usually not null when `type`
  /// is DioErrorType.other
  Object? error;

  /// The stacktrace of the original error/exception object;
  /// It's usually not null when `type` is DioErrorType.other
  StackTrace? stackTrace;

  String? message;

  @override
  String toString() {
    var msg = 'DioError [$type]: $message';
    if (error is Error) {
      msg += '\n${(error as Error).stackTrace}';
    }
    if (stackTrace != null) {
      msg += '\nSource stack:\n$stackTrace';
    }
    return msg;
  }
}
