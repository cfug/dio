import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http2/http2.dart';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

part 'connection_manager.dart';

part 'client_setting.dart';

part 'connection_manager_imp.dart';

/// A Dio HttpAdapter which implements Http/2.0.
class Http2Adapter extends HttpClientAdapter {
  final ConnectionManager _connectionMgr;
  late HttpClientAdapter _fallbackAdapter;

  Http2Adapter(ConnectionManager? connectionManager, {HttpClientAdapter? fallbackAdapter})
      : _connectionMgr = connectionManager ?? ConnectionManager(),
        _fallbackAdapter = fallbackAdapter ?? DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    if (options.uri.isScheme('http')) {
      return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
    } else {
      try {
        var redirects = <RedirectRecord>[];
        return await _fetch(
          options,
          requestStream,
          cancelFuture,
          redirects,
        );
      } on FallbackException catch (e) {
        return _fallbackAdapter.fetch(options, requestStream, cancelFuture);
      }
    }
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
    List<RedirectRecord> redirects,
  ) async {
    final transport = await _connectionMgr.getConnection(options);
    final uri = options.uri;
    var path = uri.path;
    const excludeMethods = ['PUT', 'POST', 'PATCH'];

    if (path.isEmpty || !path.startsWith('/')) path = '/' + path;
    if (uri.query.trim().isNotEmpty) path += ('?' + uri.query);
    var headers = [
      Header.ascii(':method', options.method),
      Header.ascii(':path', path),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':authority', uri.host),
      Header.ascii('user-agent', 'Dart/h2'),
    ];

    // Add custom headers
    headers.addAll(
      options.headers.keys
          .map((key) => Header.ascii(key.toLowerCase(), options.headers[key] ?? ''))
          .toList(),
    );

    // Creates a new outgoing stream.
    final stream = transport.makeRequest(headers);

    // ignore: unawaited_futures
    cancelFuture?.whenComplete(() {
      Future(() {
        stream.terminate();
      });
    });

    var list;
    var hasRequestData = requestStream != null;
    if (!excludeMethods.contains(options.method) && hasRequestData) {
      list = await requestStream!.toList();
      requestStream = Stream.fromIterable(list);
    }

    if (hasRequestData) {
      await requestStream!.listen((data) {
        stream.outgoingMessages.add(DataStreamMessage(data));
      }).asFuture();
    }

    await stream.outgoingMessages.close();

    final sc = StreamController<Uint8List>();
    final responseHeaders = Headers();
    var completer = Completer();
    var statusCode;
    var needRedirect = false;
    late StreamSubscription subscription;
    var needResponse = false;
    subscription = stream.incomingMessages.listen(
      (message) async {
        if (message is HeadersStreamMessage) {
          for (var header in message.headers) {
            var name = utf8.decode(header.name);
            var value = utf8.decode(header.value);
            responseHeaders.add(name, value);
          }

          var status = responseHeaders.value(':status');
          if (status != null) {
            statusCode = int.parse(status);
            responseHeaders.removeAll(':status');

            needRedirect = _needRedirect(options, statusCode);

            needResponse =
                !needRedirect && options.validateStatus(statusCode) ||
                    options.receiveDataWhenStatusError;

            completer.complete();
          }
        } else if (message is DataStreamMessage) {
          if (needResponse) {
            sc.add(Uint8List.fromList(message.bytes));
          } else {
            // ignore: unawaited_futures
            subscription.cancel().whenComplete(() => sc.close());
          }
        }
      },
      onDone: () => sc.close(),
      onError: (e) {
        // If connection is being forcefully terminated, remove the connection
        if (e is TransportConnectionException) {
          _connectionMgr.removeConnection(transport);
        }
        if (!completer.isCompleted) {
          completer.completeError(e, StackTrace.current);
        } else {
          sc.addError(e);
        }
      },
      cancelOnError: true,
    );

    await completer.future;

    // Handle redirection
    if (needRedirect) {
      var url = responseHeaders.value('location');
      redirects.add(
          RedirectRecord(statusCode, options.method, Uri.parse(url ?? '')));
      return _fetch(
        options.copyWith(path: url, maxRedirects: --options.maxRedirects),
        list == null ? null : Stream.fromIterable(list),
        cancelFuture,
        redirects,
      );
    }
    return ResponseBody(
      sc.stream,
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
    _connectionMgr.close(force: force);
  }
}
