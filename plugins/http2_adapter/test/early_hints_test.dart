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

  test(
      'completes normally when the server sends a trailer HEADERS frame '
      'after DATA', () async {
    // A trailer section is a HEADERS frame without `:status`, sent after the
    // response body with END_STREAM (RFC 9113 §8.4, §8.8.5). Trailers are
    // currently discarded (proper support tracked in
    // https://github.com/cfug/dio/issues/2602); this test pins that the
    // request still resolves normally instead of hanging or throwing.
    final fixture = await _H2Fixture.serve((stream) {
      stream.sendHeaders(
        [
          Header.ascii(':status', '200'),
          Header.ascii('content-type', 'text/plain'),
        ],
        endStream: false,
      );
      stream.sendData('hello'.codeUnits, endStream: false);
      // Trailing metadata (e.g. gRPC `grpc-status`) — no `:status`.
      stream.sendHeaders(
        [Header.ascii('grpc-status', '0')],
        endStream: true,
      );
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
    expect(response.headers.value('content-type'), 'text/plain');
    // Trailers are dropped for now.
    expect(response.headers.value('grpc-status'), isNull);
  });

  test(
      'fails fast when a 1xx interim response carries END_STREAM '
      'instead of hanging', () async {
    // A 1xx HEADERS frame with END_STREAM terminates the stream without a
    // final response — malformed per RFC 9110 §15.2 and RFC 9113 §8.4. With
    // `receiveTimeout` unset (the default) the request would otherwise wait
    // forever on a pooled connection, so it should error out promptly.
    final fixture = await _H2Fixture.serve((stream) {
      stream.sendHeaders(
        [Header.ascii(':status', '100')],
        endStream: true,
      );
    });
    addTearDown(fixture.close);

    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(fixture.connectionManager);

    await expectLater(
      dio.get<String>(
        'http://127.0.0.1/',
        options: Options(responseType: ResponseType.plain),
      ),
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.connectionError)
            .having(
              (e) => e.message,
              'message',
              contains('interim 1xx response with END_STREAM'),
            ),
      ),
    );
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
