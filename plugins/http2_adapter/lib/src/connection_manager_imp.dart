part of 'http2_adapter.dart';

/// Default implementation of ConnectionManager
class _ConnectionManager implements ConnectionManager {
  _ConnectionManager({
    Duration? idleTimeout,
    this.onClientCreate,
  }) : _idleTimeout = idleTimeout ?? const Duration(seconds: 1);

  /// Callback when socket created.
  ///
  /// We can set trusted certificates and handler
  /// for unverifiable certificates.
  final void Function(Uri uri, ClientSetting)? onClientCreate;

  /// Sets the idle timeout(milliseconds) of non-active persistent
  /// connections. For the sake of socket reuse feature with http/2,
  /// the value should not be less than 1 second.
  final Duration _idleTimeout;

  /// Saving the reusable connections
  final _transportsMap = <String, _ClientTransportConnectionState>{};

  /// Saving the connecting futures
  final _connectFutures = <String, Future<_ClientTransportConnectionState>>{};

  bool _closed = false;
  bool _forceClosed = false;

  @override
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
  ) async {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [ConnectionManager] closed!");
    }
    final uri = options.uri;
    final domain = '${uri.host}:${uri.port}';
    _ClientTransportConnectionState? transportState = _transportsMap[domain];
    if (transportState == null) {
      Future<_ClientTransportConnectionState>? initFuture =
          _connectFutures[domain];
      if (initFuture == null) {
        _connectFutures[domain] = initFuture = _connect(options);
      }
      transportState = await initFuture;
      if (_forceClosed) {
        transportState.dispose();
      } else {
        _transportsMap[domain] = transportState;
        final _ = _connectFutures.remove(domain);
      }
    } else {
      // Check whether the connection is terminated, if it is, reconnecting.
      if (!transportState.transport.isOpen) {
        transportState.dispose();
        _transportsMap[domain] = transportState = await _connect(options);
      }
    }
    return transportState.activeTransport;
  }

  Future<_ClientTransportConnectionState> _connect(
    RequestOptions options,
  ) async {
    final uri = options.uri;
    final domain = '${uri.host}:${uri.port}';
    final clientConfig = ClientSetting();
    if (onClientCreate != null) {
      onClientCreate!(uri, clientConfig);
    }
    late SecureSocket socket;
    try {
      // Create socket
      if (clientConfig.proxy != null) {
        socket = await _createSocketWithProxy(
          uri,
          options,
          clientConfig,
          clientConfig.proxy!,
        );
      } else {
        socket = await _createSocket(
          uri,
          options,
          clientConfig,
        );
      }
    } on SocketException catch (e) {
      if (e.osError == null) {
        if (e.message.contains('timed out')) {
          throw DioError.connectionTimeout(
            timeout: options.connectTimeout!,
            requestOptions: options,
          );
        }
      }
      rethrow;
    }

    if (clientConfig.validateCertificate != null) {
      final isCertApproved = clientConfig.validateCertificate!(
          socket.peerCertificate, uri.host, uri.port);
      if (!isCertApproved) {
        throw DioError(
          requestOptions: options,
          type: DioErrorType.badCertificate,
          error: socket.peerCertificate,
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
    //
    transportState.delayClose(
      _closed ? Duration(milliseconds: 50) : _idleTimeout,
      () {
        _transportsMap.remove(domain);
        transportState.transport.finish();
      },
    );
    return transportState;
  }

  Future<SecureSocket> _createSocket(
    Uri target,
    RequestOptions options,
    ClientSetting clientConfig,
  ) async {
    final socket = await SecureSocket.connect(
      target.host,
      target.port,
      timeout: options.connectTimeout,
      context: clientConfig.context,
      onBadCertificate: clientConfig.onBadCertificate,
      supportedProtocols: ['h2'],
    );

    return socket;
  }

  Future<SecureSocket> _createSocketWithProxy(
    Uri target,
    RequestOptions options,
    ClientSetting clientConfig,
    Uri proxy,
  ) async {
    late Socket proxySocket;

    proxySocket = await Socket.connect(
      proxy.host,
      proxy.port,
      timeout: options.connectTimeout,
    );

    //Send proxy headers
    const crlf = '\r\n';
    proxySocket.write('CONNECT ${target.host}:${target.port} HTTP/1.1');
    proxySocket.write(crlf);
    proxySocket.write('Host: ${target.host}:${target.port}');
    proxySocket.write(crlf);
    proxySocket.write(crlf);

    final completer = Completer<void>();

    completer.future.onError((error, stackTrace) => {
          throw DioError(
            requestOptions: options,
            error: 'Proxy connection error: $error',
            type: DioErrorType.other,
          )
        });

    final sub = proxySocket.listen(
      (event) {
        final response = ascii.decode(event);
        final lines = response.split(crlf);
        final statusLine = lines.first;
        if (statusLine.startsWith('HTTP/1.1 200')) {
          completer.complete();
        } else {
          completer.completeError(statusLine);
        }
      },
      onError: completer.completeError,
    );

    await completer.future;

    final socket = await SecureSocket.secure(
      proxySocket,
      host: target.host,
      context: clientConfig.context,
      onBadCertificate: clientConfig.onBadCertificate,
      supportedProtocols: ['h2'],
    );

    sub.cancel();

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
}

class _ClientTransportConnectionState {
  _ClientTransportConnectionState(this.transport);

  ClientTransportConnection transport;

  ClientTransportConnection get activeTransport {
    isActive = true;
    latestIdleTimeStamp = DateTime.now();
    return transport;
  }

  bool isActive = true;
  late DateTime latestIdleTimeStamp;
  Timer? _timer;

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
