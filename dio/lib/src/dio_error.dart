import 'options.dart';
import 'response.dart';

enum DioErrorType {
  /// Caused by a connection timeout.
  connectionTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  ///It occurs when receiving timeout.
  receiveTimeout,

  /// Caused by an incorrect certificate as configured by [ValidateCertificate].
  badCertificate,

  /// The [DioError] was caused by an incorrect status code as configured by
  /// [ValidateStatus].
  badResponse,

  /// When the request is cancelled, dio will throw a error with this type.
  cancel,

  /// Caused for example by a `xhr.onError` or SocketExceptions.
  connectionError,

  /// Default error type, Some other [Error]. In this case, you can use the
  /// [DioError.error] if it is not null.
  unknown,
}

extension _DioErrorTypeExtension on DioErrorType {
  String toPrettyDescription() {
    switch (this) {
      case DioErrorType.connectionTimeout:
        return 'connection timeout';
      case DioErrorType.sendTimeout:
        return 'send timeout';
      case DioErrorType.receiveTimeout:
        return 'receive timeout';
      case DioErrorType.badCertificate:
        return 'bad certificate';
      case DioErrorType.badResponse:
        return 'bad response';
      case DioErrorType.cancel:
        return 'request cancelled';
      case DioErrorType.connectionError:
        return 'connection error';
      case DioErrorType.unknown:
        return 'unknown';
    }
  }
}

/// [DioError] describes the exception info when a request failed.
class DioError implements Exception {
  /// Prefer using one of the other constructors.
  /// They're most likely better fitting.
  DioError({
    required this.requestOptions,
    this.response,
    this.type = DioErrorType.unknown,
    this.error,
    StackTrace? stackTrace,
    this.message,
  }) : stackTrace = identical(stackTrace, StackTrace.empty)
            ? (requestOptions.sourceStackTrace ?? StackTrace.current)
            : stackTrace ??
                requestOptions.sourceStackTrace ??
                StackTrace.current;

  factory DioError.badResponse({
    required int statusCode,
    required RequestOptions requestOptions,
    required Response response,
  }) =>
      DioError(
        type: DioErrorType.badResponse,
        message: 'The request returned an '
            'invalid status code of $statusCode.',
        requestOptions: requestOptions,
        response: response,
        error: null,
      );

  factory DioError.connectionTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioError(
        type: DioErrorType.connectionTimeout,
        message: 'The request connection took '
            'longer than $timeout. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: error,
      );

  factory DioError.sendTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
  }) =>
      DioError(
        type: DioErrorType.sendTimeout,
        message: 'The request took '
            'longer than $timeout to send data. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: null,
      );

  factory DioError.receiveTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioError(
        type: DioErrorType.receiveTimeout,
        message: 'The request took '
            'longer than $timeout to receive data. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: error,
      );

  factory DioError.requestCancelled({
    required RequestOptions requestOptions,
    required Object? reason,
    StackTrace? stackTrace,
  }) =>
      DioError(
        type: DioErrorType.cancel,
        message: 'The request was cancelled.',
        requestOptions: requestOptions,
        response: null,
        error: reason,
        stackTrace: stackTrace,
      );

  factory DioError.connectionError({
    required RequestOptions requestOptions,
    required String reason,
  }) =>
      DioError(
        type: DioErrorType.connectionError,
        message: 'The connection errored: $reason',
        requestOptions: requestOptions,
        response: null,
        error: null,
      );

  /// The request info for the request that throws exception.
  final RequestOptions requestOptions;

  /// Response info, it may be `null` if the request can't reach to the
  /// HTTP server, for example, occurring a DNS error, network is not available.
  final Response? response;

  final DioErrorType type;

  /// The original error/exception object;
  /// It's usually not null when `type` is [DioErrorType.unknown].
  final Object? error;

  /// The stacktrace of the original error/exception object;
  /// It's usually not null when `type` is [DioErrorType.unknown].
  final StackTrace stackTrace;

  /// The error message that throws a [DioError].
  final String? message;

  /// Generate a new [DioError] by combining given values and original values.
  DioError copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioErrorType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  }) {
    return DioError(
      requestOptions: requestOptions ?? this.requestOptions,
      response: response ?? this.response,
      type: type ?? this.type,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    String msg = 'DioError [${type.toPrettyDescription()}]: $message';
    if (error != null) {
      msg += '\nError: $error';
    }
    return msg;
  }
}
