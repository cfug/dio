import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../adapter.dart';
import '../dio_exception.dart';
import '../options.dart';
import '../redirect_record.dart';

@Deprecated('Use IOHttpClientAdapter instead. This will be removed in 6.0.0')
typedef DefaultHttpClientAdapter = IOHttpClientAdapter;

/// The signature of [IOHttpClientAdapter.onHttpClientCreate].
@Deprecated('Use CreateHttpClient instead. This will be removed in 6.0.0')
typedef OnHttpClientCreate = HttpClient? Function(HttpClient client);

/// The signature of [IOHttpClientAdapter.createHttpClient].
/// Can be used to provide a custom [HttpClient] for Dio.
typedef CreateHttpClient = HttpClient Function();

/// The signature of [IOHttpClientAdapter.validateCertificate].
typedef ValidateCertificate = bool Function(
  X509Certificate? certificate,
  String host,
  int port,
);

/// A helper that builds a [ValidateCertificate] callback for fingerprint-based
/// certificate pinning.
///
/// Pinning is done by comparing the leaf certificate's SHA-1 fingerprint
/// (available natively on all platforms via [X509Certificate.sha1]) against a
/// set of known-good values. For SHA-256 pinning, add the `crypto` package and
/// pass a custom [ValidateCertificate] that computes
/// `sha256.convert(cert!.der).toString()`.
///
/// **Usage:**
/// ```dart
/// final pinner = CertificatePinner(
///   // Obtain with: openssl x509 -in cert.pem -fingerprint -sha1 -noout
///   allowedSHA1Fingerprints: {'AA:BB:CC:DD:EE:...'},
/// );
///
/// final dio = Dio();
/// dio.httpClientAdapter = IOHttpClientAdapter(
///   validateCertificate: pinner.validate,
/// );
/// ```
///
/// **Warning:** Setting `badCertificateCallback: (cert, host, port) => true`
/// on the underlying [HttpClient] (via [IOHttpClientAdapter.createHttpClient])
/// causes dart:io to accept any certificate before Dio's [validateCertificate]
/// is ever called, silently bypassing all pinning. Never use that callback in
/// production.
class CertificatePinner {
  CertificatePinner({
    this.allowedSHA1Fingerprints = const {},
    this.allowedDERCertificates = const {},
  }) : assert(
          allowedSHA1Fingerprints.isNotEmpty ||
              allowedDERCertificates.isNotEmpty,
          'Provide at least one allowedSHA1Fingerprints entry or '
          'allowedDERCertificates entry.',
        );

  /// Allowed SHA-1 fingerprints in colon-separated uppercase hex form,
  /// e.g. `'AA:BB:CC:...'`, as printed by:
  /// `openssl x509 -in cert.pem -fingerprint -sha1 -noout`
  ///
  /// Comparison is case-insensitive.
  final Set<String> allowedSHA1Fingerprints;

  /// Allowed certificates as raw DER-encoded bytes for exact byte comparison.
  final Set<List<int>> allowedDERCertificates;

  /// A [ValidateCertificate] callback for [IOHttpClientAdapter.validateCertificate].
  bool validate(X509Certificate? certificate, String host, int port) {
    if (certificate == null) {
      return false;
    }

    if (allowedSHA1Fingerprints.isNotEmpty) {
      final fingerprint = _toColonHex(certificate.sha1).toUpperCase();
      if (allowedSHA1Fingerprints.any((f) => f.toUpperCase() == fingerprint)) {
        return true;
      }
    }

    if (allowedDERCertificates.isNotEmpty) {
      final der = certificate.der;
      if (allowedDERCertificates.any((allowed) => _bytesEqual(allowed, der))) {
        return true;
      }
    }

    return false;
  }

  static String _toColonHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Creates an [IOHttpClientAdapter].
HttpClientAdapter createAdapter() => IOHttpClientAdapter();

/// The default [HttpClientAdapter] for native platforms.
class IOHttpClientAdapter implements HttpClientAdapter {
  IOHttpClientAdapter({
    @Deprecated('Use createHttpClient instead. This will be removed in 6.0.0')
    this.onHttpClientCreate,
    this.createHttpClient,
    this.validateCertificate,
  });

  /// [Dio] will create [HttpClient] when it is needed. If [onHttpClientCreate]
  /// has provided, [Dio] will call it when a [HttpClient] created.
  @Deprecated('Use createHttpClient instead. This will be removed in 6.0.0')
  OnHttpClientCreate? onHttpClientCreate;

