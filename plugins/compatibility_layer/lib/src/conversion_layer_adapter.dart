import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// A conversion layer which translates [Dio] requests to
/// [`http`](https://pub.dev/packages/http) compatible requests.
/// This enables you to use
/// [`cronet_http`](https://pub.dev/packages/cronet_http),
/// [`cupertino_http`](https://pub.dev/packages/cupertino_http),
/// and other `http` compatible packages with [Dio].
class ConversionLayerAdapter implements HttpClientAdapter {
  ConversionLayerAdapter(this.client);

  /// The client instance from the `http` package.
  final http.Client client;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final request = await _fromOptionsAndStream(options, requestStream);
    final response = await client.send(request);
    return ResponseBody(
      response.stream.cast<Uint8List>(),
      response.statusCode,
      statusMessage: response.reasonPhrase,
      isRedirect: response.isRedirect,
      headers: Map.fromEntries(
        response.headers.entries.map((e) => MapEntry(e.key, [e.value])),
      ),
    );
  }

  @override
  void close({bool force = false}) => client.close();

  Future<http.BaseRequest> _fromOptionsAndStream(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) async {
    final http.BaseRequest request;
    if (_kIsWeb && requestStream != null) {
      final normalRequest = request = http.Request(
        options.method,
        options.uri,
      );
      final completer = Completer<Uint8List>();
      final sink = ByteConversionSink.withCallback(
        (bytes) => completer.complete(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        ),
      );
      requestStream.listen(
        sink.add,
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true,
      );
      final bytes = await completer.future;
      normalRequest.bodyBytes = bytes;
    } else if (requestStream != null) {
      final streamedRequest = request = http.StreamedRequest(
        options.method,
        options.uri,
      );
      requestStream.listen(
        streamedRequest.sink.add,
        onError: streamedRequest.sink.addError,
        onDone: streamedRequest.sink.close,
        cancelOnError: true,
      );
    } else {
      request = http.Request(options.method, options.uri);
    }
    request.headers.addAll(
      Map.fromEntries(
        options.headers.entries.map(
          (e) => MapEntry(e.key, e.value.toString().trim()),
        ),
      ),
    );
    request
      ..followRedirects = options.followRedirects
      ..maxRedirects = options.maxRedirects
      ..persistentConnection = options.persistentConnection;
    return request;
  }
}
