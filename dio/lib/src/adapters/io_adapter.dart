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

/// Internal sentinel thrown from [IOHttpClientAdapter]'s connection factory
/// when [IOHttpClientAdapter.validateCertificate] rejects the peer certificate.
/// [_fetch] catches it and rethrows as [DioException.badCertificate].
class _BadCertificateException implements HandshakeException {
  _BadCertificateException(this.host, this.port, this.cert);

  final String host;
  final int port;
  final X509Certificate? cert;

  @override
  String get type => 'HandshakeException';

  @override
  String get message => 'validateCertificate returned false';

  @override
  OSError? get osError => null;

  @override
  String toString() =>
      'HandshakeException: $message (host=$host, port=$port)';
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
  ///
  /// Note: supplying this disables the pre-emission TLS hook used by
  /// [validateCertificate]. See [validateCertificate] for details.
  CreateHttpClient? createHttpClient;

  /// Allows the user to decide if the leaf certificate of the TLS connection
  /// is good. If this function is missing, then the certificate is allowed.
  ///
  /// For **direct HTTPS** connections (no proxy) with the default
  /// [createHttpClient], this callback fires **before** the request body
  /// is sent, immediately after the TLS handshake completes. Returning
  /// `false` aborts the connection without leaking any request data and
  /// surfaces as [DioException.badCertificate]. This makes the callback
  /// suitable for certificate or public-key pinning.
  ///
  /// The callback also runs **after the response head arrives** for the
  /// same connection. The two invocations receive the same leaf
  /// certificate, so for fingerprint-style pinning the second call is
  /// idempotent. If your callback has side effects (logging, metrics),
  /// expect to see them twice per request on the direct-HTTPS path.
  ///
  /// **HTTPS through a proxy:** `HttpClient` performs its own `CONNECT`
  /// tunnel and TLS handshake, so the pre-emission hook is bypassed.
  /// Validation runs only post-response on this path — the request body
  /// has already been transmitted by the time the callback is invoked.
  /// For pre-emission pinning behind a proxy, use [createHttpClient] and
  /// install your own `connectionFactory` on the returned client.
  ///
  /// **Custom [createHttpClient]:** dio cannot install the pre-emission
  /// hook on a user-built [HttpClient]; the callback runs post-response
  /// (the legacy 5.x behavior). For pre-emission validation in that case,
  /// set `connectionFactory` on the [HttpClient] you return.
  ///
  /// On the pre-emission path, this callback is the **sole** gate for
  /// certificate trust: system / CA validation is bypassed (the equivalent
  /// of `HttpClient.badCertificateCallback: (_, _, _) => true` in the
  /// existing example), so the callback receives every leaf cert and is
  /// solely responsible for accepting or rejecting it. This matches what
  /// users already configure manually for pinning and lets self-signed and
  /// pinned-CA setups work without supplying [createHttpClient]. If you
  /// do not intend to perform pinning, do not set this callback —
  /// supplying any non-null value disables stdlib chain validation.
  ///
  /// Any [SecurityContext] you set on a custom [HttpClient] is **not**
  /// used by the pre-emission path. To combine mTLS or a custom trust store
  /// with pinning, supply a [createHttpClient] and pin in the post-response
  /// path.
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
    final reqFuture = httpClient.openUrl(options.method, options.uri);
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

      final requestWR = WeakReference<HttpClientRequest>(request);
      cancelFuture?.whenComplete(() {
        requestWR.target?.abort();
      });

