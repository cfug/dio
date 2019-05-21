import 'options.dart';
import 'response.dart';

enum DioErrorType {
  /// It occurs when url is opened timeout.
  CONNECT_TIMEOUT,

  /// It occurs when url is sent timeout.
  SEND_TIMEOUT,

  ///It occurs when receiving timeout.
  RECEIVE_TIMEOUT,

  /// When the server response, but with a incorrect status, such as 404, 503...
  RESPONSE,

  /// When the request is cancelled, dio will throw a error with this type.
  CANCEL,

  /// Default error type, Some other Error. In this case, you can
  /// read the DioError.error if it is not null.
  DEFAULT,
}

/// DioError describes the error info  when request failed.
class DioError implements Exception {
  DioError({
    this.request,
    this.response,
    this.message,
    this.type = DioErrorType.DEFAULT,
    this.error,
    this.stackTrace,
  });

  /// Request info.
  RequestOptions request;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response response;

  /// Error descriptions.
  String message;

  DioErrorType type;

  /// The original error/exception object; It's usually not null when `type`
  /// is DioErrorType.DEFAULT
  dynamic error;

  String toString() =>
      "DioError [$type]: " +
      (message ?? "") +
      (stackTrace ?? "").toString();

  /// Error stacktrace info
  StackTrace stackTrace;
}
