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
    Future<void>? cancelFuture,
  ) async {
    final timeoutCompleter = Completer<void>();

    // Completes [timeoutCompleter] at most once. This is used to release the
    // abort-trigger future chain so that native resources (e.g. the Cronet
    // UrlRequest JNI reference and the upload body bytes) can be garbage
    // collected after the request/response cycle is finished.
    void completeTimeout() {
      if (!timeoutCompleter.isCompleted) {
        timeoutCompleter.complete();
      }
    }

    final cancelToken = cancelFuture != null
        ? Future.any([cancelFuture, timeoutCompleter.future])
        : timeoutCompleter.future;
    final requestFuture = _fromOptionsAndStream(
      options,
      requestStream,
      cancelToken,
    );

    final sendTimeout = options.sendTimeout ?? Duration.zero;
    final BaseRequest request;
    if (sendTimeout == Duration.zero) {
      request = await requestFuture;
    } else {
      request = await requestFuture.timeout(
        sendTimeout,
        onTimeout: () {
          timeoutCompleter.complete();
          throw DioException.sendTimeout(
            timeout: sendTimeout,
            requestOptions: options,
          );
        },
      );
    }

    // http package doesn't separate connect and receive phases,
    // so we combine both timeouts for client.send()
    final connectTimeout = options.connectTimeout ?? Duration.zero;
    final receiveTimeout = options.receiveTimeout ?? Duration.zero;
    final totalTimeout = connectTimeout + receiveTimeout;
    final StreamedResponse response;
    try {
      if (totalTimeout == Duration.zero) {
        response = await client.send(request);
      } else {
        response = await client.send(request).timeout(
          totalTimeout,
          onTimeout: () {
            timeoutCompleter.complete();
            throw DioException.receiveTimeout(
              timeout: totalTimeout,
              requestOptions: options,
            );
          },
        );
      }
    } catch (_) {
      // Release the abort-trigger future chain on any send error so that
      // native resources held by the request are freed promptly.
      completeTimeout();
      rethrow;
    }

    // Wrap the response stream so that [timeoutCompleter] is completed when
    // the stream ends (successfully or with an error). This ensures that the
    // abort-trigger registered by native clients (e.g. CronetClient) is
    // resolved, allowing the native request object and the upload body bytes
    // to be garbage collected.
    return response.toDioResponseBody(options, onStreamDone: completeTimeout);
  }

  @override
  void close({bool force = false}) => client.close();

  Future<BaseRequest> _fromOptionsAndStream(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void> cancelFuture,
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
  ResponseBody toDioResponseBody(
    RequestOptions options, {
    void Function()? onStreamDone,
  }) {
    final dioHeaders = headers.entries.map(
      (e) => MapEntry(
        options.preserveHeaderCase ? e.key : e.key.toLowerCase(),
        [e.value],
      ),
    );
    Stream<Uint8List> responseStream = stream.cast<Uint8List>();
    if (onStreamDone != null) {
      // Wrap the stream so that [onStreamDone] is invoked when the response
      // body is fully consumed or encounters an error. This allows callers to
      // release resources (e.g. native request objects and upload body bytes)
      // that were kept alive only to support request abort / cancellation.
      responseStream = responseStream.transform(
        StreamTransformer.fromHandlers(
          handleDone: (sink) {
            onStreamDone();
            sink.close();
          },
          handleError: (error, stack, sink) {
            onStreamDone();
            sink.addError(error, stack);
          },
        ),
      );
    }
    return ResponseBody(
      responseStream,
      statusCode,
      headers: Map.fromEntries(dioHeaders),
      isRedirect: isRedirect,
      statusMessage: reasonPhrase,
    );
  }
}
