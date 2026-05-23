import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http2/http2.dart';
import 'package:test/test.dart';

void http2AuthorityTests(
  Dio Function(String baseUrl) create,
) {
  group('http2 authority', () {
    late ServerSocket server;
    late StreamSubscription<Socket> serverSubscription;
    late Future<String> authorityFuture;
    late Dio dio;

    setUp(() async {
      final authorityCompleter = Completer<String>();
      authorityFuture = authorityCompleter.future;
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      serverSubscription = server.listen((socket) {
        final connection = ServerTransportConnection.viaSocket(socket);
        connection.incomingStreams.listen((stream) {
          stream.incomingMessages.listen((message) {
            if (message is HeadersStreamMessage) {
              for (final header in message.headers) {
                if (utf8.decode(header.name) == ':authority' &&
                    !authorityCompleter.isCompleted) {
                  authorityCompleter.complete(utf8.decode(header.value));
                }
              }
              stream.outgoingMessages.add(
                HeadersStreamMessage(
                  [Header.ascii(':status', '200')],
                ),
              );
              stream.outgoingMessages.close();
            }
          });
        });
      });
      dio = create('http://127.0.0.1:${server.port}');
    });

    tearDown(() async {
      dio.close(force: true);
      await serverSubscription.cancel();
      await server.close();
    });

    test('includes non-default port in :authority', () async {
      final response = await dio.get('/get');
      expect(response.statusCode, equals(200));
      expect(
        await authorityFuture,
        equals('127.0.0.1:${server.port}'),
      );
    });
  });
}
