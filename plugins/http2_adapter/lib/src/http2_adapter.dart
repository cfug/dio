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
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
  DioH2NotSupportedException exception,
);

/// A Dio HttpAdapter which implements Http/2.0.
class Http2Adapter implements HttpClientAdapter {
  Http2Adapter(
    ConnectionManager? connectionManager, {
    HttpClientAdapter? fallbackAdapter,
    this.onNotSupported,
  })  : connectionManager = connectionManager ?? ConnectionManager(),
        fallbackAdapter = fallbackAdapter ?? IOHttpClientAdapter();

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
  ) {
    // Recursive fetching.
    final redirects = <RedirectRecord>[];
    return _fetch(options, requestStream, cancelFuture, redirects);
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
    List<RedirectRecord> redirects,
  ) async {
    late final ClientTransportConnection transport;
    try {
      transport = await connectionManager.getConnection(options, redirects);
    } on DioH2NotSupportedException catch (e) {
      // Fallback to use the callback
      // or to another adapter (typically IOHttpClientAdapter)
      // since the request can have a better handle by it.
      if (onNotSupported != null) {
        return onNotSupported!(options, requestStream, cancelFuture, e);
      }
      return fallbackAdapter.fetch(options, requestStream, cancelFuture);
    } on SocketException catch (e) {
      if (e.message.contains('timed out')) {
        final Duration effectiveTimeout;
        if (options.connectTimeout != null &&
            options.connectTimeout! > Duration.zero) {
          effectiveTimeout = options.connectTimeout!;
        } else {
          effectiveTimeout = Duration.zero;
        }
        throw DioException.connectionTimeout(
          requestOptions: options,
          timeout: effectiveTimeout,
          error: e,
        );
      }
      throw DioException.connectionError(
        requestOptions: options,
        reason: e.message,
        error: e,
      );
    }

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
    final streamWR = WeakReference<ClientTransportStream>(stream);

    final hasRequestData = requestStream != null;
    if (hasRequestData && cancelFuture != null) {
      cancelFuture.whenComplete(() {
        streamWR.target?.outgoingMessages.close();
      });
    }

    List<Uint8List>? list;
    if (!excludeMethods.contains(options.method) && hasRequestData) {
      list = await requestStream.toList();
      requestStream = Stream.fromIterable(list);
    }

    if (hasRequestData) {
      Future<dynamic> requestStreamFuture = requestStream!.listen((data) {
        //TODO(EVERYONE): Investigate why this statement can cause "StateError: Bad state: Cannot add event after closing"
        stream.outgoingMessages.add(DataStreamMessage(data));
      }).asFuture();
      final sendTimeout = options.sendTimeout ?? Duration.zero;
      if (sendTimeout > Duration.zero) {
        requestStreamFuture = requestStreamFuture.timeout(
          sendTimeout,
          onTimeout: () {
            stream.outgoingMessages.close().catchError((_) {});
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
    final responseCompleter = Completer();
    late StreamSubscription responseSubscription;
    bool needRedirect = false;
    bool needResponse = false;

    final receiveTimeout = options.receiveTimeout ?? Duration.zero;

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
            responseSink.add(
              message.bytes is Uint8List
                  ? message.bytes as Uint8List
                  : Uint8List.fromList(message.bytes),
            );
          } else {
            responseSubscription.cancel().whenComplete(() {
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
        responseSubscription.cancel();
        responseSink.close();
      },
      onDone: () {
        responseSubscription.cancel();
        responseSink.close();
      },
      cancelOnError: true,
    );

    Future<dynamic> responseFuture = responseCompleter.future;
    if (receiveTimeout > Duration.zero) {
      responseFuture = responseFuture.timeout(
        receiveTimeout,
        onTimeout: () {
          responseSubscription
              .cancel()
              .catchError((_) {})
              .whenComplete(() => responseSink.close().catchError((_) {}));
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
      if (responseHeaders['location'] == null) {
        // Redirect without location is illegal.
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Received redirect without location header.',
        );
      }
      final url = responseHeaders.value('location');
      // An empty `location` header is considered a self redirect.
      final uri = Uri.parse(url ?? '');
      redirects.add(RedirectRecord(statusCode, options.method, uri));
      final String path = resolveRedirectUri(options.uri, uri).toString();
      return _fetch(
        options.copyWith(
          path: path,
          maxRedirects: --options.maxRedirects,
        ),
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
      onClose: () {
        responseSubscription.cancel();
        responseSink.close();
        streamWR.target?.outgoingMessages.close();
      },
    );
  }

  bool _needRedirect(RequestOptions options, int status) {
    const statusCodes = [301, 302, 303, 307, 308];
    return options.followRedirects &&
        options.maxRedirects > 0 &&
        statusCodes.contains(status);
  }

  static Uri resolveRedirectUri(Uri currentUri, Uri redirectUri) {
    if (redirectUri.hasScheme) {
      // This is a full URL which has to be redirected to as is.
      return redirectUri;
    }

    // This is relative with or without leading slash and is resolved against
    // the URL of the original request.
    return currentUri.resolveUri(redirectUri);
  }

  @override
  void close({bool force = false}) {
    connectionManager.close(force: force);
  }
}

/// The exception when a connected socket for the [uri] does not support HTTP/2.
class DioH2NotSupportedException extends SocketException {
  const DioH2NotSupportedException(
    this.uri,
    this.selectedProtocol,
  ) : super('h2 protocol not supported');

  final Uri uri;
  final String? selectedProtocol;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('DioH2NotSupportedException');
    if (message.isNotEmpty) {
      sb.write(': $message');
      if (osError != null) {
        sb.write(' ($osError)');
      }
    } else if (osError != null) {
      sb.write(': $osError');
    }
    if (address != null) {
      sb.write(', address = ${address!.host}');
    }
    if (port != null) {
      sb.write(', port = $port');
    }
    return sb.toString();
  }
}
