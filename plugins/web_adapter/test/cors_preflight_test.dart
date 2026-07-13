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

  group('collectCorsPreflightReasons', () {
    test('simple GET produces no reasons', () {
      final options = RequestOptions(method: 'GET');
      expect(
        collectCorsPreflightReasons(options),
        isEmpty,
      );
    });

    test('upload listener adds a reason', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
      );
      final reasons = collectCorsPreflightReasons(
        options,
        willRegisterUploadListener: true,
      );
      expect(reasons, hasLength(1));
      expect(reasons.first, contains('upload progress listener'));
    });

    test('withCredentials adds a reason', () {
      final options = RequestOptions(method: 'GET');
      final reasons = collectCorsPreflightReasons(
        options,
        withCredentials: true,
      );
      expect(reasons, hasLength(1));
      expect(reasons.first, contains('withCredentials'));
    });

    test('non-simple method and upload listener and withCredentials', () {
      final options = RequestOptions(method: 'PUT');
      final reasons = collectCorsPreflightReasons(
        options,
        willRegisterUploadListener: true,
        withCredentials: true,
      );
      expect(reasons, hasLength(3));
      expect(reasons[0], contains('PUT'));
      expect(reasons[1], contains('upload progress listener'));
      expect(reasons[2], contains('withCredentials'));
    });

    test('simple POST with text/plain and no listener is empty', () {
      final options = RequestOptions(
        method: 'POST',
        headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
      );
      expect(
        collectCorsPreflightReasons(options),
        isEmpty,
      );
    });
  });

  group('corsEnrichedErrorReason', () {
    const baseReason = 'The XMLHttpRequest onError callback was called. '
        'This typically indicates an error on the network layer.';

    test('returns base reason when no preflight reasons', () {
      expect(
        corsEnrichedErrorReason(baseReason, []),
        baseReason,
      );
    });

    test('appends CORS guidance when preflight reasons exist', () {
      final reason = corsEnrichedErrorReason(baseReason, [
        'the request method "PUT" is not a CORS-safelisted method',
      ]);
      expect(reason, startsWith(baseReason));
      expect(reason, contains('cross-origin'));
      expect(reason, contains('PUT'));
      expect(reason, contains('CORS preflight'));
    });

    test('joins multiple reasons with semicolons', () {
      final reason = corsEnrichedErrorReason(baseReason, [
        'reason one',
        'reason two',
      ]);
      expect(reason, contains('reason one; reason two'));
    });
  });
}
