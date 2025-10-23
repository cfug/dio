part of 'http2_adapter.dart';

/// Default implementation of ConnectionManager
class _ConnectionManager implements ConnectionManager {
  _ConnectionManager({
    Duration? idleTimeout,
    Duration? handshakeTimeout,
    this.onClientCreate,
    this.proxyConnectedPredicate = defaultProxyConnectedPredicate,
  })  : _idleTimeout = idleTimeout ?? const Duration(seconds: 1),
        _handshakeTimeout = handshakeTimeout ?? const Duration(seconds: 15);

  /// Callback when socket created.
  ///
  /// We can set trusted certificates and handler
  /// for unverifiable certificates.
  final void Function(Uri uri, ClientSetting)? onClientCreate;

  /// {@macro dio_http2_adapter.ProxyConnectedPredicate}
  final ProxyConnectedPredicate proxyConnectedPredicate;

  /// Sets the idle timeout(milliseconds) of non-active persistent
  /// connections. For the sake of socket reuse feature with http/2,
  /// the value should not be less than 1 second.
  final Duration _idleTimeout;

  /// Sets the handshake timeout for secure socket connections.
  ///
  /// This timeout is applied to a future returned by [RawSecureSocket.secure],
  /// which actually is a handshake future.
  final Duration _handshakeTimeout;

  /// Saving the reusable connections
  final _transportsMap = <String, _ClientTransportConnectionState>{};

  /// Saving the connecting futures
  final _connectFutures = <String, Future<_ClientTransportConnectionState>>{};

  bool _closed = false;
  bool _forceClosed = false;

