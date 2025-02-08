import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/utils.dart';
import 'package:web/web.dart' as web;

import 'fetch/readable_stream.dart';
import 'fetch/readable_stream_source.dart';

BrowserHttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

/// The default [HttpClientAdapter] for Web platforms.
class BrowserHttpClientAdapter implements HttpClientAdapter {
  BrowserHttpClientAdapter({this.withCredentials = false});

  /// These are aborted if the client is closed.
  final _abortables = <web.AbortController>{};

  /// Whether to send credentials such as cookies or authorization headers for
  /// cross-site requests.
  ///
  /// Defaults to `false`.
  ///
  /// You can also override this value using `Options.extra['withCredentials']`
  /// for each request.
  bool withCredentials;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = web.RequestInit(
      method: options.method,
      redirect: options.followRedirects ? 'follow' : 'error',
    );

    final withCredentialsOption = options.extra['withCredentials'] != null
        ? options.extra['withCredentials'] == true
        : withCredentials;
    request.credentials = withCredentialsOption ? 'include' : 'same-origin';

    options.headers.remove(Headers.contentLengthHeader);
    options.headers.forEach((key, v) {
      if (v is Iterable) {
        request.headers.setProperty(key.toJS, v.join(', ').toJS);
      } else {
        request.headers.setProperty(key.toJS, v.toString().toJS);
      }
    });

    final onSendProgress = options.onSendProgress;
    final sendTimeout = options.sendTimeout ?? Duration.zero;
    final connectTimeout = options.connectTimeout ?? Duration.zero;
    final receiveTimeout = options.receiveTimeout ?? Duration.zero;

    final fetchTimeout = connectTimeout + receiveTimeout;
    final abortController = web.AbortController();
    request.signal = abortController.signal;
    _abortables.add(abortController);

    final completer = Completer<ResponseBody>();

    cancelFuture?.then((_) {
      try {
        abortController.abort();
      } catch (_) {}
      if (!completer.isCompleted) {
        completer.completeError(
          DioException.requestCancelled(
            requestOptions: options,
            reason: 'The Fetch request was aborted.',
          ),
        );
      }
    });

    if (requestStream == null) {
      if (sendTimeout > Duration.zero) {
        warningLog(
          'sendTimeout cannot be used without a request body to send on Web',
          StackTrace.current,
        );
      }
      if (onSendProgress != null) {
        warningLog(
          'onSendProgress cannot be used without a request body to send on Web',
          StackTrace.current,
        );
      }
    } else {
      if (options.method == 'GET') {
        warningLog(
          'GET request with a body data are not support on the '
          'web platform. Use POST/PUT instead.',
          StackTrace.current,
        );
      }

      Stopwatch? uploadStopwatch;
      if (sendTimeout > Duration.zero) {
        uploadStopwatch = Stopwatch();
      }

      int sentBytes = 0;
      final streamReader = ReadableStream(
        ReadableStreamSource.fromStream(
          requestStream.map((e) {
            if (uploadStopwatch != null) {
              if (!uploadStopwatch.isRunning) {
                uploadStopwatch.start();
              }

              if (uploadStopwatch.elapsed > sendTimeout) {
                uploadStopwatch.stop();
                completer.completeError(
                  DioException.sendTimeout(
                    timeout: sendTimeout,
                    requestOptions: options,
                  ),
                  StackTrace.current,
                );
                abortController.abort();
              }
            }

            sentBytes += e.lengthInBytes;
            if (options.onSendProgress != null) {
              options.onSendProgress!(sentBytes, -1);
            }
            return e.toJS;
          }),
        ),
      );

      request.body = streamReader;
    }

    // Now send
    final Future<web.Response> requestPrototype =
        web.window.fetch(options.uri.toString().toJS, request).toDart;

