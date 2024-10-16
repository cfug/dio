import 'package:meta/meta.dart';

import 'options.dart';
import 'response.dart';

/// Deprecated in favor of [DioExceptionType] and will be removed in future major versions.
@Deprecated('Use DioExceptionType instead. This will be removed in 6.0.0')
typedef DioErrorType = DioExceptionType;

/// [DioError] describes the exception info when a request failed.
@Deprecated('Use DioException instead. This will be removed in 6.0.0')
typedef DioError = DioException;

/// The exception enumeration indicates what type of exception
/// has happened during requests.
enum DioExceptionType {
  /// Caused by a connection timeout.
  connectionTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  /// It occurs when receiving timeout.
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

/// Determine the content logging level of [DioException]s.
///
/// - Using [withRequestUrl] will log the URL of the exception.
///   The URL could be [Response.realUri] or [RequestOptions.uri].
/// - Using [withMessages] will log the available message of the exception.
///
/// To combine levels, use the binary operators to compute the desired level.
/// For example, to log both URL and messages, either use [all] or use:
/// ```dart
/// final level = DioExceptionLogLevel(
///   DioExceptionLogLevel.withRequestUrl | DioExceptionLogLevel.withRequestUrl,
/// );
/// ```
class DioExceptionLogLevel {
  const DioExceptionLogLevel(this.value);

  final int value;

  static const withRequestUrl = 1;
  static const withMessages = 1 << 2;

  static const least = DioExceptionLogLevel(0);
  static const common = DioExceptionLogLevel(withMessages);
  static const all = DioExceptionLogLevel(withRequestUrl | withMessages);

  bool get containsRequestUrl => value & withRequestUrl == withRequestUrl;

  bool get containsMessages => value & withMessages == withMessages;

  DioExceptionLogLevel operator +(DioExceptionLogLevel type) => this | type;

  DioExceptionLogLevel operator -(DioExceptionLogLevel type) => this ^ type;

  DioExceptionLogLevel operator |(DioExceptionLogLevel type) {
    return DioExceptionLogLevel(value | type.value);
  }

  DioExceptionLogLevel operator ^(DioExceptionLogLevel type) {
    return DioExceptionLogLevel(value ^ type.value);
  }

  DioExceptionLogLevel operator >>(int bit) {
    return DioExceptionLogLevel(value >> bit);
  }

  DioExceptionLogLevel operator <<(int bit) {
    return DioExceptionLogLevel(value << bit);
  }

  /// The values of [RequestType].
  static const values = <DioExceptionLogLevel>[all, common];

  /// Computes the request type from given types.
  static DioExceptionLogLevel fromTypes(List<DioExceptionLogLevel> types) {
    DioExceptionLogLevel result = const DioExceptionLogLevel(0);
    for (final type in types) {
      result += type;
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is DioExceptionLogLevel && value == other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => 'DioExceptionLogLevel($value)';
}

/// [DioException] describes the exception info when a request failed.
@immutable
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
        requestOptions: requestOptions,
        response: response,
        error: null,
        message: _badResponseExceptionMessage(statusCode),
      );

  factory DioException.connectionTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: requestOptions,
        response: null,
        error: error,
        message: 'The request connection took longer than $timeout '
            'and it was aborted. '
            'To get rid of this exception, try raising the '
            'RequestOptions.connectTimeout above the duration of $timeout or '
            'improve the response time of the server.',
      );

  factory DioException.sendTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
  }) =>
      DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: requestOptions,
        response: null,
        error: null,
        message: 'The request took longer than $timeout to send data. '
            'It was aborted. '
            'To get rid of this exception, try raising the '
            'RequestOptions.sendTimeout above the duration of $timeout or '
            'improve the response time of the server.',
      );

  factory DioException.receiveTimeout({
    required Duration timeout,
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: requestOptions,
        response: null,
        error: error,
        message: 'The request took longer than $timeout to receive data. '
            'It was aborted. '
            'To get rid of this exception, try raising the '
            'RequestOptions.receiveTimeout above the duration of $timeout or '
            'improve the response time of the server.',
      );

  factory DioException.badCertificate({
    required RequestOptions requestOptions,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.badCertificate,
        requestOptions: requestOptions,
        response: null,
        error: error,
        message: 'The certificate of the response is not approved.',
      );

  factory DioException.requestCancelled({
    required RequestOptions requestOptions,
    required Object? reason,
    StackTrace? stackTrace,
  }) =>
      DioException(
        type: DioExceptionType.cancel,
        requestOptions: requestOptions,
        response: null,
        error: reason,
        stackTrace: stackTrace,
        message: 'The request was manually cancelled by the user.',
      );

  factory DioException.connectionError({
    required RequestOptions requestOptions,
    required String reason,
    Object? error,
  }) =>
      DioException(
        type: DioExceptionType.connectionError,
        message: 'The connection errored: $reason '
            'This indicates an error which most likely cannot be solved by the library.',
        requestOptions: requestOptions,
        response: null,
        error: error,
      );

  /// Users can customize the logging level when a [DioException] was thrown.
  static DioExceptionLogLevel logLevel = DioExceptionLogLevel.common;

  /// The request info for the request that throws exception.
  ///
  /// The info can be empty (e.g. `uri` equals to "")
  /// if the request was never submitted.
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
    final buffer = StringBuffer('DioException [${type.toPrettyDescription()}]');
    if (logLevel.containsRequestUrl) {
      buffer.writeln(' ${response?.realUri ?? requestOptions.uri}');
    }
    if (logLevel.containsMessages) {
      if (logLevel.containsRequestUrl) {
        buffer.writeln();
      } else {
        buffer.write(': ');
      }
      buffer.write('$message');
    }
    if (error != null) {
      buffer.writeln();
      buffer.write('Error: $error');
    }
    return buffer.toString();
  }

  /// Because of [ValidateStatus] we need to consider all status codes when
  /// creating a [DioException.badResponse].
  static String _badResponseExceptionMessage(int statusCode) {
    final String message;
    if (statusCode >= 100 && statusCode < 200) {
      message =
          'This is an informational response - the request was received, continuing processing';
    } else if (statusCode >= 200 && statusCode < 300) {
      message =
          'The request was successfully received, understood, and accepted';
    } else if (statusCode >= 300 && statusCode < 400) {
      message =
          'Redirection: further action needs to be taken in order to complete the request';
    } else if (statusCode >= 400 && statusCode < 500) {
      message =
          'Client error - the request contains bad syntax or cannot be fulfilled';
    } else if (statusCode >= 500 && statusCode < 600) {
      message =
          'Server error - the server failed to fulfil an apparently valid request';
    } else {
      message =
          'A response with a status code that is not within the range of inclusive 100 to exclusive 600'
          'is a non-standard response, possibly due to the server\'s software';
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'This exception was thrown because the response has a status code of $statusCode '
      'and RequestOptions.validateStatus was configured to throw for this status code.',
    );
    buffer.writeln(
      'The status code of $statusCode has the following meaning: "$message"',
    );
    buffer.writeln(
      'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status',
    );
    buffer.writeln(
      'In order to resolve this exception you typically have either to verify '
      'and fix your request code or you have to fix the server code.',
    );

    return buffer.toString();
  }
}
