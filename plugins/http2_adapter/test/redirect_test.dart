import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:http2/http2.dart';
import 'package:test/test.dart';

const _sensitiveHeaders = <String, String>{
  'AuThOrIzAtIoN': 'Bearer token',
  'WWW-Authenticate': 'Basic realm="private"',
  'CoOkIe': 'session=secret',
  'Cookie2': r'$Version="1"',
  'Proxy-Authorization': 'Basic proxy-token',
  'Proxy-Authenticate': 'Basic realm="proxy"',
};

const _ordinaryHeaderName = 'x-request-id';
const _ordinaryHeaderValue = 'request-123';
const _testTimeout = Duration(seconds: 5);

void main() {
  group('Http2Adapter.resolveRedirectUri', () {
    test('empty location', () async {
      final current = Uri.parse('https://example.com');
      final result = Http2Adapter.resolveRedirectUri(
        current,
        Uri.parse(''),
      );
      expect(result.toString(), current.toString());
    });

    test('relative location 1', () async {
      final result = Http2Adapter.resolveRedirectUri(
        Uri.parse('https://example.com/foo'),
        Uri.parse('/bar'),
      );

      expect(result.toString(), 'https://example.com/bar');
    });

    test('relative location 2', () async {
      final result = Http2Adapter.resolveRedirectUri(
        Uri.parse('https://example.com/foo'),
        Uri.parse('../bar'),
      );
      expect(result.toString(), 'https://example.com/bar');
    });

    test('different location', () async {
      final current = Uri.parse('https://example.com/foo');
      final target = 'https://somewhere.com/bar';
      final result = Http2Adapter.resolveRedirectUri(
        current,
        Uri.parse(target),
      );
      expect(result.toString(), target);
    });
  });

  group('redirect headers', () {
    final crossOriginCases =
        <String, ({String initial, String location, String expected})>{
      'different host': (
        initial: 'http://origin.test/start',
        location: 'http://other.test/capture',
        expected: 'http://other.test/capture',
      ),
      'different scheme': (
        initial: 'http://origin.test:8080/start',
        location: 'https://origin.test:8080/capture',
        expected: 'https://origin.test:8080/capture',
      ),
      'different port': (
        initial: 'http://origin.test:8080/start',
        location: 'http://origin.test:8081/capture',
        expected: 'http://origin.test:8081/capture',
      ),
      'subdomain': (
        initial: 'http://origin.test/start',
        location: 'http://sub.origin.test/capture',
        expected: 'http://sub.origin.test/capture',
      ),
      'network-path location': (
        initial: 'http://origin.test/start',
        location: '//other.test/capture',
        expected: 'http://other.test/capture',
      ),
    };

    for (final MapEntry(key: description, value: testCase)
        in crossOriginCases.entries) {
      test('$description strips sensitive headers', () async {
        final capturedHeaders = Completer<Map<String, String>>();
        final fixture = await _H2Fixture.start((headers) {
          if (headers[':path'] == '/start') {
            return _TestResponse.redirect(testCase.location);
          }
          capturedHeaders.complete(headers);
          return const _TestResponse.ok();
        });
        final options = _requestOptions(testCase.initial);
        final adapter = Http2Adapter(fixture.connectionManager);

        try {
          final response = await _fetch(adapter, options);
          await response.stream.drain<void>().timeout(_testTimeout);
          final redirectedHeaders =
              await capturedHeaders.future.timeout(_testTimeout);
          _expectRequestTarget(redirectedHeaders, testCase.expected);
          _expectSensitiveHeadersAbsent(
            redirectedHeaders,
          );
          for (final name in _sensitiveHeaders.keys) {
            expect(options.headers, contains(name));
          }
          expect(options.maxRedirects, 5);
        } finally {
          await fixture.close();
        }
      });
    }

    final sameOriginCases =
        <String, ({String initial, String location, String expected})>{
      'relative location': (
        initial: 'http://origin.test/start',
        location: '/capture',
        expected: 'http://origin.test/capture',
      ),
      'absolute location': (
        initial: 'http://origin.test/start',
        location: 'http://origin.test/capture',
        expected: 'http://origin.test/capture',
      ),
      'explicit default port': (
        initial: 'http://origin.test/start',
        location: 'http://origin.test:80/capture',
        expected: 'http://origin.test/capture',
      ),
    };

    for (final MapEntry(key: description, value: testCase)
        in sameOriginCases.entries) {
      test('$description preserves sensitive headers', () async {
        final capturedHeaders = Completer<Map<String, String>>();
        final fixture = await _H2Fixture.start((headers) {
          if (headers[':path'] == '/start') {
            return _TestResponse.redirect(testCase.location);
          }
          capturedHeaders.complete(headers);
          return const _TestResponse.ok();
        });
        final adapter = Http2Adapter(fixture.connectionManager);

        try {
          final response = await _fetch(
            adapter,
            _requestOptions(testCase.initial),
          );
          await response.stream.drain<void>().timeout(_testTimeout);
          final redirectedHeaders =
              await capturedHeaders.future.timeout(_testTimeout);
          _expectRequestTarget(redirectedHeaders, testCase.expected);
          _expectSensitiveHeadersPresent(
            redirectedHeaders,
          );
        } finally {
          await fixture.close();
        }
      });
    }

    test('does not restore sensitive headers later in a redirect chain',
        () async {
      final capturedHeaders = Completer<Map<String, String>>();
      final requests = <Map<String, String>>[];
      final fixture = await _H2Fixture.start((headers) {
        requests.add(headers);
        switch (headers[':path']) {
          case '/start':
            return const _TestResponse.redirect('http://other.test/bounce');
          case '/bounce':
            return const _TestResponse.redirect('http://origin.test/capture');
          default:
            capturedHeaders.complete(headers);
            return const _TestResponse.ok();
        }
      });
      final adapter = Http2Adapter(fixture.connectionManager);

      try {
        final response = await _fetch(
          adapter,
          _requestOptions('http://origin.test/start'),
        );
        await response.stream.drain<void>().timeout(_testTimeout);
        expect(requests, hasLength(3));
        _expectRequestTarget(requests[0], 'http://origin.test/start');
        _expectRequestTarget(requests[1], 'http://other.test/bounce');
        _expectRequestTarget(requests[2], 'http://origin.test/capture');
        _expectSensitiveHeadersAbsent(
          await capturedHeaders.future.timeout(_testTimeout),
        );
      } finally {
        await fixture.close();
      }
    });

    test('passes sanitized options to onNotSupported', () async {
      final fixture = await _H2Fixture.start(
        (_) => const _TestResponse.redirect('http://other.test/capture'),
        failConnectionAt: 2,
      );
      final fallbackOptions = Completer<RequestOptions>();
      final adapter = Http2Adapter(
        fixture.connectionManager,
        onNotSupported: (options, requestStream, cancelFuture, exception) {
          fallbackOptions.complete(options);
          return Future.value(ResponseBody.fromString('ok', 200));
        },
      );

      try {
        final response = await _fetch(
          adapter,
          _requestOptions('http://origin.test/start'),
        );
        await response.stream.drain<void>().timeout(_testTimeout);
        expect(
          (await fallbackOptions.future.timeout(_testTimeout)).uri,
          Uri.parse('http://other.test/capture'),
        );
        expect(
          (await fallbackOptions.future.timeout(_testTimeout)).maxRedirects,
          4,
        );
        _expectSensitiveHeadersAbsent(
          (await fallbackOptions.future.timeout(_testTimeout)).headers.map(
                (key, value) => MapEntry(key.toLowerCase(), '$value'),
              ),
        );
      } finally {
        await fixture.close();
      }
    });
  });
}

