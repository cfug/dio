import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http2/http2.dart';
import 'package:test/test.dart';

void registerHostHeaderPortTests(
  Dio Function() getDio,
) {
  test(
    'includes non-default port in host/authority header value',
    () async {
      final dio = getDio();
      final adapterName = dio.httpClientAdapter.runtimeType.toString();

      if (adapterName == 'Http2Adapter') {
        final authorityCompleter = Completer<String>();
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final serverSubscription = server.listen((socket) {
          final connection = ServerTransportConnection.viaSocket(socket);
          connection.incomingStreams.listen((stream) {
            stream.incomingMessages.listen((message) {
              if (message is! HeadersStreamMessage) {
                return;
              }
              for (final header in message.headers) {
                if (utf8.decode(header.name) == ':authority' &&
                    !authorityCompleter.isCompleted) {
                  authorityCompleter.complete(utf8.decode(header.value));
                }
              }
              stream.outgoingMessages.add(
                HeadersStreamMessage(
                  [
                    Header.ascii(':status', '200'),
                    Header.ascii('content-type', 'text/plain'),
                  ],
                ),
              );
              stream.outgoingMessages.add(
                DataStreamMessage(
                  Uint8List.fromList(utf8.encode('ok')),
                  endStream: true,
                ),
              );
            });
          });
        });
        try {
          final response = await dio.get('http://127.0.0.1:${server.port}/get');
          expect(response.statusCode, equals(200));
          expect(
            await authorityCompleter.future,
            equals('127.0.0.1:${server.port}'),
          );
        } finally {
          await serverSubscription.cancel();
          await server.close();
        }
        return;
      }

      final hostCompleter = Completer<String>();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serverSubscription = server.listen((request) async {
        hostCompleter.complete(
          request.headers.value(HttpHeaders.hostHeader)!,
        );
        request.response.statusCode = 200;
        await request.response.close();
      });
      try {
        final response = await dio.get('http://127.0.0.1:${server.port}/get');
        expect(response.statusCode, equals(200));
        expect(
          await hostCompleter.future,
          equals('127.0.0.1:${server.port}'),
        );
      } finally {
        await serverSubscription.cancel();
        await server.close(force: true);
      }
    },
    testOn: 'vm',
  );
}