  @override
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
    List<RedirectRecord> redirects,
  ) async {
    if (_closed) {
      throw Exception(
        "Can't establish connection after [ConnectionManager] closed!",
      );
    }
    Uri uri = options.uri;
    if (redirects.isNotEmpty) {
      uri = Http2Adapter.resolveRedirectUri(uri, redirects.last.location);
    }
    // Identify whether the connection can be reused.
    // [Uri.scheme] is required when redirecting from non-TLS to TLS connection.
    final transportCacheKey = '${uri.scheme}://${uri.host}:${uri.port}';
    _ClientTransportConnectionState? transportState =
        _transportsMap[transportCacheKey];
    if (transportState == null) {
      Future<_ClientTransportConnectionState>? initFuture =
          _connectFutures[transportCacheKey];
      if (initFuture == null) {
        _connectFutures[transportCacheKey] =
            initFuture = _connect(options, redirects);
      }
      try {
        transportState = await initFuture;
      } catch (e) {
        _connectFutures.remove(transportCacheKey);
        rethrow;
      }
      if (_forceClosed) {
        transportState.dispose();
      } else {
        _transportsMap[transportCacheKey] = transportState;
        final _ = _connectFutures.remove(transportCacheKey);
      }
    } else {
      // Check whether the connection is terminated, if it is, reconnecting.
      if (!transportState.transport.isOpen) {
        transportState.dispose();
        _transportsMap[transportCacheKey] =
            transportState = await _connect(options, redirects);
      }
    }
    return transportState.activeTransport;
  }

  Future<_ClientTransportConnectionState> _connect(
    RequestOptions options,
    List<RedirectRecord> redirects,
  ) async {
    Uri uri = options.uri;
    if (redirects.isNotEmpty) {
      uri = Http2Adapter.resolveRedirectUri(uri, redirects.last.location);
    }
    final domain = '${uri.host}:${uri.port}';
    final clientConfig = ClientSetting();
    if (onClientCreate != null) {
      onClientCreate!(uri, clientConfig);
    }

    // Allow [Socket] for non-TLS connections
    // or [SecureSocket] for TLS connections.
    late final Socket socket;
    try {
      socket = await _createSocket(uri, options, clientConfig);
    } on SocketException catch (e) {
      if (e.osError == null) {
        if (e.message.contains('timed out')) {
          throw DioException.connectionTimeout(
            timeout: options.connectTimeout ?? Duration.zero,
            requestOptions: options,
          );
        }
      }
      rethrow;
    }

    if (clientConfig.validateCertificate != null) {
      final certificate =
          socket is SecureSocket ? socket.peerCertificate : null;
      final isCertApproved = clientConfig.validateCertificate!(
        certificate,
        uri.host,
        uri.port,
      );
      if (!isCertApproved) {
        // TODO(EVERYONE): Replace with DioException.badCertificate once upgrade dependencies Dio above 5.4.2.
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
          error: certificate,
          message: 'The certificate of the response is not approved.',
        );
      }
    }

    // Config a ClientTransportConnection and save it
    final transport = ClientTransportConnection.viaSocket(socket);
    final transportState = _ClientTransportConnectionState(transport);
    transport.onActiveStateChanged = (bool isActive) {
      transportState.isActive = isActive;
      if (!isActive) {
        transportState.latestIdleTimeStamp = DateTime.now();
      }
    };

    transportState.delayClose(
      _closed ? const Duration(milliseconds: 50) : _idleTimeout,
      () {
        _transportsMap.remove(domain);
        transportState.transport.finish();
      },
    );
    return transportState;
  }

  Future<Socket> _createSocket(
    Uri target,
    RequestOptions options,
    ClientSetting clientConfig,
  ) async {
    final timeout = (options.connectTimeout ?? Duration.zero) > Duration.zero
        ? options.connectTimeout!
        : null;
    final proxy = clientConfig.proxy;

    if (proxy == null) {
      if (target.scheme != 'https') {
        return Socket.connect(
          target.host,
          target.port,
          timeout: timeout,
        );
      }
      final socket = await SecureSocket.connect(
        target.host,
        target.port,
        timeout: timeout,
        context: clientConfig.context,
        onBadCertificate: clientConfig.onBadCertificate,
        supportedProtocols: ['h2'],
      ).timeout(_handshakeTimeout);
      _throwIfH2NotSelected(target, socket);
      return socket;
    }

    final proxySocket = await Socket.connect(
      proxy.host,
      proxy.port,
      timeout: timeout,
    );

    final String credentialsProxy = base64Encode(utf8.encode(proxy.userInfo));

    // Create http tunnel proxy https://www.ietf.org/rfc/rfc2817.txt

    // Use CRLF as the end of the line https://www.ietf.org/rfc/rfc2616.txt
    const crlf = '\r\n';

    // TODO(EVERYONE): Figure out why we can only use an HTTP/1.x proxy here.
    const proxyProtocol = 'HTTP/1.1';
    proxySocket.write('CONNECT ${target.host}:${target.port} $proxyProtocol');
    proxySocket.write(crlf);
    proxySocket.write('Host: ${target.host}:${target.port}');

    if (credentialsProxy.isNotEmpty) {
      proxySocket.write(crlf);
      proxySocket.write('Proxy-Authorization: Basic $credentialsProxy');
    }

    proxySocket.write(crlf);
    proxySocket.write(crlf);

    final completerProxyInitialization = Completer<void>();

    Never onProxyError(Object? error, StackTrace stackTrace) {
      throw DioException(
        requestOptions: options,
        error: error,
        type: DioExceptionType.connectionError,
        stackTrace: stackTrace,
      );
    }

    completerProxyInitialization.future.onError(onProxyError);

    final proxySubscription = proxySocket.listen(
      (event) {
        final response = ascii.decode(event);
        final lines = response.split(crlf);
        final statusLine = lines.first;
        if (!completerProxyInitialization.isCompleted) {
          if (proxyConnectedPredicate(proxyProtocol, statusLine)) {
            completerProxyInitialization.complete();
          } else {
            completerProxyInitialization.completeError(
              SocketException(
                'Proxy cannot be initialized with status = [$statusLine], '
                'host = ${target.host}, port = ${target.port}',
              ),
            );
          }
        }
      },
      onError: (e, s) {
        if (!completerProxyInitialization.isCompleted) {
          completerProxyInitialization.completeError(e, s);
        }
      },
    );
    await completerProxyInitialization.future;

    final socket = await SecureSocket.secure(
      proxySocket,
      host: target.host,
      context: clientConfig.context,
      onBadCertificate: clientConfig.onBadCertificate,
      supportedProtocols: ['h2'],
    ).timeout(_handshakeTimeout);
    _throwIfH2NotSelected(target, socket);

    proxySubscription.cancel();

    return socket;
  }

  @override
  void removeConnection(ClientTransportConnection transport) {
    _ClientTransportConnectionState? transportState;
    _transportsMap.removeWhere((_, state) {
      if (state.transport == transport) {
        transportState = state;
        return true;
      }
      return false;
    });
    transportState?.dispose();
  }

  @override
  void close({bool force = false}) {
    _closed = true;
    _forceClosed = force;
    if (force) {
      _transportsMap.forEach((key, value) => value.dispose());
    }
  }

  void _throwIfH2NotSelected(Uri target, SecureSocket socket) {
    if (socket.selectedProtocol != 'h2') {
      throw DioH2NotSupportedException(target, socket.selectedProtocol);
    }
  }
}

class _ClientTransportConnectionState {
  _ClientTransportConnectionState(this.transport);

  final ClientTransportConnection transport;

  bool isActive = true;
  late DateTime latestIdleTimeStamp;
  Timer? _timer;

  ClientTransportConnection get activeTransport {
    isActive = true;
    latestIdleTimeStamp = DateTime.now();
    return transport;
  }

  void delayClose(Duration idleTimeout, void Function() callback) {
    const duration = Duration(milliseconds: 100);
    idleTimeout = idleTimeout < duration ? duration : idleTimeout;
    _startTimer(callback, idleTimeout, idleTimeout);
  }

  void dispose() {
    _timer?.cancel();
    transport.finish();
  }

  void _startTimer(
    void Function() callback,
    Duration duration,
    Duration idleTimeout,
  ) {
    _timer = Timer(duration, () {
      if (!isActive) {
        final interval = DateTime.now().difference(latestIdleTimeStamp);
        if (interval >= duration) {
          return callback();
        }
        return _startTimer(callback, duration - interval, idleTimeout);
      }
      // if active
      _startTimer(callback, idleTimeout, idleTimeout);
    });
  }
}
