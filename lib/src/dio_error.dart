import 'options.dart';
import 'response.dart';

enum DioErrorType {
  /// Default error type, usually occurs before connecting the server.
  DEFAULT,

  /// When opening  url timeout, it occurs.
  CONNECT_TIMEOUT,

  ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT].
  ///
  ///  Note: This is not the receiving time limitation.
  RECEIVE_TIMEOUT,

  /// When the server response, but with a incorrect status, such as 404, 503...
  RESPONSE,

  /// When the request is cancelled, dio will throw a error with this type.
  CANCEL
}

/**
 * DioError describes the error info  when request failed.
 */
class DioError extends Error {
  DioError(
      {this.request,
      this.response,
      this.message,
      this.type = DioErrorType.DEFAULT,
      this.stackTrace});

  /// Request info.
  RequestOptions request;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response response;

  /// Error descriptions.
  String message;

  DioErrorType type;

  String toString() =>
      "DioError [$type]: " + (message??"") + (stackTrace ?? "").toString();

  /// Error stacktrace info
  StackTrace stackTrace;
}
