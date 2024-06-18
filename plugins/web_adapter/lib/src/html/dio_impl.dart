// export '../js_interop/dio_impl.dart';

import 'dart:async';

import 'package:dio/dio.dart';

import 'adapter.dart';

/// Create the [Dio] instance for Web platforms.
Dio createDio([BaseOptions? options]) => DioForBrowser(options);

/// Implements features for [Dio] on Web platforms.
class DioForBrowser with DioMixin implements Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  DioForBrowser([BaseOptions? options]) {
    this.options = options ?? BaseOptions();
    httpClientAdapter = BrowserHttpClientAdapter();
  }

  @override
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
  }) async {
    final Response response = await fetch(
      RequestOptions(
        baseUrl: urlPath,
        data: data,
        method: 'GET',
        responseType: ResponseType.blobUrl,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );

    final completer = Completer<Response>();

    // Set response in Completer
    completer.complete(response);

    return DioMixin.listenCancelForAsyncTask(cancelToken, completer.future);
  }
}
