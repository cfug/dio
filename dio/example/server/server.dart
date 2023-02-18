import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '2384');
  final server = await serve(
    handler,
    ip,
    port,
  );

  print('Server listening on http://${server.address.host}:${server.port}');
}


final router = Router()
  ..get('/cors/getCookie', _getCookieHandler)
  ..get('/cors/checkCookie', _checkCookieHandler);

Future<Response> _getCookieHandler(Request request) async {
  final value = request.requestedUri.queryParametersAll['value'];

  if (value == null || value.isEmpty) {
    return Response.badRequest(
        body: 'Get cookies failed. Required parameter is missing.');
  } else {
    return Response.ok(
      'Get cookies success.',
      headers: {
        HttpHeaders.setCookieHeader: [
          'value=${value[0]}; Secure; HttpOnly; SameSite=None',
        ],
      },
    );
  }
}

Response _checkCookieHandler(Request request) {
  final cookies = request.headersAll['Cookie'];
  final value = request.requestedUri.queryParametersAll['value'];

  if (value == null || value.isEmpty){
    return Response.badRequest(
        body: 'Check cookies failed. Required parameter is missing.',);
  } else if (cookies == null || cookies.isEmpty) {
    return Response.badRequest(
        body: 'Check cookies failed. Cookies not received.',);
  } else if (!cookies.any((element) => element.contains('value=${value[0]};'))) {
    return Response.badRequest(
        body: 'Check cookies failed. The cookie does not match the parameter.',);
  } else {
    return Response.ok(
      'Check cookies success!',
    );
  }
}
