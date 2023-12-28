import 'dart:convert';
import 'dart:typed_data';

import '../options.dart';
import '../redirect_record.dart';

import 'io_adapter.dart'
    if (dart.library.html) 'browser_adapter.dart' as adapter;

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
  /// [cancelFuture] corresponds to [CancelToken] handling.
  /// When the request is canceled, [cancelFuture] will be resolved.
  /// To await if a request has been canceled:
  /// ```dart
  /// cancelFuture?.then((_) => print('request cancelled!'));
  /// ```
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  );

  /// Close the current adapter and its inner clients or requests.
  void close({bool force = false});
}

/// The response wrapper class for adapters.
///
/// This class should not be used in regular usages.
class ResponseBody {
  ResponseBody(
    this.stream,
    this.statusCode, {
    this.statusMessage,
    this.isRedirect = false,
    this.redirects,
    Map<String, List<String>>? headers,
  }) : headers = headers ?? {};

  ResponseBody.fromString(
    String text,
    this.statusCode, {
    this.statusMessage,
    this.isRedirect = false,
    Map<String, List<String>>? headers,
  })  : stream = Stream.value(Uint8List.fromList(utf8.encode(text))),
        headers = headers ?? {};

  ResponseBody.fromBytes(
    List<int> bytes,
    this.statusCode, {
    this.statusMessage,
    this.isRedirect = false,
    Map<String, List<String>>? headers,
  })  : stream = Stream.value(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        ),
        headers = headers ?? {};

  /// Whether this response is a redirect.
  final bool isRedirect;

  /// The response stream.
  Stream<Uint8List> stream;

  /// HTTP status code.
  int statusCode;

  /// Returns the reason phrase corresponds to the status code.
  /// The message can be [HttpRequest.statusText]
  /// or [HttpClientResponse.reasonPhrase].
  String? statusMessage;

  /// Stores redirections during the request.
  List<RedirectRecord>? redirects;

  /// The response headers.
  Map<String, List<String>> headers;

  /// The extra field which will pass-through to the [Response.extra].
  Map<String, dynamic> extra = {};
}
