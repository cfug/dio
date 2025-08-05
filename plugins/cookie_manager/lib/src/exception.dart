import 'package:dio/dio.dart';

/// Thrown when the cookie manager fails to load cookies.
class CookieManagerLoadException implements Exception {
  CookieManagerLoadException({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => 'CookieManagerLoadException: $error';
}

/// Thrown when the cookie manager fails to save cookies.
class CookieManagerSaveException implements Exception {
  CookieManagerSaveException({
    required this.response,
    required this.error,
    required this.stackTrace,
    required this.dioException,
  });

  final Response response;
  final Object error;
  final StackTrace stackTrace;
  final DioException? dioException;

  @override
  String toString() => 'CookieManagerSaveException: $error';
}
