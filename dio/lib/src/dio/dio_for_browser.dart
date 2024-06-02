import 'dart:async';
import 'dart:html';

import '../../dio.dart';
import '../adapters/browser_adapter.dart';

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
    options ??= DioMixin.checkOptions('GET', options);

    // Set receiveTimeout to 48 hours because `Duration.zero` not work!
    options=options.copyWith(receiveTimeout: const Duration(hours: 48));

    final Response response = await request(
      urlPath,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    final completer = Completer<Response>();

    // Create blob url from byte data
    response.data = Url.createObjectUrlFromBlob(Blob([response.data]));

    // Set response in Completer
    completer.complete(response);

    return DioMixin.listenCancelForAsyncTask(cancelToken, completer.future);
  }
}