    late final web.Response response;
    try {
      if (fetchTimeout > Duration.zero) {
        response = await requestPrototype.timeout(fetchTimeout);
      } else {
        response = await requestPrototype;
      }
    } on TimeoutException catch (timeoutException) {
      completer.completeError(
        DioException.connectionTimeout(
          timeout: connectTimeout,
          error: timeoutException,
          requestOptions: options,
        ),
      );

      return completer.future;
    } catch (exception, stackTrace) {
      completer.completeError(
        DioException.connectionError(
          requestOptions: options,
          error: exception,
          reason: 'The Fetch operation threw an exception. '
              'This typically indicates an error on the network layer.',
        ),
        stackTrace,
      );

      return completer.future;
    }

    Stopwatch? receiveStopwatch;
    if (receiveTimeout > Duration.zero) {
      receiveStopwatch = Stopwatch();
    }

    final Map<String, List<String>> headers = {};
    final _IterableHeaders responseHeaders =
        response.headers as _IterableHeaders;
    responseHeaders.forEach(
      (String value, String header, [JSAny? _]) {
        headers[header.toLowerCase()] = [value];
      }.toJS,
    );

    final BytesBuilder receivedBody = BytesBuilder();
    final int totalResponseLength = int.tryParse(
          response.headers.get(Headers.contentLengthHeader) ?? '-1',
        ) ??
        -1;

    if (response.body != null) {
      receiveStopwatch?.start();

      final web.ReadableStreamDefaultReader reader =
          response.body!.getReader() as web.ReadableStreamDefaultReader;
      StreamController<Uint8List>? dataStreamController;
      if (options.responseType == ResponseType.stream) {
        dataStreamController = StreamController(
          onCancel: () {
            // Abort
            abortController.abort();
          },
        );
      }

      Future readResponse() async {
        int totalRead = 0;
        while (true) {
          final web.ReadableStreamReadResult chunk = await reader.read().toDart;
          if (chunk.done) {
            dataStreamController?.close();
            break;
          }

          if (receiveStopwatch != null &&
              receiveStopwatch.elapsed > receiveTimeout) {
            receiveStopwatch.stop();
            abortController.abort();

            completer.completeError(
              DioException.receiveTimeout(
                timeout: receiveTimeout,
                requestOptions: options,
              ),
              StackTrace.current,
            );
          }

          // https://developer.mozilla.org/en-US/docs/Web/API/ReadableStreamDefaultReader/read#examples
          final Uint8List payload = (chunk.value as JSUint8Array).toDart;
          totalRead += payload.lengthInBytes;
          if (options.responseType == ResponseType.stream) {
            dataStreamController!.add(payload);
          } else {
            receivedBody.add(payload);
          }
          if (options.onReceiveProgress != null) {
            options.onReceiveProgress!(totalRead, totalResponseLength);
          }
        }
      }

      if (options.responseType == ResponseType.stream) {
        readResponse();

        completer.complete(
          ResponseBody(
            dataStreamController!.stream,
            response.status,
            statusMessage: response.statusText,
            headers: headers,
            isRedirect: response.redirected,
          ),
        );
      } else {
        await readResponse();

        completer.complete(
          ResponseBody.fromBytes(
            receivedBody.toBytes(),
            response.status,
            statusMessage: response.statusText,
            headers: headers,
            isRedirect: response.redirected,
          ),
        );
      }
    } else {
      // No response data

      completer.complete(
        ResponseBody.fromBytes(
          Uint8List(0),
          response.status,
          statusMessage: response.statusText,
          headers: headers,
          isRedirect: response.redirected,
        ),
      );
    }

    return completer.future.whenComplete(() {
      _abortables.remove(abortController);
    });
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close({bool force = false}) {
    if (force) {
      for (final abortable in _abortables) {
        abortable.abort();
      }
    }
    _abortables.clear();
  }
}

/// Workaround for `Headers` not providing a way to iterate the headers.
/// https://github.com/dart-lang/http/blob/aadf8363a83dd211bb56c36ac301396437b9282b/pkgs/http/lib/src/browser_client.dart#L184
@JS()
extension type _IterableHeaders._(JSObject _) implements JSObject {
  external void forEach(JSFunction fn);
}
