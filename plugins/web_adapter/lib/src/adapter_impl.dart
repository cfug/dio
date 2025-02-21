import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/utils.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

BrowserHttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

/// The default [HttpClientAdapter] for Web platforms.
class BrowserHttpClientAdapter implements HttpClientAdapter {
  BrowserHttpClientAdapter({this.withCredentials = false});

  /// These are aborted if the client is closed.
  @visibleForTesting
  final xhrs = <web.XMLHttpRequest>{};

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
    final xhr = web.XMLHttpRequest();
    xhrs.add(xhr);
    xhr
      ..open(options.method, '${options.uri}')
      ..responseType = 'arraybuffer';

    final withCredentialsOption = options.extra['withCredentials'];
    if (withCredentialsOption != null) {
      xhr.withCredentials = withCredentialsOption == true;
    } else {
      xhr.withCredentials = withCredentials;
    }

    options.headers.remove(Headers.contentLengthHeader);
    options.headers.forEach((key, v) {
      if (v is Iterable) {
        xhr.setRequestHeader(key, v.join(', '));
      } else {
        xhr.setRequestHeader(key, v.toString());
      }
    });

    final onSendProgress = options.onSendProgress;
    final sendTimeout = options.sendTimeout ?? Duration.zero;
    final connectTimeout = options.connectTimeout ?? Duration.zero;
    final receiveTimeout = options.receiveTimeout ?? Duration.zero;

    final xhrTimeout = (connectTimeout + receiveTimeout).inMilliseconds;
    xhr.timeout = xhrTimeout;

    final completer = Completer<ResponseBody>();

    xhr.onLoad.first.then((_) {
      final ByteBuffer body = (xhr.response as JSArrayBuffer).toDart;
      completer.complete(
        ResponseBody.fromBytes(
          body.asUint8List(),
          xhr.status,
          headers: xhr.getResponseHeaders(),
          statusMessage: xhr.statusText,
          isRedirect: xhr.status == 302 ||
              xhr.status == 301 ||
              options.uri.toString() != xhr.responseURL,
        ),
      );
    });

    Timer? connectTimeoutTimer;
    if (connectTimeout > Duration.zero) {
      connectTimeoutTimer = Timer(
        connectTimeout,
        () {
          connectTimeoutTimer = null;
          if (completer.isCompleted) {
            // connectTimeout is triggered after the fetch has been completed.
            return;
          }
          xhr.abort();
          completer.completeError(
            DioException.connectionTimeout(
              requestOptions: options,
              timeout: connectTimeout,
            ),
            StackTrace.current,
          );
        },
      );
    }

    // This code is structured to call `xhr.upload.onProgress.listen` only when
    // absolutely necessary, because registering an xhr upload listener prevents
    // the request from being classified as a "simple request" by the CORS spec.
    // Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests
    // Upload progress events only get triggered if the request body exists,
    // so we can check it beforehand.
    if (requestStream != null) {
      final xhrUploadProgressStream =
          web.EventStreamProviders.progressEvent.forTarget(xhr.upload);

      if (connectTimeoutTimer != null) {
        xhrUploadProgressStream.listen((_) {
          connectTimeoutTimer?.cancel();
          connectTimeoutTimer = null;
        });
      }

      if (sendTimeout > Duration.zero) {
        final uploadStopwatch = Stopwatch();
        xhrUploadProgressStream.listen((_) {
          if (!uploadStopwatch.isRunning) {
            uploadStopwatch.start();
          }
          final duration = uploadStopwatch.elapsed;
          if (duration > sendTimeout) {
            uploadStopwatch.stop();
            completer.completeError(
              DioException.sendTimeout(
                timeout: sendTimeout,
                requestOptions: options,
              ),
              StackTrace.current,
            );
            xhr.abort();
          }
        });
      }

      if (onSendProgress != null) {
        xhrUploadProgressStream.listen((event) {
          onSendProgress(event.loaded, event.total);
        });
      }
    } else {
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
    }

    final receiveStopwatch = Stopwatch();
    Timer? receiveTimer;

    void stopWatchReceiveTimeout() {
      receiveTimer?.cancel();
      receiveTimer = null;
      receiveStopwatch.stop();
    }

