import 'dart:async';
import 'adapter.dart';
import 'dio_mixin.dart';
import 'options.dart';
import 'headers.dart';
import 'cancel_token.dart';
import 'transformer.dart';
import 'response.dart';
import 'entry_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'entry/dio_for_browser.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'entry/dio_for_native.dart';

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Dio is
/// very easy to use.
///
/// You can create a dio instance and config it by two ways:
/// 1. create first , then config it
///
///   ```dart
///    var dio = Dio();
///    dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
///    dio.options.connectTimeout = 5000; //5s
///    dio.options.receiveTimeout = 5000;
///    dio.options.headers = {HttpHeaders.userAgentHeader: 'dio', 'common-header': 'xx'};
///   ```
/// 2. create and config it:
///
/// ```dart
///   var dio = Dio(BaseOptions(
///    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
///    connectTimeout: 5000,
///    receiveTimeout: 5000,
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
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http GET request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http POST request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PUT request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http HEAD request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http HEAD request, which is a alias of [dio.fetch(RequestOptions)].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http DELETE request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Handy method to make http PATCH request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Handy method to make http PATCH request, which is a alias of  [dio.fetch(RequestOptions)].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  /// Lock the current Dio instance.
  ///
  /// Dio will enqueue the incoming request tasks instead
  /// send them directly when [interceptor.requestOptions] is locked.
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  void lock();

  /// Unlock the current Dio instance.
  ///
  /// Dio instance dequeue the request task。
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  void unlock();

  ///Clear the current Dio instance waiting queue.
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  void clear();

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [urlPath]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(Headers headers)`; for example:
  ///  ```dart
  ///   await dio.download(url,(Headers headers){
  ///        // Extra info: redirect counts
  ///        print(headers.value('redirects'));
  ///        // Extra info: real uri
  ///        print(headers.value('uri'));
  ///      ...
  ///      return "...";
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  /// [deleteOnError] Whether delete the file when error occurs. The default value is [true].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await dio.download(url, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });

  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  });

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [uri]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(Headers)`; for example:
  ///  ```dart
  ///   await dio.downloadUri(uri,(Headers headers){
  ///        // Extra info: redirect counts
  ///        print(headers.value('redirects'));
  ///        // Extra info: real uri
  ///        print(headers.value('uri'));
  ///       ...
  ///       return "...";
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await dio.downloadUri(uri, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  });

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  Future<Response<T>> request<T>(
    String path, {
    data,
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
    data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Response<T>> fetch<T>(RequestOptions requestOptions);
}
