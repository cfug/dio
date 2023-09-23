import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../adapter.dart';
import '../dio_exception.dart';
import '../headers.dart';
import '../options.dart';
import '../utils.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

/// The default [HttpClientAdapter] for Web platforms.
class BrowserHttpClientAdapter implements HttpClientAdapter {
  BrowserHttpClientAdapter({this.withCredentials = false});

  /// These are aborted if the client is closed.
  @visibleForTesting
  final xhrs = <HttpRequest>{};

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
    final xhr = HttpRequest();
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

    final connectTimeout = options.connectTimeout;
    final receiveTimeout = options.receiveTimeout;
    int xhrTimeout = 0;
    if (connectTimeout != null &&
        receiveTimeout != null &&
        receiveTimeout > Duration.zero) {
      xhrTimeout = (connectTimeout + receiveTimeout).inMilliseconds;
      xhr.timeout = xhrTimeout;
    }

    final completer = Completer<ResponseBody>();

    xhr.onLoad.first.then((_) {
      final Uint8List body = (xhr.response as ByteBuffer).asUint8List();
      completer.complete(
        ResponseBody.fromBytes(
          body,
          xhr.status!,
          headers: xhr.responseHeaders.map((k, v) => MapEntry(k, v.split(','))),
          statusMessage: xhr.statusText,
          isRedirect: xhr.status == 302 ||
              xhr.status == 301 ||
              options.uri.toString() != xhr.responseUrl,
        ),
      );
    });

    Timer? connectTimeoutTimer;

    final connectionTimeout = options.connectTimeout;
    if (connectionTimeout != null) {
      connectTimeoutTimer = Timer(
        connectionTimeout,
        () {
          if (completer.isCompleted) {
            // connectTimeout is triggered after the fetch has been completed.
            return;
          }

          xhr.abort();
          completer.completeError(
            DioException.connectionTimeout(
              requestOptions: options,
              timeout: connectionTimeout,
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
      if (connectTimeoutTimer != null) {
        xhr.upload.onProgress.listen((event) {
          connectTimeoutTimer?.cancel();
          connectTimeoutTimer = null;
        });
      }

      final sendTimeout = options.sendTimeout;
      if (sendTimeout != null) {
        final uploadStopwatch = Stopwatch();
        xhr.upload.onProgress.listen((event) {
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

      final onSendProgress = options.onSendProgress;
      if (onSendProgress != null) {
        xhr.upload.onProgress.listen((event) {
          if (event.loaded != null && event.total != null) {
            onSendProgress(event.loaded!, event.total!);
          }
        });
      }
    } else {
      if (options.sendTimeout != null) {
        debugLog(
          'sendTimeout cannot be used without a request body to send',
          StackTrace.current,
        );
      }
      if (options.onSendProgress != null) {
        debugLog(
          'onSendProgress cannot be used without a request body to send',
          StackTrace.current,
        );
      }
    }

    final downloadStopwatch = Stopwatch();
    xhr.onProgress.listen((event) {
      if (connectTimeoutTimer != null) {
        connectTimeoutTimer!.cancel();
        connectTimeoutTimer = null;
      }

      final receiveTimeout = options.receiveTimeout;
      if (receiveTimeout != null) {
        if (!downloadStopwatch.isRunning) {
          downloadStopwatch.start();
        }

        final duration = downloadStopwatch.elapsed;
        if (duration > receiveTimeout) {
          downloadStopwatch.stop();
          completer.completeError(
            DioException.receiveTimeout(
              timeout: options.receiveTimeout!,
              requestOptions: options,
            ),
            StackTrace.current,
          );
          xhr.abort();
        }
      }
      if (options.onReceiveProgress != null) {
        if (event.loaded != null && event.total != null) {
          options.onReceiveProgress!(event.loaded!, event.total!);
        }
      }
    });

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

    xhr.onTimeout.first.then((_) {
      if (connectTimeoutTimer != null) {
        connectTimeoutTimer?.cancel();
      }
      if (!completer.isCompleted) {
        completer.completeError(
          DioException.receiveTimeout(
            timeout: Duration(milliseconds: xhrTimeout),
            requestOptions: options,
          ),
          StackTrace.current,
        );
      }
    });

    cancelFuture?.then((_) {
      if (xhr.readyState < HttpRequest.DONE &&
          xhr.readyState > HttpRequest.UNSENT) {
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
        debugLog(
          'GET request with a body data are not support on the '
          'web platform. Use POST/PUT instead.',
          StackTrace.current,
        );
      }
      final completer = Completer<Uint8List>();
      final sink = ByteConversionSink.withCallback(
        (bytes) => completer.complete(Uint8List.fromList(bytes)),
      );
      requestStream.listen(
        sink.add,
        onError: (Object e, StackTrace s) => completer.completeError(e, s),
        onDone: sink.close,
        cancelOnError: true,
      );
      final bytes = await completer.future;
      xhr.send(bytes);
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
