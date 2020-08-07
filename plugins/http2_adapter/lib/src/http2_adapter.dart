import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http2/http2.dart';
import 'package:dio/dio.dart';

part 'connection_manager.dart';

part 'client_setting.dart';

part 'connection_manager_imp.dart';


/// A Dio HttpAdapter which implements Http/2.0.
class Http2Adapter extends HttpClientAdapter {
  final ConnectionManager _connectionMgr;

  Http2Adapter(ConnectionManager connectionManager)
      : this._connectionMgr = connectionManager ?? ConnectionManager();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
  ) async {
    List<RedirectRecord> redirects = [];
    return _fetch(options, requestStream, cancelFuture, redirects);
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<List<int>> requestStream,
    Future cancelFuture,
    List<RedirectRecord> redirects,
  ) async {
    final transport = await _connectionMgr.getConnection(options);
    final uri = options.uri;
    var path = uri.path;
    if (uri.query.trim().isNotEmpty) path += ("?" + uri.query);
    if (!path.startsWith("/")) path = "/" + path;
    var headers = [
      Header.ascii(':method', options.method),
      Header.ascii(':path', path),
      Header.ascii(':scheme', uri.scheme),
      Header.ascii(':authority', uri.host),
    ];

    // Add custom headers
    headers.addAll(
      options.headers.keys
          .map((key) => Header.ascii(key, options.headers[key]??''))
          .toList(),
    );
    // Creates a new outgoing stream.
    final stream = transport.makeRequest(headers);
    cancelFuture?.whenComplete(() {
      Future.delayed(Duration(seconds: 0)).then((e) {
        stream.terminate();
      });
    });

    await (requestStream
      ?.listen((data) {
          stream.outgoingMessages.add(DataStreamMessage(data));
      })
      ?.asFuture());
    await stream.outgoingMessages.close();

    final sc = StreamController<Uint8List>();
    final Headers responseHeaders = Headers();
    Completer completer = Completer();
    var statusCode;
    var needRedirect = false;
    StreamSubscription subscription;
    var needResponse = false;
    subscription = stream.incomingMessages.listen(
      (message) async {
        if (message is HeadersStreamMessage) {
          for (var header in message.headers) {
            var name = utf8.decode(header.name);
            var value = utf8.decode(header.value);
            responseHeaders.add(name, value);
          }

          var status = responseHeaders.value(":status");
          statusCode = int.parse(status);
          responseHeaders.removeAll(":status");
          needRedirect = options.followRedirects &&
              options.maxRedirects > 0 &&
              [301, 302, 303, 307, 308].contains(statusCode);
          needResponse = !needRedirect && options.validateStatus(statusCode) ||
              options.receiveDataWhenStatusError;
          completer.complete();
        } else if (message is DataStreamMessage) {
          if (needResponse) {
            sc.add(Uint8List.fromList(message.bytes));
          } else {
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
      var url = responseHeaders.value("location");
      redirects.add(RedirectRecord(statusCode, options.method, Uri.parse(url)));
      return _fetch(
        options.merge(path: url, maxRedirects: --options.maxRedirects),
        requestStream,
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

  @override
  void close({bool force = false}) {
    _connectionMgr.close(force: force);
  }
}