RequestOptions _requestOptions(String path) {
  return RequestOptions(
    path: path,
    headers: <String, dynamic>{
      ..._sensitiveHeaders,
      _ordinaryHeaderName: _ordinaryHeaderValue,
    },
  );
}

Future<ResponseBody> _fetch(
  Http2Adapter adapter,
  RequestOptions options,
) {
  return adapter.fetch(options, null, null).timeout(_testTimeout);
}

void _expectRequestTarget(Map<String, String> headers, String expected) {
  final uri = Uri.parse(expected);
  var path = uri.path.isEmpty ? '/' : uri.path;
  if (uri.hasQuery) {
    path += '?${uri.query}';
  }
  expect(headers[':scheme'], uri.scheme);
  expect(headers[':authority'], uri.authority);
  expect(headers[':path'], path);
}

void _expectSensitiveHeadersAbsent(Map<String, String> headers) {
  for (final name in _sensitiveHeaders.keys) {
    expect(headers, isNot(contains(name.toLowerCase())));
  }
  expect(headers[_ordinaryHeaderName], _ordinaryHeaderValue);
}

void _expectSensitiveHeadersPresent(Map<String, String> headers) {
  for (final MapEntry(key: name, value: value) in _sensitiveHeaders.entries) {
    expect(headers[name.toLowerCase()], value);
  }
  expect(headers[_ordinaryHeaderName], _ordinaryHeaderValue);
}

