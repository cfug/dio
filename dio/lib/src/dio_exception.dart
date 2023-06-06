import 'options.dart';
import 'response.dart';

/// Deprecated in favor of [DioExceptionType] and will be removed in future major versions.
@Deprecated('Use DioExceptionType instead. This will be removed in 6.0.0')
typedef DioErrorType = DioExceptionType;

/// [DioError] describes the exception info when a request failed.
/// Deprecated in favor of [DioException] and will be removed in future major versions.
@Deprecated('Use DioException instead. This will be removed in 6.0.0')
typedef DioError = DioException;

enum DioExceptionType {
  /// Caused by a connection timeout.
  connectionTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  ///It occurs when receiving timeout.
  receiveTimeout,

  /// Caused by an incorrect certificate as configured by [ValidateCertificate].
  badCertificate,

  /// The [DioException] was caused by an incorrect status code as configured by
  /// [ValidateStatus].
  badResponse,

  /// When the request is cancelled, dio will throw a error with this type.
  cancel,

  /// Caused for example by a `xhr.onError` or SocketExceptions.
  connectionError,

  /// Default error type, Some other [Error]. In this case, you can use the
  /// [DioException.error] if it is not null.
  unknown,
}

extension _DioExceptionTypeExtension on DioExceptionType {
  String toPrettyDescription() {
    switch (this) {
      case DioExceptionType.connectionTimeout:
        return 'connection timeout';
      case DioExceptionType.sendTimeout:
        return 'send timeout';
      case DioExceptionType.receiveTimeout:
        return 'receive timeout';
      case DioExceptionType.badCertificate:
        return 'bad certificate';
      case DioExceptionType.badResponse:
        return 'bad response';
      case DioExceptionType.cancel:
        return 'request cancelled';
      case DioExceptionType.connectionError:
        return 'connection error';
      case DioExceptionType.unknown:
        return 'unknown';
    }
  }
}

/// [DioException] describes the exception info when a request failed.
class DioException implements Exception {
  /// Prefer using one of the other constructors.
  /// They're most likely better fitting.
  DioException({
    required this.requestOptions,
    this.response,
    this.type = DioExceptionType.unknown,
    this.error,
    StackTrace? stackTrace,
    this.message,
  }) : stackTrace = identical(stackTrace, StackTrace.empty)
            ? requestOptions.sourceStackTrace ?? StackTrace.current
            : stackTrace ??
                requestOptions.sourceStackTrace ??
                StackTrace.current;

  factory DioException.badResponse({
    required int statusCode,
    required RequestOptions requestOptions,
    required Response response,
  }) =>
      DioException(
        type: DioExceptionType.badResponse,
        message: 'The request returned an '
            'invalid status code of $statusCode.',
        requestOptions: requestOptions,
        response: response,
        error: null,
      );

  factory DioException.connectionTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.connectionTimeout,
        message: 'The request connection took '
            'longer than $timeout. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: error,
      );

  factory DioException.sendTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
  }) =>
      DioException(
        type: DioExceptionType.sendTimeout,
        message: 'The request took '
            'longer than $timeout to send data. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: null,
      );

  factory DioException.receiveTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.receiveTimeout,
        message: 'The request took '
            'longer than $timeout to receive data. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        error: error,
      );

  factory DioException.requestCancelled({
    required RequestOptions requestOptions,
    required Object? reason,
    StackTrace? stackTrace,
  }) =>
      DioException(
        type: DioExceptionType.cancel,
        message: 'The request was cancelled.',
        requestOptions: requestOptions,
        response: null,
        error: reason,
        stackTrace: stackTrace,
      );

  factory DioException.connectionError({
    required RequestOptions requestOptions,
    required String reason,
  }) =>
      DioException(
        type: DioExceptionType.connectionError,
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

  final DioExceptionType type;

  /// The original error/exception object;
  /// It's usually not null when `type` is [DioExceptionType.unknown].
  final Object? error;

  /// The stacktrace of the original error/exception object;
  /// It's usually not null when `type` is [DioExceptionType.unknown].
  final StackTrace stackTrace;

  /// The error message that throws a [DioException].
  final String? message;

  /// Generate a new [DioException] by combining given values and original values.
  DioException copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioExceptionType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  }) {
    return DioException(
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
    String msg = 'DioException [${type.toPrettyDescription()}]: $message';
    if (error != null) {
      msg += '\nError: $error';
    }
    return msg;
  }
}
