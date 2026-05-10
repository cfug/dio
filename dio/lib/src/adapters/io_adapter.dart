import 'dart:async';
import 'dart:convert';
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
  /// When [createHttpClient] is **not** set, this callback fires **before**
  /// the request body is sent, immediately after the TLS handshake completes.
  /// Returning `false` aborts the connection without leaking any request
  /// data and surfaces as [DioException.badCertificate]. This makes the
  /// callback suitable for certificate or public-key pinning.
  ///
  /// When [createHttpClient] **is** supplied, dio cannot install the
  /// pre-emission hook on the user-built [HttpClient]; the callback then
  /// runs after the response head arrives (the legacy 5.x behavior). For
  /// pre-emission validation in that case, set `connectionFactory` on the
  /// [HttpClient] you return.
  ///
  /// Validation runs once per TCP connection, not per request. Connections
  /// are pooled by [HttpClient], so multiple requests to the same host
  /// within `idleTimeout` will produce one approval call.
  ///
  /// On the pre-emission path, this callback is the **sole** gate for
  /// certificate trust: system / CA validation is bypassed (the equivalent
  /// of `HttpClient.badCertificateCallback: (_, _, _) => true` in the
  /// existing example), so the callback receives every leaf cert and is
  /// solely responsible for accepting or rejecting it. This matches what
  /// users already configure manually for pinning and lets self-signed and
  /// pinned-CA setups work without supplying [createHttpClient].
  ///
  /// Any [SecurityContext] you set on a custom [HttpClient] is **not**
  /// used by the pre-emission path. To combine mTLS or a custom trust store
  /// with pinning, supply a [createHttpClient] and pin in the legacy
  /// post-response path.
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

    if (validateCertificate != null && createHttpClient != null) {
      // Legacy post-response validation: only runs when the user supplied
      // a custom [createHttpClient]. In that case we cannot install the
      // pre-emission [HttpClient.connectionFactory] without clobbering the
      // user's client, so the callback runs after the response head has
      // arrived. See the doc-comment on [validateCertificate].
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

  /// Custom connection factory that performs TLS handshake and runs
  /// [validateCertificate] *before* yielding the socket to [HttpClient],
  /// so a rejected certificate cannot leak request bytes.
  Future<ConnectionTask<Socket>> _pinnedConnectionFactory(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  ) async {
    // Plain HTTP — no TLS handshake to gate.
    if (url.scheme != 'https') {
      if (proxyHost != null) {
        return Socket.startConnect(proxyHost, proxyPort!);
      }
      return Socket.startConnect(url.host, url.port);
    }

    // Snapshot at call time so a runtime mutation of the public field
    // is honored on every new connection.
    final validator = validateCertificate;

    if (proxyHost != null) {
      return _connectHttpsViaProxy(url, proxyHost, proxyPort!, validator);
    }

    final socketFuture = () async {
      final ss = await SecureSocket.connect(
        url.host,
        url.port,
        supportedProtocols: const ['http/1.1'],
        // When [validateCertificate] is set, defer all certificate validation
        // to the user's callback. This makes self-signed and pinned-CA setups
        // work without forcing the user to also supply [createHttpClient].
        onBadCertificate: validator == null ? null : (_) => true,
      );
      if (validator != null) {
        _validatePeerCertificate(ss, url.host, url.port, validator);
      }
      return ss as Socket;
    }();
    return ConnectionTask.fromSocket(socketFuture, () {});
  }

  Future<ConnectionTask<Socket>> _connectHttpsViaProxy(
    Uri target,
    String proxyHost,
    int proxyPort,
    ValidateCertificate? validator,
  ) async {
    Socket? proxySocket;
    bool cancelled = false;

    final socketFuture = () async {
      proxySocket = await Socket.connect(proxyHost, proxyPort);
      if (cancelled) {
        proxySocket!.destroy();
        throw const SocketException('connection cancelled');
      }

      // HTTP/1.1 CONNECT tunnel preamble.
      const crlf = '\r\n';
      final preamble = StringBuffer()
        ..write('CONNECT ${target.host}:${target.port} HTTP/1.1$crlf')
        ..write('Host: ${target.host}:${target.port}$crlf')
        ..write(crlf);
      proxySocket!.write(preamble.toString());

      final completer = Completer<void>();
      late StreamSubscription<List<int>> subscription;
      subscription = proxySocket!.listen(
        (event) {
          if (completer.isCompleted) {
            return;
          }
          final response = ascii.decode(event);
          final statusLine = response.split(crlf).first;
          if (statusLine.contains(' 200 ')) {
            completer.complete();
          } else {
            completer.completeError(
              SocketException(
                'Proxy CONNECT failed: $statusLine '
                '(host=${target.host}, port=${target.port})',
              ),
            );
          }
        },
        onError: (Object e, StackTrace s) {
          if (!completer.isCompleted) {
            completer.completeError(e, s);
          }
        },
      );
      try {
        await completer.future;
      } finally {
        await subscription.cancel();
      }

      final ss = await SecureSocket.secure(
        proxySocket!,
        host: target.host,
        supportedProtocols: const ['http/1.1'],
        onBadCertificate: validator == null ? null : (_) => true,
      );
      if (validator != null) {
        _validatePeerCertificate(ss, target.host, target.port, validator);
      }
      return ss as Socket;
    }();

    return ConnectionTask.fromSocket(socketFuture, () {
      cancelled = true;
      proxySocket?.destroy();
    });
  }

  void _validatePeerCertificate(
    SecureSocket ss,
    String host,
    int port,
    ValidateCertificate validator,
  ) {
    final cert = ss.peerCertificate;
    if (!validator(cert, host, port)) {
      ss.destroy();
      throw _BadCertificateException(host, port, cert);
    }
  }
}