    void watchReceiveTimeout() {
      if (receiveTimeout <= Duration.zero) {
        return;
      }
      receiveStopwatch.reset();
      if (!receiveStopwatch.isRunning) {
        receiveStopwatch.start();
      }
      receiveTimer?.cancel();
      receiveTimer = Timer(receiveTimeout, () {
        if (!completer.isCompleted) {
          xhr.abort();
          completer.completeError(
            DioException.receiveTimeout(
              timeout: receiveTimeout,
              requestOptions: options,
            ),
            StackTrace.current,
          );
        }
        stopWatchReceiveTimeout();
      });
    }

    xhr.onProgress.listen(
      (event) {
        if (connectTimeoutTimer != null) {
          connectTimeoutTimer!.cancel();
          connectTimeoutTimer = null;
        }
        watchReceiveTimeout();
        if (options.onReceiveProgress != null) {
          options.onReceiveProgress!(event.loaded, event.total);
        }
      },
      onDone: () => stopWatchReceiveTimeout(),
    );

    xhr.onError.first.then((_) {
      connectTimeoutTimer?.cancel();
      // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
      // specific information about the error itself.
      // See also: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequestEventTarget/onerror
      completer.completeError(
        DioException.connectionError(
          requestOptions: options,
          reason: 'The XMLHttpRequest onError callback was called. '
              'This typically indicates an error on the network layer.',
        ),
        StackTrace.current,
      );
    });

    web.EventStreamProviders.timeoutEvent.forTarget(xhr).first.then((_) {
      final isConnectTimeout = connectTimeoutTimer != null;
      if (connectTimeoutTimer != null) {
        connectTimeoutTimer?.cancel();
      }
      if (!completer.isCompleted) {
        if (isConnectTimeout) {
          completer.completeError(
            DioException.connectionTimeout(
              timeout: connectTimeout,
              requestOptions: options,
            ),
          );
        } else {
          completer.completeError(
            DioException.receiveTimeout(
              timeout: Duration(milliseconds: xhrTimeout),
              requestOptions: options,
            ),
            StackTrace.current,
          );
        }
      }
    });

    cancelFuture?.then((_) {
      if (xhr.readyState < web.XMLHttpRequest.DONE &&
          xhr.readyState > web.XMLHttpRequest.UNSENT) {
        connectTimeoutTimer?.cancel();
        try {
          xhr.abort();
        } catch (_) {}
        if (!completer.isCompleted) {
          completer.completeError(
            DioException.requestCancelled(
              requestOptions: options,
              reason: 'The XMLHttpRequest was aborted.',
            ),
          );
        }
      }
    });

    if (requestStream != null) {
      if (options.method == 'GET') {
        warningLog(
          'GET request with a body data are not support on the '
          'web platform. Use POST/PUT instead.',
          StackTrace.current,
        );
      }
      final completer = Completer<Uint8List>();
      final sink = ByteConversionSink.withCallback(
        (bytes) => completer.complete(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        ),
      );
      requestStream.listen(
        sink.add,
        onError: (Object e, StackTrace s) => completer.completeError(e, s),
        onDone: sink.close,
        cancelOnError: true,
      );
      final bytes = await completer.future;
      xhr.send(bytes.toJS);
    } else {
      xhr.send();
    }
    return completer.future.whenComplete(() {
      xhrs.remove(xhr);
    });
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close({bool force = false}) {
    if (force) {
      for (final xhr in xhrs) {
        xhr.abort();
      }
    }
    xhrs.clear();
  }
}

extension on web.XMLHttpRequest {
  Map<String, List<String>> getResponseHeaders() {
    final headersString = getAllResponseHeaders();
    final headers = <String, List<String>>{};
    if (headersString.isEmpty) {
      return headers;
    }
    final headersList = headersString.split('\r\n');
    for (final header in headersList) {
      if (header.isEmpty) {
        continue;
      }

      final splitIdx = header.indexOf(': ');
      if (splitIdx == -1) {
        continue;
      }
      final key = header.substring(0, splitIdx).toLowerCase();
      final value = header.substring(splitIdx + 2);
      (headers[key] ??= []).add(value);
    }
    return headers;
  }
}
