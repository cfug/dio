import 'package:dio/dio.dart';

/// Headers that the CORS spec exempts from preflight for "simple requests".
///
/// Reference: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests
const corsSafelistedRequestHeaders = <String>{
  'accept',
  'accept-language',
  'content-language',
  'content-type',
  'range',
};

/// Content-Type values that the CORS spec treats as "simple".
const corsSimpleContentTypes = <String>{
  'application/x-www-form-urlencoded',
  'multipart/form-data',
  'text/plain',
};

/// Returns a human-readable reason when [options] is likely to trigger a CORS
/// preflight request on the Web platform, or `null` when the request matches
/// the "simple request" criteria.
///
/// This is a pure function over [RequestOptions] so it can be unit-tested
/// without a browser. The upload-progress listener is not considered here
/// because it depends on runtime wiring inside the adapter; callers that
/// register an upload listener should append that reason themselves.
String? corsPreflightReason(RequestOptions options) {
  final method = options.method.toUpperCase();
  if (method != 'GET' && method != 'HEAD' && method != 'POST') {
    return 'the request method "$method" is not a CORS-safelisted method '
        '(GET, HEAD, POST)';
  }
  final contentType = options.headers[Headers.contentTypeHeader];
  final contentTypeValue = contentType is List && contentType.isNotEmpty
      ? contentType.first.toString()
      : contentType?.toString();
  if (contentTypeValue != null && contentTypeValue.isNotEmpty) {
    final mimeType = contentTypeValue.split(';').first.trim().toLowerCase();
    if (mimeType.isNotEmpty && !corsSimpleContentTypes.contains(mimeType)) {
      return 'the Content-Type "$contentTypeValue" is not a CORS-safelisted '
          'value (application/x-www-form-urlencoded, multipart/form-data, '
          'text/plain)';
    }
  }
  for (final key in options.headers.keys) {
    if (!corsSafelistedRequestHeaders.contains(key.toLowerCase())) {
      return 'the request header "$key" is not on the CORS safelist';
    }
  }
  return null;
}
