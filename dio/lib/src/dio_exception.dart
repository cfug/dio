import 'options.dart';
import 'response.dart';

/// The exception enumeration indicates what type of exception
/// has happened during requests.
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
  /// [DioException.cause] if it is not null.
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
    this.cause,
    StackTrace? causeStackTrace,
    this.message,
  }) : _causeStackTrace = causeStackTrace;

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
        cause: null,
      );

  factory DioException.connectionTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? cause,
  }) =>
      DioException(
        type: DioExceptionType.connectionTimeout,
        message: 'The request connection took '
            'longer than $timeout. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        cause: cause,
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
        cause: null,
      );

  factory DioException.receiveTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? cause,
  }) =>
      DioException(
        type: DioExceptionType.receiveTimeout,
        message: 'The request took '
            'longer than $timeout to receive data. It was aborted.',
        requestOptions: requestOptions,
        response: null,
        cause: cause,
      );

  factory DioException.requestCancelled({
    required RequestOptions requestOptions,
    required Object? cause,
    StackTrace? causeStackTrace,
  }) =>
      DioException(
        type: DioExceptionType.cancel,
        message: 'The request was cancelled.',
        requestOptions: requestOptions,
        response: null,
        cause: cause,
        causeStackTrace: causeStackTrace,
      );

  factory DioException.connectionError({
    required RequestOptions requestOptions,
    required String reason,
    Object? cause,
  }) =>
      DioException(
        type: DioExceptionType.connectionError,
        message: 'The connection errored: $reason',
        requestOptions: requestOptions,
        response: null,
        cause: cause,
      );

  /// The request info for the request that throws exception.
  final RequestOptions requestOptions;

  /// Response info, it may be `null` if the request can't reach to the
  /// HTTP server, for example, occurring a DNS error, network is not available.
  final Response? response;

  final DioExceptionType type;

  /// The original error/exception object;
  /// It's usually not null when `type` is [DioExceptionType.unknown].
  final Object? cause;

  /// The stacktrace of the original error/exception object;
  /// It's usually not null when `type` is [DioExceptionType.unknown].
  final StackTrace? _causeStackTrace;

  StackTrace? get causeStackTrace =>
      _causeStackTrace ?? (cause is Error ? (cause as Error).stackTrace : null);

  /// The error message that throws a [DioException].
  final String? message;

  /// Generate a new [DioException] by combining given values and original values.
  DioException copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioExceptionType? type,
    Object? cause,
    StackTrace? causeStackTrace,
    String? message,
  }) {
    return DioException(
      requestOptions: requestOptions ?? this.requestOptions,
      response: response ?? this.response,
      type: type ?? this.type,
      cause: cause ?? this.cause,
      causeStackTrace: causeStackTrace ?? this.causeStackTrace,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    String msg = 'DioException [${type.toPrettyDescription()}]: $message';
    if (cause != null) {
      msg += '\nError: $cause';
    }
    return msg;
  }
}
