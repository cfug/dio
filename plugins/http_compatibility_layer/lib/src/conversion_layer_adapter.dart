import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// A conversion layer which translates Dio HTTP requests to
/// [http](https://pub.dev/packages/http) compatible requests.
/// This way there's no need to implement custom [HttpClientAdapter]
/// for each platform. Therefore, the required effort to add tests is kept
/// to a minimum. Since `CupertinoClient` and `CronetClient` depend anyway on
/// `http` this also doesn't add any additional dependency.
class ConversionLayerAdapter implements HttpClientAdapter {
  ConversionLayerAdapter(this.client);

  final Client client;

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
      isRedirect: response.isRedirect,
      statusMessage: response.reasonPhrase,
      headers: Map.fromEntries(
        response.headers.entries.map((e) => MapEntry(e.key, [e.value])),
      ),
    );
  }

  @override
  void close({bool force = false}) => client.close();

  Future<BaseRequest> _fromOptionsAndStream(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) async {
    final BaseRequest request;
    if (_kIsWeb && requestStream != null) {
      final normalRequest = request = Request(
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
      final streamedRequest = request = StreamedRequest(
        options.method,
        options.uri,
      );
      requestStream.listen(streamedRequest.sink.add);
    } else {
      request = Request(options.method, options.uri);
    }
    request.headers.addAll(
      Map.fromEntries(
        options.headers.entries.map(
          (e) => MapEntry(e.key, e.value.toString().trim()),
        ),
      ),
    );
    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;
    return request;
  }
}
