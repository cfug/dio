import 'package:dio/dio.dart';

import 'adapter_impl.dart';

/// Create the [Dio] instance for Web platforms.
Dio createDio([BaseOptions? options]) => DioForBrowser(options);

/// Implements features for [Dio] on Web platforms.
class DioForBrowser with DioMixin implements Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  DioForBrowser([BaseOptions? baseOptions]) {
    options = baseOptions ?? BaseOptions();
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
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    throw UnsupportedError(
      'The download method is not available in the Web environment.',
    );
  }
}
