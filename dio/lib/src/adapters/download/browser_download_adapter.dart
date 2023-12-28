import '../../cancel_token.dart';
import '../../headers.dart';
import '../../options.dart';
import '../../response.dart';
import '../../transformer.dart';
import 'download_adapter.dart';

DownloadAdapter createAdapter() => BrowserDownloadAdapter();

class BrowserDownloadAdapter implements DownloadAdapter {
  @override
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
  }) {
    throw UnsupportedError(
      'The download method is not available in the Web environment.',
    );
  }
}
