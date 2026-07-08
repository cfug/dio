import 'package:dio/dio.dart';
import 'package:dio_web_adapter/src/cors.dart';
import 'package:test/test.dart';

void main() {
  group('corsPreflightReason', () {
    test('GET with no extra headers is a simple request', () {
      final options = RequestOptions(method: 'GET');
      expect(corsPreflightReason(options), isNull);
    });

    test('HEAD with no extra headers is a simple request', () {
      final options = RequestOptions(method: 'HEAD');
      expect(corsPreflightReason(options), isNull);
    });

    test('POST with text/plain is a simple request', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
      );
      expect(corsPreflightReason(options), isNull);
    });

    test('POST with application/x-www-form-urlencoded is a simple request', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {
          Headers.contentTypeHeader: Headers.formUrlEncodedContentType,
        },
      );
      expect(corsPreflightReason(options), isNull);
    });

    test('POST with multipart/form-data is a simple request', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {
          Headers.contentTypeHeader: Headers.multipartFormDataContentType,
        },
      );
      expect(corsPreflightReason(options), isNull);
    });

    test('PUT is not a simple request', () {
      final options = RequestOptions(method: 'PUT');
      final reason = corsPreflightReason(options);
      expect(reason, isNotNull);
      expect(reason, contains('PUT'));
      expect(reason, contains('CORS-safelisted method'));
    });

    test('DELETE is not a simple request', () {
      final options = RequestOptions(method: 'DELETE');
      expect(corsPreflightReason(options), contains('DELETE'));
    });

    test('PATCH is not a simple request', () {
      final options = RequestOptions(method: 'PATCH');
      expect(corsPreflightReason(options), contains('PATCH'));
    });

    test('custom header is not a simple request', () {
      final options = RequestOptions(
        method: 'GET',
        headers: {'x-custom-header': 'value'},
      );
      final reason = corsPreflightReason(options);
      expect(reason, isNotNull);
      expect(reason, contains('x-custom-header'));
      expect(reason, contains('CORS safelist'));
    });

    test('application/json content type is not a simple request', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      );
      final reason = corsPreflightReason(options);
      expect(reason, isNotNull);
      expect(reason, contains('application/json'));
      expect(reason, contains('CORS-safelisted value'));
    });

    test('content type with charset suffix is parsed by mime type', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {Headers.contentTypeHeader: 'text/plain; charset=utf-8'},
      );
      expect(corsPreflightReason(options), isNull);
    });

    test('application/json with charset is not a simple request', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {
          Headers.contentTypeHeader: 'application/json; charset=utf-8',
        },
      );
      expect(corsPreflightReason(options), contains('application/json'));
    });

    test('safelisted headers do not trigger preflight', () {
      final options = RequestOptions(
        method: 'GET',
        headers: {
          'accept': 'application/json',
          'accept-language': 'en-US',
          'content-language': 'en',
        },
      );
      expect(corsPreflightReason(options), isNull);
    });

    test('content-type header value as a list is handled', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
      expect(corsPreflightReason(options), contains('application/json'));
    });

    test('method is case-insensitive', () {
      final options = RequestOptions(method: 'get');
      expect(corsPreflightReason(options), isNull);
    });
  });
}
