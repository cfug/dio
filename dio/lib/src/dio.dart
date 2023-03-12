import 'dart:async';

import 'adapter.dart';
import 'dio_mixin.dart';
import 'options.dart';
import 'headers.dart';
import 'cancel_token.dart';
import 'transformer.dart';
import 'response.dart';

import 'dio/dio_for_native.dart'
    if (dart.library.html) 'dio/dio_for_browser.dart';

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Dio is
/// very easy to use.
///
/// You can create a dio instance and config it by two ways:
/// 1. create first , then config it
///
///   ```dart
///    final dio = Dio();
///    dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
///    dio.options.connectTimeout = const Duration(seconds: 5);
///    dio.options.receiveTimeout = const Duration(seconds: 5);
///    dio.options.headers = {HttpHeaders.userAgentHeader: 'dio', 'common-header': 'xx'};
///   ```
/// 2. create and config it:
///
/// ```dart
///   final dio = Dio(BaseOptions(
///    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
///    connectTimeout: const Duration(seconds: 5),
///    receiveTimeout: const Duration(seconds: 5),
///    headers: {HttpHeaders.userAgentHeader: 'dio', 'common-header': 'xx'},
///   ));
///  ```

abstract class Dio {
  factory Dio([BaseOptions? options]) => createDio(options);

  /// Default Request config. More see [BaseOptions] .
  late BaseOptions options;

  Interceptors get interceptors;

  late HttpClientAdapter httpClientAdapter;

  /// [transformer] allows changes to the request/response data before it is sent/received to/from the server
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
  late Transformer transformer;

  /// Shuts down the dio client.
  ///
  /// If [force] is `false` (the default) the [Dio] will be kept alive
  /// until all active connections are done. If [force] is `true` any active
  /// connections will be closed to immediately release all resources. These
  /// closed connections will receive an error event to indicate that the client
  /// was shut down. In both cases trying to establish a new connection after
  /// calling [close] will throw an exception.
  void close({bool force = false});

  /// Handy method to make http GET request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http GET request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http HEAD request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http HEAD request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http PATCH request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PATCH request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// {@template dio.Dio.download}
  /// Download the file and save it in local. The default http method is "GET",
  /// you can custom it by [Options.method].
  ///
  /// [urlPath] is the file url.
  ///
  /// [savePath] is the path to save the downloading file later. it can be a String or
  /// a callback:
  /// 1. A path with String type, eg "xs.jpg"
  /// 2. A callback `String Function(Headers headers)`; for example:
  /// ```dart
  /// await dio.download(
  ///   url,
  ///   (Headers headers) {
  ///     // Extra info: redirect counts
  ///     print(headers.value('redirects'));
  ///     // Extra info: real uri
  ///     print(headers.value('uri'));
  ///     // ...
  ///     return (await getTemporaryDirectory()).path + 'file_name';
  ///   },
  /// );
  /// ```
  ///
  /// [onReceiveProgress] is the callback to listen downloading progress.
  /// Please refer to [ProgressCallback].
  ///
  /// [deleteOnError] whether delete the file when error occurs.
  /// The default value is [true].
  ///
  /// [lengthHeader] : The real size of original file (not compressed).
  /// When file is compressed:
  /// 1. If this value is 'content-length', the `total` argument of [onReceiveProgress] will be -1
  /// 2. If this value is not 'content-length', maybe a custom header indicates the original
  /// file size , the `total` argument of [onReceiveProgress] will be this header value.
  ///
  /// You can also disable the compression by specifying
  /// the 'accept-encoding' header value as '*' to assure the value of
  /// `total` argument of [onReceiveProgress] is not -1. for example:
  ///
  /// ```dart
  /// await dio.download(
  ///   url,
  ///   (await getTemporaryDirectory()).path + 'flutter.svg',
  ///   options: Options(
  ///     headers: {HttpHeaders.acceptEncodingHeader: "*"}, // Disable gzip
  ///   ),
  ///   onReceiveProgress: (received, total) {
  ///     if (total != -1) {
  ///       print((received / total * 100).toStringAsFixed(0) + "%");
  ///     }
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  });

  /// {@macro dio.Dio.download}
  Future<Response> downloadUri(
    Uri uri,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    return download(
      uri.toString(),
      savePath,
      onReceiveProgress: onReceiveProgress,
      lengthHeader: lengthHeader,
      deleteOnError: deleteOnError,
      cancelToken: cancelToken,
      data: data,
      options: options,
    );
  }

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    Object? data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Response<T>> fetch<T>(RequestOptions requestOptions);
}
