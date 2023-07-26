# Migration Guide

This document gathered all breaking changes and migrations requirement between versions.

<!--
When new content need to be added to the migration guide, make sure they're following the format:
1. Add a version in the *Breaking versions* section, with a version anchor.
2. Use *Summary* and *Details* to introduce the migration.
-->

## Breaking versions

- [5.0.0](#500)
- [4.0.0](#400)

## 5.0.0

### Summary

- `get` and `getUri` in `Dio` has different signature.
- `DefaultHttpClientAdapter` is now named `IOHttpClientAdapter`,
  and the platform independent adapter can be initiated by `HttpClientAdapter()` which is a factory method.
- Adapters that extends `HttpClientAdapter` must now `implements` instead of `extends`.
- `DioError` has separate constructors and all fields are annotated as final.
- `DioErrorType` has different values.
- Imports are split into new libraries:
  - `dio/io.dart` is for natives specific classes;
  - `dio/browser.dart` is for web specific classes.
- `connectTimeout`, `sendTimeout`, and `receiveTimeout` are now `Duration` instead of `int`.

### Details

#### `get` and `getUri`

```diff
 Future<Response<T>> get<T>(
   String path, {
+  Object? data,
   Map<String, dynamic>? queryParameters,
   Options? options,
   CancelToken? cancelToken,
   ProgressCallback? onReceiveProgress,
 });
```

```diff
 Future<Response<T>> getUri<T>(
   Uri uri, {
+  Object? data,
   Map<String, dynamic>? queryParameters,
   Options? options,
   CancelToken? cancelToken,
   ProgressCallback? onReceiveProgress,
 });
```

#### `HttpClientAdapter`

Before:

```dart
void initAdapter() {
  final dio = Dio();
  // For natives.
  dio.httpClientAdapter = DefaultHttpClientAdapter();
  // For web.
  dio.httpClientAdapter = BrowserHttpClientAdapter();
}
```

After:

```dart
void initAdapter() {
  final dio = Dio();
  // Universal adapter that create the adapter for the corresponding platform.
  dio.httpClientAdapter = HttpClientAdapter();
  // For natives.
  dio.httpClientAdapter = IOHttpClientAdapter();
  // For web.
  dio.httpClientAdapter = BrowserHttpClientAdapter();
}
```

#### Implementing `HttpClientAdapter`

Before:
```dart
class ExampleAdapter extends HttpClientAdapter { /* ... */ }
```

After:
```dart
class ExampleAdapter implements HttpClientAdapter { /* ... */ }
```

#### Const `DioError`

Before:

```dart
Never throwDioError() {
  final error = DioError(request: requestOptions, error: err);
  error.message = 'Custom message.';
  error.stackTrace = StackTrace.current;
  throw error;
}
```

After:

```dart
Never throwDioError() {
  DioError error = DioError(
    request: requestOptions,
    error: err,
    stackTrace: StackTrace.current
  );
  error = error.copyWith(message: 'Custom message.');
  throw error;
}
```

#### `DioErrorType` values update

| Before         | After             |
|:---------------|:------------------|
| N/A            | badCertificate    |
| response       | badResponse       |
| connectTimeout | connectionTimeout |
| other          | unknown           |

#### `Duration` instead of `int` for timeouts

Before:

```dart
void request() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: 5000,
      sendTimeout: 5000,
      receiveTimeout: 10000,
    ),
  );
}
```

After:

```dart
void request() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
```

## 4.0.0

### Details

1. **Null safety support** (Dart >= 2.12).
2. **The `Interceptor` APIs signature has changed**.
3. Rename `options.merge` to `options.copyWith`.
4. Rename `DioErrorType` enums from uppercase to camel style.
5. Delete `dio.resolve` and `dio.reject` APIs (use `handler` instead in  interceptors).
6. Class `BaseOptions`  no longer inherits from `Options` class.
7. Change `requestStream` type of `HttpClientAdapter.fetch` from `Stream<List<int>>` to `Stream<Uint8List>`.
8. Download API: Add real uri and redirect information to headers.
