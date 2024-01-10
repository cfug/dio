// ignore_for_file: void_checks
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:http2/http2.dart';

part 'client_setting.dart';

part 'connection_manager.dart';

part 'connection_manager_imp.dart';

/// The signature of [Http2Adapter.onNotSupported].
typedef H2NotSupportedCallback = Future<ResponseBody> Function(
  DioH2NotSupportedException exception,
);

/// The exception when a connected socket for the [uri]
/// does not support HTTP/2.
class DioH2NotSupportedException extends SocketException {
  const DioH2NotSupportedException(
    this.uri,
    this.selectedProtocol,
  ) : super('h2 protocol not supported');

  final Uri uri;
  final String? selectedProtocol;
}

/// A Dio HttpAdapter which implements Http/2.0.
class Http2Adapter implements HttpClientAdapter {
  Http2Adapter(
    this.connectionManager, {
    HttpClientAdapter? fallbackAdapter,
    this.onNotSupported,
  }) : fallbackAdapter = fallbackAdapter ?? IOHttpClientAdapter();

  /// {@macro dio_http2_adapter.ConnectionManager}
  ConnectionManager connectionManager;

  /// {@macro dio.HttpClientAdapter}
  HttpClientAdapter fallbackAdapter;

  /// Handles [DioH2NotSupportedException] and returns a [ResponseBody].
  H2NotSupportedCallback? onNotSupported;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final redirects = <RedirectRecord>[];
    try {
      return await _fetch(options, requestStream, cancelFuture, redirects);
    } on DioH2NotSupportedException catch (e) {
      // Fallback to use the callback
      // or to another adapter (typically IOHttpClientAdapter)
      // since the request can have a better handle by it.
      return await onNotSupported?.call(e) ??
          await fallbackAdapter.fetch(options, requestStream, cancelFuture);
    }
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
    List<RedirectRecord> redirects,
  ) async {
    final transport = await connectionManager.getConnection(options);
    final uri = options.uri;
    String path = uri.path;
    const excludeMethods = ['PUT', 'POST', 'PATCH'];

    if (path.isEmpty || !path.startsWith('/')) {
      path = '/$path';
    }
    if (uri.query.trim().isNotEmpty) {
      path += '?${uri.query}';
    }
    final headers = [
      Header.ascii(':method', options.method),
      Header.ascii(':path', path),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':authority', uri.host),
    ];

    // Add custom headers
    headers.addAll(
      options.headers.entries.map(
        (entry) {
          final String v;
          if (entry.value is Iterable) {
            v = entry.value.join(', ');
          } else {
            v = '${entry.value}';
          }
          return Header.ascii(entry.key.toLowerCase(), v);
        },
      ).toList(),
    );

    // Creates a new outgoing stream.
    final stream = transport.makeRequest(headers);

    cancelFuture?.whenComplete(() {
      Future(() {
        stream.terminate();
      });
    });

    List<Uint8List>? list;
    final hasRequestData = requestStream != null;
    if (!excludeMethods.contains(options.method) && hasRequestData) {
      list = await requestStream.toList();
      requestStream = Stream.fromIterable(list);
    }

    if (hasRequestData) {
      Future<void> requestStreamFuture = requestStream!.listen((data) {
        stream.outgoingMessages.add(DataStreamMessage(data));
      }).asFuture();
      final sendTimeout = options.sendTimeout ?? Duration.zero;
      if (sendTimeout > Duration.zero) {
        requestStreamFuture = requestStreamFuture.timeout(
          sendTimeout,
          onTimeout: () {
            stream.terminate();
            throw DioException.sendTimeout(
              timeout: sendTimeout,
              requestOptions: options,
            );
          },
        );
      }
      await requestStreamFuture;
    }
    await stream.outgoingMessages.close();

    final responseSink = StreamController<Uint8List>();
    final responseHeaders = Headers();
    final responseCompleter = Completer<void>();
    late StreamSubscription responseSubscription;
    bool needRedirect = false;
    bool needResponse = false;

    final receiveTimeout = options.receiveTimeout ?? Duration.zero;
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
        responseSink.addError(
          DioException.receiveTimeout(
            timeout: receiveTimeout,
            requestOptions: options,
          ),
        );
        responseSink.close();
        responseSubscription.cancel();
        stream.terminate();
        stopWatchReceiveTimeout();
      });
    }

    late int statusCode;
    responseSubscription = stream.incomingMessages.listen(
      (StreamMessage message) async {
        if (message is HeadersStreamMessage) {
          for (final header in message.headers) {
            final name = utf8.decode(header.name);
            final value = utf8.decode(header.value);
            responseHeaders.add(name, value);
          }

          final status = responseHeaders.value(':status');
          if (status != null) {
            statusCode = int.parse(status);
            responseHeaders.removeAll(':status');
            needRedirect = _needRedirect(options, statusCode);
            needResponse =
                !needRedirect && options.validateStatus(statusCode) ||
                    options.receiveDataWhenStatusError;
            responseCompleter.complete();
          }
        } else if (message is DataStreamMessage) {
          if (needResponse) {
            watchReceiveTimeout();
            responseSink.add(
              message.bytes is Uint8List
                  ? message.bytes as Uint8List
                  : Uint8List.fromList(message.bytes),
            );
          } else {
            stopWatchReceiveTimeout();
            responseSubscription.cancel().whenComplete(() {
              stream.terminate();
              responseSink.close();
            });
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // If connection is being forcefully terminated, remove the connection.
        if (error is TransportConnectionException) {
          connectionManager.removeConnection(transport);
        }
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(error, stackTrace);
        } else {
          responseSink.addError(error, stackTrace);
        }
        stopWatchReceiveTimeout();
        responseSubscription.cancel();
        responseSink.close();
      },
      onDone: () {
        stopWatchReceiveTimeout();
        responseSubscription.cancel();
        responseSink.close();
      },
      cancelOnError: true,
    );

    Future<void> responseFuture = responseCompleter.future;
    if (receiveTimeout > Duration.zero) {
      responseFuture = responseFuture.timeout(
        receiveTimeout,
        onTimeout: () {
          responseSubscription
              .cancel()
              .whenComplete(() => responseSink.close());
          throw DioException.receiveTimeout(
            timeout: receiveTimeout,
            requestOptions: options,
          );
        },
      );
    }
    await responseFuture;

    // Handle redirection.
    if (needRedirect) {
      final url = responseHeaders.value('location');
      redirects.add(
        RedirectRecord(statusCode, options.method, Uri.parse(url ?? '')),
      );
      return _fetch(
        options.copyWith(path: url, maxRedirects: --options.maxRedirects),
        list != null ? Stream.fromIterable(list) : null,
        cancelFuture,
        redirects,
      );
    }
    return ResponseBody(
      responseSink.stream,
      statusCode,
      headers: responseHeaders.map,
      redirects: redirects,
      isRedirect: redirects.isNotEmpty,
    );
  }

  bool _needRedirect(RequestOptions options, int status) {
    const statusCodes = [301, 302, 303, 307, 308];
    return options.followRedirects &&
        options.maxRedirects > 0 &&
        statusCodes.contains(status);
  }

  @override
  void close({bool force = false}) {
    connectionManager.close(force: force);
  }
}
