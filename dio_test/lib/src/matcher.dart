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
      matchesDioException(
        type,
        stackTraceContains: stackTraceContains,
        matcher: matcher,
      ),
    );

Matcher matchesDioException(
  DioExceptionType type, {
  String? stackTraceContains,
  Object? matcher,
}) {
  TypeMatcher<DioException> base = isA<DioException>().having(
    (e) => e.type,
    'type',
    equals(type),
  );
  if (stackTraceContains != null) {
    base = base.having(
      (e) => e.stackTrace.toString(),
      'stackTrace',
      contains(stackTraceContains),
    );
  }
  return allOf([
    base,
    if (matcher != null) matcher,
  ]);
}
