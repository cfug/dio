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

/// Collects all reasons why a request will trigger a CORS preflight, combining
/// the static [corsPreflightReason] analysis with runtime factors that only
/// the adapter knows: whether an upload progress listener will be registered
/// ([willRegisterUploadListener]) and whether credentials are being sent
/// ([withCredentials]).
///
/// Returns an empty list when the request is a CORS "simple request".
/// This is a pure function so it can be unit-tested without a browser.
List<String> collectCorsPreflightReasons(
  RequestOptions options, {
  bool willRegisterUploadListener = false,
  bool withCredentials = false,
}) {
  final reasons = <String>[
    if (corsPreflightReason(options) case final reason?) reason,
  ];
  if (willRegisterUploadListener) {
    reasons.add(
      'an upload progress listener (sendTimeout or onSendProgress) '
      'forces a preflight request',
    );
  }
  if (withCredentials) {
    reasons.add(
      'withCredentials is enabled, which requires a CORS preflight request',
    );
  }
  return reasons;
}

/// Builds the error reason for `XMLHttpRequest.onError`, appending CORS
/// guidance when [preflightReasons] is non-empty.
///
/// This is a pure function so it can be unit-tested without a browser.
String corsEnrichedErrorReason(
  String baseReason,
  List<String> preflightReasons,
) {
  if (preflightReasons.isEmpty) {
    return baseReason;
  }
  return '$baseReason If this is a cross-origin request, the browser may '
      'have blocked it because the request is not a CORS "simple '
      'request" (${preflightReasons.join('; ')}). Verify that the '
      'server responds correctly to the CORS preflight (OPTIONS) '
      'request. See '
      'https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests';
}
