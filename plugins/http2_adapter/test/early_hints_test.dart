import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:http2/transport.dart';
import 'package:test/test.dart';

void main() {
  test('ignores 1xx interim responses and resolves with the final response',
      () async {
    final fixture = await _H2Fixture.serve((stream) {
      stream.sendHeaders(
        [
          Header.ascii(':status', '103'),
          Header.ascii('link', '</s.css>; rel=preload; as=style'),
        ],
        endStream: false,
      );
      stream.sendHeaders(
        [
          Header.ascii(':status', '200'),
          Header.ascii('content-type', 'text/plain'),
        ],
        endStream: false,
      );
      stream.sendData('hello'.codeUnits, endStream: true);
    });
    addTearDown(fixture.close);

    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(fixture.connectionManager);

    final response = await dio.get<String>(
      'http://127.0.0.1/',
      options: Options(responseType: ResponseType.plain),
    );

    expect(response.statusCode, 200);
    expect(response.data, 'hello');
    expect(response.headers.value('link'), isNull);
    expect(response.headers.value('content-type'), 'text/plain');
  });
}

class _H2Fixture {
  _H2Fixture._(
    this._server,
    this._serverSubscription,
    this._connectionManager,
    this._serverConnections,
    this._subscriptions,
  );

  final ServerSocket _server;
  final StreamSubscription<Socket> _serverSubscription;
  final _TestConnectionManager _connectionManager;
  final List<ServerTransportConnection> _serverConnections;
  final List<StreamSubscription<dynamic>> _subscriptions;

  ConnectionManager get connectionManager => _connectionManager;

  static Future<_H2Fixture> serve(
    void Function(ServerTransportStream stream) handler,
  ) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final serverConnections = <ServerTransportConnection>[];
    final subscriptions = <StreamSubscription<dynamic>>[];
    late final StreamSubscription<Socket> serverSubscription;
    serverSubscription = server.listen((socket) {
      final connection = ServerTransportConnection.viaSocket(socket);
      serverConnections.add(connection);
      subscriptions.add(
        connection.incomingStreams.listen(
          (stream) {
            subscriptions.add(
              stream.incomingMessages.listen(
                (message) {
                  if (message is HeadersStreamMessage) {
                    handler(stream);
                  }
                },
                onError: (_, __) {},
              ),
            );
          },
          onError: (_, __) {},
        ),
      );
    });

    final socket = await Socket.connect(server.address, server.port);
    final clientConnection = ClientTransportConnection.viaSocket(socket);
    return _H2Fixture._(
      server,
      serverSubscription,
      _TestConnectionManager(clientConnection),
      serverConnections,
      subscriptions,
    );
  }

  Future<void> close() async {
    await _serverSubscription.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    try {
      await _connectionManager.terminate();
    } catch (_) {}
    for (final connection in _serverConnections) {
      try {
        await connection.terminate();
      } catch (_) {}
    }
    await _server.close();
  }
}

class _TestConnectionManager implements ConnectionManager {
  _TestConnectionManager(this._connection);

  final ClientTransportConnection _connection;

  @override
  int get cachedConnectionsCount => 1;

  @override
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
    List<RedirectRecord> redirects,
  ) async =>
      _connection;

  @override
  void removeConnection(ClientTransportConnection transport) {}

  @override
  void close({bool force = false}) {}

  Future<void> terminate() => _connection.terminate();
}