typedef _RequestHandler = _TestResponse Function(Map<String, String> headers);

class _TestResponse {
  const _TestResponse.ok()
      : statusCode = 200,
        location = null;

  const _TestResponse.redirect(this.location) : statusCode = 302;

  final int statusCode;
  final String? location;
}

class _H2Fixture {
  _H2Fixture._(
    this._server,
    this._serverSubscription,
    this._connectionManager,
    this._serverConnections,
    this._subscriptions,
    this._asyncErrors,
  );

  static Future<_H2Fixture> start(
    _RequestHandler handler, {
    int? failConnectionAt,
  }) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final serverConnections = <ServerTransportConnection>[];
    final subscriptions = <StreamSubscription<dynamic>>[];
    final asyncErrors = <({Object error, StackTrace stackTrace})>[];
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
                  if (message is! HeadersStreamMessage) {
                    return;
                  }
                  final headers = <String, String>{
                    for (final header in message.headers)
                      utf8.decode(header.name): utf8.decode(header.value),
                  };
                  try {
                    final response = handler(headers);
                    stream.sendHeaders(
                      [
                        Header.ascii(':status', '${response.statusCode}'),
                        if (response.location != null)
                          Header.ascii('location', response.location!),
                      ],
                      endStream: true,
                    );
                  } catch (error, stackTrace) {
                    asyncErrors.add((error: error, stackTrace: stackTrace));
                  }
                },
                onError: (Object error, StackTrace stackTrace) {
                  asyncErrors.add((error: error, stackTrace: stackTrace));
                },
              ),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            asyncErrors.add((error: error, stackTrace: stackTrace));
          },
        ),
      );
    });

    final socket = await Socket.connect(server.address, server.port);
    final clientConnection = ClientTransportConnection.viaSocket(socket);
    final connectionManager = _TestConnectionManager(
      clientConnection,
      failConnectionAt: failConnectionAt,
    );
    return _H2Fixture._(
      server,
      serverSubscription,
      connectionManager,
      serverConnections,
      subscriptions,
      asyncErrors,
    );
  }

  final ServerSocket _server;
  final StreamSubscription<Socket> _serverSubscription;
  final _TestConnectionManager _connectionManager;
  final List<ServerTransportConnection> _serverConnections;
  final List<StreamSubscription<dynamic>> _subscriptions;
  final List<({Object error, StackTrace stackTrace})> _asyncErrors;

  ConnectionManager get connectionManager => _connectionManager;

  Future<void> close() async {
    await _serverSubscription.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    try {
      await _connectionManager.terminate();
    } catch (error, stackTrace) {
      _asyncErrors.add((error: error, stackTrace: stackTrace));
    }
    for (final connection in _serverConnections) {
      try {
        await connection.terminate();
      } catch (error, stackTrace) {
        _asyncErrors.add((error: error, stackTrace: stackTrace));
      }
    }
    await _server.close();
    if (_asyncErrors.isNotEmpty) {
      final (:error, :stackTrace) = _asyncErrors.first;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class _TestConnectionManager implements ConnectionManager {
  _TestConnectionManager(
    this._connection, {
    this.failConnectionAt,
  });

  final ClientTransportConnection _connection;
  final int? failConnectionAt;
  int _connectionCount = 0;

  @override
  int get cachedConnectionsCount => 1;

  @override
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
    List<RedirectRecord> redirects,
  ) async {
    _connectionCount++;
    if (_connectionCount == failConnectionAt) {
      throw DioH2NotSupportedException(options.uri, null);
    }
    return _connection;
  }

  @override
  void removeConnection(ClientTransportConnection transport) {}

  @override
  void close({bool force = false}) {}

  Future<void> terminate() => _connection.terminate();
}
