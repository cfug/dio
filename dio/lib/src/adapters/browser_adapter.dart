import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_error.dart';
import '../headers.dart';
import '../options.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

class BrowserHttpClientAdapter implements HttpClientAdapter {
  /// These are aborted if the client is closed.
  final _xhrs = <HttpRequest>{};

  /// Whether to send credentials such as cookies or authorization headers for
  /// cross-site requests.
  ///
  /// Defaults to `false`.
  ///
  /// You can also override this value in Options.extra['withCredentials'] for each request
  bool withCredentials = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    var xhr = HttpRequest();
    _xhrs.add(xhr);
    xhr
      ..open(options.method, '${options.uri}')
      ..responseType = 'arraybuffer';

    var _withCredentials = options.extra['withCredentials'];

    if (_withCredentials != null) {
      xhr.withCredentials = _withCredentials == true;
    } else {
      xhr.withCredentials = withCredentials;
    }

    options.headers.remove(Headers.contentLengthHeader);
    options.headers.forEach((key, v) => xhr.setRequestHeader(key, '$v'));

    final connectTimeout = options.connectTimeout;
    final receiveTimeout = options.receiveTimeout;
    if (connectTimeout != null &&
        receiveTimeout != null &&
        receiveTimeout > Duration.zero) {
      xhr.timeout = (connectTimeout + receiveTimeout).inMilliseconds;
    }

    var completer = Completer<ResponseBody>();

    xhr.onLoad.first.then((_) {
      Uint8List body = (xhr.response as ByteBuffer).asUint8List();
      completer.complete(
        ResponseBody.fromBytes(
          body,
          xhr.status!,
          headers: xhr.responseHeaders.map((k, v) => MapEntry(k, v.split(','))),
          statusMessage: xhr.statusText,
          isRedirect: xhr.status == 302 || xhr.status == 301,
        ),
      );
    });

    bool haveSent = false;

    final connectionTimeout = options.connectTimeout;
    if (connectionTimeout != null) {
      Future.delayed(connectionTimeout).then(
        (value) {
          if (!haveSent) {
            completer.completeError(
              DioError(
                requestOptions: options,
                error: 'Connecting timed out [${options.connectTimeout}ms]',
                type: DioErrorType.connectTimeout,
              ),
              StackTrace.current,
            );
            xhr.abort();
          }
        },
      );
    }

    DateTime? sendStart;
    xhr.upload.onProgress.listen((event) {
      haveSent = true;
      final sendTimeout = options.sendTimeout;
      if (sendTimeout != null) {
        sendStart ??= DateTime.now();
        var t = DateTime.now();
        if (t.difference(sendStart!) > sendTimeout) {
          completer.completeError(
            DioError(
              requestOptions: options,
              error: 'Sending timed out [${options.sendTimeout}ms]',
              type: DioErrorType.sendTimeout,
            ),
            StackTrace.current,
          );
          xhr.abort();
        }
      }
      if (options.onSendProgress != null &&
          event.loaded != null &&
          event.total != null) {
        options.onSendProgress!(event.loaded!, event.total!);
      }
    });

    DateTime? receiveStart;
    xhr.onProgress.listen((event) {
      final reveiveTimeout = options.receiveTimeout;
      if (reveiveTimeout != null) {
        receiveStart ??= DateTime.now();
        final duration = DateTime.now().difference(receiveStart!).abs();
        if (duration > reveiveTimeout) {
          completer.completeError(
            DioError(
              requestOptions: options,
              error: 'Receiving timed out [${options.receiveTimeout}ms]',
              type: DioErrorType.receiveTimeout,
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
      // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
      // specific information about the error itself.
      completer.completeError(
        DioError(
          type: DioErrorType.response,
          error: 'XMLHttpRequest error.',
          requestOptions: options,
        ),
        StackTrace.current,
      );
    });

    cancelFuture?.then((_) {
      if (xhr.readyState < 4 && xhr.readyState > 0) {
        try {
          xhr.abort();
        } catch (e) {
          // ignore
        }
      }
    });

    if (requestStream != null) {
      var _completer = Completer<Uint8List>();
      var sink = ByteConversionSink.withCallback(
          (bytes) => _completer.complete(Uint8List.fromList(bytes)));
      requestStream.listen(
        sink.add,
        onError: _completer.completeError,
        onDone: sink.close,
        cancelOnError: true,
      );
      var bytes = await _completer.future;
      xhr.send(bytes);
    } else {
      xhr.send();
    }

    return completer.future.whenComplete(() {
      _xhrs.remove(xhr);
    });
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close({bool force = false}) {
    if (force) {
      for (var xhr in _xhrs) {
        xhr.abort();
      }
    }
    _xhrs.clear();
  }
}
