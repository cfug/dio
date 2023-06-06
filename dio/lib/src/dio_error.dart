import 'dio_exception.dart';

/// Deprecated in favor of [DioExceptionType] and will be removed in future major versions.
@Deprecated('Use DioException instead. This will be removed in 6.0.0')
typedef DioErrorType = DioExceptionType;

/// [DioError] describes the exception info when a request failed.
/// Deprecated in favor of [DioException] and will be removed in future major versions.
@Deprecated('Use DioException instead. This will be removed in 6.0.0')
typedef DioError = DioException;
