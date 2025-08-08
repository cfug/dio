import 'dart:async' show Completer;
import 'dart:convert' show ByteConversionSink;
import 'dart:typed_data' show Uint8List;

import 'package:dio/dio.dart';
import 'package:http/http.dart';

/// A conversion layer which translates Dio HTTP requests to
/// [http](https://pub.dev/packages/http) compatible requests.
/// This way there's no need to implement custom [HttpClientAdapter]
/// for each platform. Therefore, the required effort to add tests is kept
/// to a minimum. Since `CupertinoClient` and `CronetClient` depend anyway on
/// `http` this also doesn't add any additional dependency.
class ConversionLayerAdapter implements HttpClientAdapter {
  ConversionLayerAdapter(this.client);

  /// The underlying http client.
  final Client client;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final request = await _fromOptionsAndStream(
      options,
      requestStream,
      cancelFuture,
    );
    final response = await client.send(request);
    return response.toDioResponseBody(options);
  }

  @override
  void close({bool force = false}) => client.close();

  Future<BaseRequest> _fromOptionsAndStream(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    final request = AbortableRequest(
      options.method,
      options.uri,
      abortTrigger: cancelFuture,
    );

    request.headers.addAll(
      Map.fromEntries(
        options.headers.entries.map(
          (e) => MapEntry(
            options.preserveHeaderCase ? e.key : e.key.toLowerCase(),
            e.value.toString(),
          ),
        ),
      ),
    );

    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;

    if (requestStream != null) {
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
      request.bodyBytes = bytes;
    }
    return request;
  }
}

extension on StreamedResponse {
  ResponseBody toDioResponseBody(RequestOptions options) {
    final dioHeaders = headers.entries.map(
      (e) => MapEntry(
        options.preserveHeaderCase ? e.key : e.key.toLowerCase(),
        [e.value],
      ),
    );
    return ResponseBody(
      stream.cast<Uint8List>(),
      statusCode,
      headers: Map.fromEntries(dioHeaders),
      isRedirect: isRedirect,
      statusMessage: reasonPhrase,
    );
  }
}
