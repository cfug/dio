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
    var transport = await _connectionMgr.getConnection(options);
    var uri = options.uri;
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
          .map((key) => Header.ascii(key, options.headers[key]))
          .toList(),
    );
    // Creates a new outgoing stream.
    var stream = transport.makeRequest(
      headers,
      endStream: false,
    );
    var _ = cancelFuture?.whenComplete(() {
      Future.delayed(Duration(seconds: 0)).then((e) {
        stream.terminate();
      });
    });
    // Write outgoing stream
    await requestStream
        ?.listen((data) => stream.outgoingMessages.add(DataStreamMessage(data)))
        ?.asFuture();
    await stream.outgoingMessages.close();
    var sc = StreamController<Uint8List>();
    Headers responseHeaders = Headers();
    Completer completer = Completer();
    stream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage) {
          for (var header in message.headers) {
            var name = utf8.decode(header.name);
            var value = utf8.decode(header.value);
            responseHeaders.add(name, value);
          }
          completer.complete();
        } else if (message is DataStreamMessage) {
          sc.add(Uint8List.fromList(message.bytes));
        }
      },
      onDone: () => sc.close(),
      onError: (e) {
        // If connection is being forcefully terminated, remove the connection
        if (e is TransportConnectionException)
          _connectionMgr.removeConnection(transport);

        if (!completer.isCompleted) {
          completer.completeError(e, StackTrace.current);
        } else {
          sc.addError(e);
        }
      },
      cancelOnError: true,
    );
    await completer.future;
    var status = responseHeaders.value(":status");
    responseHeaders.removeAll(":status");
    return ResponseBody(
      sc.stream,
      int.parse(status),
      headers: responseHeaders.map,
    );
  }

  @override
  void close({bool force = false}) {
    _connectionMgr.close(force: force);
  }
}
