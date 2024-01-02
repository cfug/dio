import '../../cancel_token.dart';
import '../../headers.dart';
import '../../options.dart';
import '../../response.dart';
import '../../transformer.dart';

import 'io_download_adapter.dart'
    if (dart.library.html) 'browser_download_adapter.dart' as adapter;

typedef RequestCallback = Future<Response<T>> Function<T>(
  String url, {
  Object? data,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  Options? options,
  ProgressCallback? onSendProgress,
  ProgressCallback? onReceiveProgress,
});

abstract class DownloadAdapter {
  factory DownloadAdapter() => adapter.createAdapter();

  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    required RequestCallback request,
    required Transformer transformer,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  });
}