  /// When this callback is set, [Dio] will call it every
  /// time it needs a [HttpClient].
  CreateHttpClient? createHttpClient;

  /// Allows the user to decide if the response certificate is good.
  /// If this function is missing, then the certificate is allowed.
  /// This method is called only if both the [SecurityContext] and
  /// [badCertificateCallback] accept the certificate chain. Those
  /// methods evaluate the root or intermediate certificate, while
  /// [validateCertificate] evaluates the leaf certificate.
  ///
  /// **Security warning:** If you set `badCertificateCallback: (_, __, ___) => true`
  /// on the [HttpClient] created by [createHttpClient], dart:io will accept
  /// any certificate before this callback is reached, silently bypassing all
  /// certificate validation. Never use that pattern in production.
  /// Use [CertificatePinner] to build a pinning callback from SHA-1 fingerprints.
  ValidateCertificate? validateCertificate;

  HttpClient? _cachedHttpClient;
  bool _closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_closed) {
      throw StateError(
        "Can't establish connection after the adapter was closed.",
      );
    }
    return _fetch(options, requestStream, cancelFuture);
  }

  Future<ResponseBody> _fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final httpClient = _configHttpClient(options.connectTimeout);

    // Mutable pointer updated each loop iteration so cancellation always
    // aborts the currently-active request, not a stale one.
    HttpClientRequest? activeRequest;
    cancelFuture?.whenComplete(() {
      activeRequest?.abort();
    });

    final redirects = <RedirectRecord>[];
    var currentUri = options.uri;
    var currentMethod = options.method;
    // Copy so cross-origin header stripping never mutates the original options.
    var currentHeaders = Map<String, dynamic>.from(options.headers);
    // A request body stream can only be consumed once. It is sent on the first
    // hop only; 307/308 redirects that require body replay are followed without
    // a body (stream replay is not supported).
    var sendBodyStream = true;

    while (true) {
      final reqFuture = httpClient.openUrl(currentMethod, currentUri);
      late HttpClientRequest request;

      try {
        final connectionTimeout = options.connectTimeout;
        if (connectionTimeout != null && connectionTimeout > Duration.zero) {
          request = await reqFuture.timeout(
            connectionTimeout,
            onTimeout: () {
              throw DioException.connectionTimeout(
                requestOptions: options,
                timeout: connectionTimeout,
              );
            },
          );
        } else {
          request = await reqFuture;
        }

        activeRequest = request;

        currentHeaders.forEach((key, value) {
          if (value != null) {
            request.headers.set(
              key,
              value,
              preserveHeaderCase: options.preserveHeaderCase,
            );
          }
        });
      } on SocketException catch (e) {
        if (e.message.contains('timed out')) {
          final Duration effectiveTimeout;
          if (options.connectTimeout != null &&
              options.connectTimeout! > Duration.zero) {
            effectiveTimeout = options.connectTimeout!;
          } else if (httpClient.connectionTimeout != null &&
              httpClient.connectionTimeout! > Duration.zero) {
            effectiveTimeout = httpClient.connectionTimeout!;
          } else {
            effectiveTimeout = Duration.zero;
          }
          throw DioException.connectionTimeout(
            requestOptions: options,
            timeout: effectiveTimeout,
            error: e,
          );
        }
        throw DioException.connectionError(
          requestOptions: options,
          reason: e.message,
          error: e,
        );
      }

      // Always disable dart:io's automatic redirect following. Dio handles
      // redirects manually so it can strip sensitive credential headers when
      // a redirect crosses an origin boundary (RFC 9110 §15.4).
      request.followRedirects = false;
      request.maxRedirects = 0;
      request.persistentConnection = options.persistentConnection;

      if (sendBodyStream && requestStream != null) {
        Future<dynamic> future = request.addStream(requestStream);
        final sendTimeout = options.sendTimeout;
        if (sendTimeout != null && sendTimeout > Duration.zero) {
          future = future.timeout(
            sendTimeout,
            onTimeout: () {
              request.abort();
              throw DioException.sendTimeout(
                timeout: sendTimeout,
                requestOptions: options,
              );
            },
          );
        }
        await future;
        // Stream consumed; cannot be replayed on subsequent redirect hops.
        sendBodyStream = false;
      }

      Future<HttpClientResponse> future = request.close();
      final receiveTimeout = options.receiveTimeout ?? Duration.zero;
      if (receiveTimeout > Duration.zero) {
        future = future.timeout(
          receiveTimeout,
          onTimeout: () {
            request.abort();
            throw DioException.receiveTimeout(
              timeout: receiveTimeout,
              requestOptions: options,
            );
          },
        );
      }
      final responseStream = await future;

      // Validate certificate on every hop, not just the first.
      if (validateCertificate != null) {
        final host = currentUri.host;
        final port = currentUri.port;
        final bool isCertApproved = validateCertificate!(
          responseStream.certificate,
          host,
          port,
        );
        if (!isCertApproved) {
          throw DioException.badCertificate(
            requestOptions: options,
            error: responseStream.certificate,
          );
        }
      }

      final statusCode = responseStream.statusCode;

      // Follow redirects with per-hop security enforcement.
      if (options.followRedirects && _isRedirectStatus(statusCode)) {
        final location = responseStream.headers.value('location');
        if (location != null) {
          if (redirects.length >= options.maxRedirects) {
            await responseStream.drain<void>();
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'Redirect limit (${options.maxRedirects}) exceeded.',
            );
          }

          final redirectUri = currentUri.resolve(location);
          final newMethod = _resolveRedirectMethod(currentMethod, statusCode);
          redirects.add(RedirectRecord(statusCode, newMethod, redirectUri));

          // RFC 9110 §15.4: strip credential headers when the redirect
          // crosses an origin boundary (different host or scheme).
          if (redirectUri.host != currentUri.host ||
              redirectUri.scheme != currentUri.scheme) {
            currentHeaders = Map.from(currentHeaders);
            for (final h in _sensitiveRedirectHeaders) {
              currentHeaders.remove(h);
            }
          }

          currentUri = redirectUri;
          currentMethod = newMethod;
          activeRequest = null;
          await responseStream.drain<void>();
          continue;
        }
      }

      // Not a redirect (or redirect without Location header): build response.
      final headers = <String, List<String>>{};
      responseStream.headers.forEach((key, values) {
        headers[key] = values;
      });

      // Extract HTTP protocol version from the response headers.
      // The protocolVersion is available in the internal `_HttpHeaders`
      // implementation but not exposed in the public `HttpHeaders` interface,
      // so we use dynamic access. This may fail in certain environments
      // (e.g., tests with mocks), so we catch and omit errors.
      String? httpVersion;
      try {
        httpVersion = (responseStream.headers as dynamic).protocolVersion;
      } catch (_) {}

      final responseBody = ResponseBody(
        responseStream.cast(),
        statusCode,
        headers: headers,
        isRedirect: redirects.isNotEmpty,
        redirects: redirects,
        statusMessage: responseStream.reasonPhrase,
      );
      if (httpVersion != null) {
        responseBody.extra[HttpClientAdapter.extraKeyHttpVersion] ??=
            httpVersion;
      }
      return responseBody;
    }
  }

  // Headers that must be stripped when a redirect crosses an origin boundary.
  // Based on RFC 9110 §15.4 and the Fetch specification.
  static const _sensitiveRedirectHeaders = {
    'authorization',
    'proxy-authorization',
    'cookie',
  };

  static bool _isRedirectStatus(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  // 303 always changes to GET. 301/302 with POST conventionally change to GET
  // (RFC 7231 recommendation followed by all major browsers/clients).
  static String _resolveRedirectMethod(String method, int statusCode) {
    if (statusCode == 303) {
      return 'GET';
    }
    if ((statusCode == 301 || statusCode == 302) && method == 'POST') {
      return 'GET';
    }
    return method;
  }

  HttpClient _configHttpClient(Duration? connectionTimeout) {
    final client = _cachedHttpClient ??= _createHttpClient();
    connectionTimeout ??= Duration.zero;
    if (connectionTimeout > Duration.zero) {
      client.connectionTimeout = connectionTimeout;
    } else {
      client.connectionTimeout = null;
    }
    return client;
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _cachedHttpClient?.close(force: force);
  }

  HttpClient _createHttpClient() {
    if (createHttpClient != null) {
      return createHttpClient!();
    }
    final client = HttpClient()..idleTimeout = const Duration(seconds: 3);
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    return onHttpClientCreate?.call(client) ?? client;
  }
}
