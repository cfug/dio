import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A matcher for functions that throw [DioException] of a specified type,
/// with an optional matcher for the stackTrace containing the specified text.
Matcher throwsDioException(
  DioExceptionType type, {
  String? stackTraceContains,
  Object? matcher,
}) =>
    throwsA(
      allOf([
        isA<DioException>(),
        (DioException e) => e.type == type,
        if (stackTraceContains != null)
          (DioException e) =>
              e.stackTrace.toString().contains(stackTraceContains),
        if (matcher != null) matcher,
      ]),
    );
