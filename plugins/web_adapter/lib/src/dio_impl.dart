import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'adapter_impl.dart';
import 'download_trigger.dart' as download_trigger;

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
  }) async {
    if (fileAccessMode == FileAccessMode.append) {
      throw UnsupportedError(
        'The append mode is not available when downloading files on Web.',
      );
    }
    if (savePath is! String &&
        savePath is! FutureOr<String> Function(Headers)) {
      throw ArgumentError.value(
        savePath.runtimeType,
        'savePath',
        'The type must be `String` or `FutureOr<String> Function(Headers)`.',
      );
    }

    options ??= Options(method: 'GET');
    // Do not modify previous options.
    options = options.copyWith(responseType: ResponseType.bytes);

    final response = await request<List<int>>(
      urlPath,
      data: data,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    final filename = await _resolveFilename(savePath, response);
    final cancelError = cancelToken?.cancelError;
    if (cancelError != null) {
      throw cancelError;
    }
    final responseBytes = response.data;
    final bytes = responseBytes == null
        ? Uint8List(0)
        : responseBytes is Uint8List
            ? responseBytes
            : Uint8List.fromList(responseBytes);
    try {
      download_trigger.triggerBrowserDownload(
        bytes: bytes,
        filename: filename,
        contentType: response.headers.value(Headers.contentTypeHeader),
      );
    } catch (e, s) {
      if (e is DioException) {
        rethrow;
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: e,
        stackTrace: s,
      );
    }
    return response;
  }
}

Future<String> _resolveFilename(dynamic savePath, Response response) async {
  if (savePath is FutureOr<String> Function(Headers)) {
    response.headers
      ..add('redirects', response.redirects.length.toString())
      ..add('uri', response.realUri.toString());
    return _suggestedFilenameFromPath(await savePath(response.headers));
  }
  return _suggestedFilenameFromPath(savePath as String);
}

String _suggestedFilenameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  final filename = slash == -1 ? normalized : normalized.substring(slash + 1);
  return filename.isEmpty ? 'download' : filename;
}
