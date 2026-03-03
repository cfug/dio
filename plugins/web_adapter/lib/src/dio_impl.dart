import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

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

  /// {@macro dio.Dio.download}
  ///
  /// ## Web Implementation Notes
  ///
  /// On web platforms, this method works differently than on native platforms:
  ///
  /// - The [savePath] parameter is used as the **suggested filename** for the
  ///   browser's "Save As" dialog. If [savePath] is a path string like
  ///   `/path/to/file.pdf`, only the filename portion (`file.pdf`) is used.
  /// - If [savePath] is a callback function `FutureOr<String> Function(Headers)`,
  ///   the returned string is used as the suggested filename.
  /// - The actual save location is determined by the user through the browser's
  ///   download dialog or the browser's default download settings.
  /// - The [deleteOnError] parameter is ignored on web.
  /// - The [fileAccessMode] parameter is ignored on web.
  /// - The entire file is loaded into memory before triggering the download,
  ///   which may not be suitable for very large files.
  /// - Progress tracking via [onReceiveProgress] is fully supported.
  /// - Cancellation via [cancelToken] works during the fetch phase.
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
    // Validate savePath type early
    if (savePath is! String && savePath is! HeadersCallback) {
      throw ArgumentError.value(
        savePath.runtimeType,
        'savePath',
        'The type must be `String` or `FutureOr<String> Function(Headers)`.',
      );
    }

    // Prepare request options
    final requestOptions =
        (options ?? Options()).copyWith(responseType: ResponseType.bytes);

    // Make the request
    final Response<List<int>> response = await request<List<int>>(
      urlPath,
      data: data,
      options: requestOptions,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );

    // Determine filename from callback if needed
    final String filename;
    if (savePath is String) {
      filename = _extractFilename(savePath, urlPath);
    } else if (savePath is HeadersCallback) {
      final callbackResult = await savePath(response.headers);
      filename = _extractFilename(callbackResult, urlPath);
    } else {
      throw ArgumentError.value(
        savePath.runtimeType,
        'savePath',
        'The type must be `String` or `FutureOr<String> Function(Headers)`.',
      );
    }

    // Get content type from response headers
    final contentType = response.headers.value(Headers.contentTypeHeader);

    // Trigger browser download
    _triggerBrowserDownload(
      response.data!,
      filename,
      contentType,
    );

    return Response<dynamic>(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      redirects: response.redirects,
      extra: response.extra,
    );
  }

  /// Extracts the filename from a path string or URL.
  String _extractFilename(String path, String urlPath) {
    // Try to get filename from the provided path
    final pathSegments = path.split(RegExp(r'[/\\]'));
    final filenameFromPath = pathSegments.last;

    if (filenameFromPath.isNotEmpty && filenameFromPath.contains('.')) {
      return filenameFromPath;
    }

    // Fallback: try to extract from URL
    try {
      final uri = Uri.parse(urlPath);
      if (uri.pathSegments.isNotEmpty) {
        final urlFilename = uri.pathSegments.last;
        if (urlFilename.isNotEmpty) {
          return urlFilename;
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

    // Final fallback
    return filenameFromPath.isNotEmpty ? filenameFromPath : 'download';
  }

  /// Triggers a browser download using the Blob API.
  void _triggerBrowserDownload(
    List<int> bytes,
    String filename,
    String? mimeType,
  ) {
    final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    // Create a Blob from the bytes
    final blob = web.Blob(
      <JSUint8Array>[uint8List.toJS].toJS,
      web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
    );

    // Create an object URL for the blob
    final url = web.URL.createObjectURL(blob);

    // Create an anchor element and trigger the download
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = filename
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);

    // Clean up the object URL
    web.URL.revokeObjectURL(url);
  }
}

/// Type alias for the savePath callback function.
typedef HeadersCallback = FutureOr<String> Function(Headers headers);
