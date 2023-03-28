import 'dart:convert';
import 'dart:typed_data';

import 'options.dart';
import 'redirect_record.dart';

import 'adapters/io_adapter.dart'
    if (dart.library.html) 'adapters/browser_adapter.dart' as adapter;

/// [HttpAdapter] is a bridge between [Dio] and [HttpClient].
///
/// [Dio] implements standard and friendly API for developer.
/// [HttpClient] is the real object that makes Http
/// requests.
///
/// We can use any [HttpClient]s not just "dart:io:HttpClient" to
/// make the HTTP request. All we need is to provide a [HttpClientAdapter].
///
/// If you want to customize the [HttpClientAdapter] you should instead use
/// either [IOHttpClientAdapter] on `dart:io` platforms
/// or [BrowserHttpClientAdapter] on `dart:html` platforms.
abstract class HttpClientAdapter {
  /// Create a [HttpClientAdapter] based on the current platform (IO/Web).
  factory HttpClientAdapter() => adapter.createAdapter();

  /// Implement this method to make real HTTP requests.
  ///
  /// [options] are the request options.
  ///
  /// [requestStream] is the request stream. It will not be null only when
  /// the request body is not empty.
  /// Use [requestStream] if your code rely on [RequestOptions.onSendProgress].
  ///
  /// [cancelFuture] will be null when the [CancelToken]
  /// is not set [CancelToken] for the request.
  ///
  /// When the request is cancelled, [cancelFuture] will be resolved.
  /// The adapter can listen cancel event like:
  /// ```dart
  /// cancelFuture?.then((_)=>print("request cancelled!"))
  /// ```
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  );

  /// Close the current adapter and it's inner clients or requests.
  void close({bool force = false});
}

/// The response class used in adapters. Users should not access this directly.
class ResponseBody {
  ResponseBody(
    this.stream,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
    this.redirects,
  });

  ResponseBody.fromString(
    String text,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
  }) : stream = Stream.value(Uint8List.fromList(utf8.encode(text)));

  ResponseBody.fromBytes(
    List<int> bytes,
    this.statusCode, {
    this.headers = const {},
    this.statusMessage,
    this.isRedirect = false,
  }) : stream = Stream.value(Uint8List.fromList(bytes));

  /// The response stream.
  Stream<Uint8List> stream;

  /// The response headers.
  Map<String, List<String>> headers;

  /// HTTP status code.
  int statusCode;

  /// Returns the reason phrase associated with the status code.
  /// The reason phrase must be set before the body is written to.
  /// Setting the reason phrase after writing to the body.
  String? statusMessage;

  /// Whether this response is a redirect.
  final bool isRedirect;

  /// Stores redirections during the request.
  List<RedirectRecord>? redirects;

  Map<String, dynamic> extra = {};
}
