@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

// Regression test for RequestOptions.uri appending queryParameters after
// an existing #fragment in path, which per RFC 3986 §3 (URI component
// order is scheme:authority/path?query#fragment) leaks the query text
// into the fragment so the server never receives it as a query.
void main() {
  test(
    'queryParameters are sent as a query even when path has a fragment',
    () async {
      final server = await HttpServer.bind('127.0.0.1', 0);
      String? receivedQuery;
      server.listen((req) {
        receivedQuery = req.uri.query;
        req.response
          ..statusCode = 200
          ..close();
      });
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:${server.port}',
        ),
      );
      await dio.get('/page#section1', queryParameters: {'x': '1'});
      await server.close(force: true);

      expect(receivedQuery, 'x=1');
    },
  );
}