      // Set Headers
      options.headers.forEach((key, value) {
        if (value != null) {
          request.headers.set(
            key,
            value,
            preserveHeaderCase: options.preserveHeaderCase,
          );
        }
      });
    } on _BadCertificateException catch (e) {
      throw DioException.badCertificate(
        requestOptions: options,
        error: e.cert,
      );
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

    request.followRedirects = options.followRedirects;
    request.maxRedirects = options.maxRedirects;
    request.persistentConnection = options.persistentConnection;

    if (requestStream != null) {
      // Transform the request data.
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

    if (validateCertificate != null) {
      // Post-response validation runs unconditionally as defense in depth.
      // On the pre-emission path it is redundant — the same cert was
      // already approved by the [HttpClient.connectionFactory] hook — but
      // it is the only line of defense for paths where pre-emission did
      // not run: (a) when the user supplied a custom [createHttpClient],
      // (b) when [validateCertificate] was set after the [HttpClient] was
      // first cached, or (c) for HTTPS through a proxy (see the doc-comment
      // on [validateCertificate]). For pinning the callback is idempotent
      // so the redundancy is harmless; callbacks with side effects will
      // observe one extra call per request on the direct-HTTPS path.
      // On plain HTTP, [responseStream.certificate] is null and the user
      // typically rejects nulls (matching the example).
      final host = options.uri.host;
      final port = options.uri.port;
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
      responseStream.statusCode,
      headers: headers,
      isRedirect:
          responseStream.isRedirect || responseStream.redirects.isNotEmpty,
      redirects: responseStream.redirects
          .map((e) => RedirectRecord(e.statusCode, e.method, e.location))
          .toList(),
      statusMessage: responseStream.reasonPhrase,
    );
    if (httpVersion != null) {
      responseBody.extra[HttpClientAdapter.extraKeyHttpVersion] ??= httpVersion;
    }
    return responseBody;
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
    if (validateCertificate != null) {
      client.connectionFactory = _pinnedConnectionFactory;
    }
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    return onHttpClientCreate?.call(client) ?? client;
  }

  /// Custom connection factory that performs the TLS handshake and runs
  /// [validateCertificate] *before* yielding the socket to [HttpClient],
  /// so a rejected certificate cannot leak request bytes.
  ///
  /// For HTTPS requests routed through a proxy, this factory cannot
  /// pre-emption-validate: HttpClient writes its own `CONNECT` and performs
  /// its own TLS handshake on top of the socket we return. In that case the
  /// proxy branch returns a plain socket to the proxy and validation falls
  /// back to the post-response check in [_fetch].
  Future<ConnectionTask<Socket>> _pinnedConnectionFactory(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  ) async {
    // Proxy: hand HttpClient a plain socket to the proxy and let it own the
    // CONNECT-tunnel and TLS upgrade. The post-response block in [_fetch]
    // performs validation in this path.
    if (proxyHost != null) {
      return Socket.startConnect(proxyHost, proxyPort!);
    }

    // Plain HTTP, no proxy: hand HttpClient the target socket.
    if (url.scheme != 'https') {
      return Socket.startConnect(url.host, url.port);
    }

    // Snapshot at call time so a runtime mutation of the public field
    // is honored on every new connection.
    final validator = validateCertificate;

    // [SecureSocket.startConnect] returns a stock SDK [ConnectionTask] —
    // available since well before dio's min SDK of 2.18 — so we don't
    // need [ConnectionTask.fromSocket] (Dart 3.5+) and don't need to
    // subclass/vendor [ConnectionTask] (which is `final class` from Dart
    // 3.0). We await `task.socket` once here to do the leaf-cert check,
    // then return the same task; [HttpClient] re-awaits `task.socket`
    // and gets the already-resolved [SecureSocket] immediately.
    //
    // Covariance: [ConnectionTask] has no bound on its type parameter,
    // so [ConnectionTask<SecureSocket>] is implicitly assignable to
    // [ConnectionTask<Socket>] at the return position.
    final task = await SecureSocket.startConnect(
      url.host,
      url.port,
      supportedProtocols: const ['http/1.1'],
      // When [validateCertificate] is set, defer all certificate
      // validation to the user's callback. This makes self-signed and
      // pinned-CA setups work without forcing the user to also supply
      // [createHttpClient].
      onBadCertificate: validator == null ? null : (_) => true,
    );
    if (validator != null) {
      final ss = await task.socket;
      final cert = ss.peerCertificate;
      if (!validator(cert, url.host, url.port)) {
        ss.destroy();
        throw _BadCertificateException(url.host, url.port, cert);
      }
    }
    return task;
  }
}
