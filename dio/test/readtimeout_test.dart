@TestOn("vm")
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

const SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED = 5000;

HttpServer? _server;

late Uri serverUrl;

Future<int> getUnusedPort() async {
  HttpServer? server;
  try {
    server = await HttpServer.bind('localhost', 0);
    return server.port;
  } finally {
    server?.close();
  }
}

void startServer() async {
  var port = await getUnusedPort();
  serverUrl = Uri.parse('http://localhost:$port');
  _server = await HttpServer.bind('localhost', port);
  _server?.listen((request) {
    const content = 'success';
    var response = request.response;

    sleep(const Duration(
        milliseconds: SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED));

    response
      ..statusCode = 200
      ..contentLength = content.length
      ..write(content);

    response.close();
    return;
  });
}

void stopServer() {
  if (_server != null) {
    _server!.close();
    _server = null;
  }
}

void main() {
  setUp(startServer);

  tearDown(stopServer);

  test(
      '#read_timeout - catch DioError when receiveTimeout < $SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED',
      () async {
    var dio = Dio();

    dio.options
      ..baseUrl = serverUrl.toString()
      ..receiveTimeout = SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED - 1000;

    DioError error;

    try {
      await dio.get('/');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    //print(error);
    expect(error.type == DioErrorType.receiveTimeout, isTrue);
  });

  test(
      '#read_timeout - no DioError when receiveTimeout > $SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED',
      () async {
    var dio = Dio();

    dio.options
      ..baseUrl = serverUrl.toString()
      ..connectTimeout = SLEEP_DURATION_AFTER_CONNECTION_ESTABLISHED + 1000;

    DioError? error;

    try {
      await dio.get('/');
    } on DioError catch (e) {
      error = e;
      print(e.requestOptions.uri);
    }

    expect(error, isNull);
  });
}
