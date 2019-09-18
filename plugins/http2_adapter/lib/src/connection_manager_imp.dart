part of 'http2_adapter.dart';

/// Default implementation of ConnectionManager
class _ConnectionManager implements ConnectionManager {
  /// Callback when socket created.
  ///
  /// We can set trusted certificates and handler
  /// for unverifiable certificates.
  final void Function(Uri uri, ClientSetting) onClientCreate;

  /// Sets the idle timeout(milliseconds) of non-active persistent
  /// connections. For the sake of socket reuse feature with http/2,
  /// the value should not be less than 1000 (1s).
  final int _idleTimeout;

  /// Saving the reusable connections
  final _transportsMap = Map<String, _ClientTransportConnectionState>();

  /// Saving the connecting futures
  final _connectFutures =
      Map<String, Future<_ClientTransportConnectionState>>();

  bool _closed = false;
  bool _forceClosed = false;

  _ConnectionManager({int idleTimeout, this.onClientCreate})
      : this._idleTimeout = idleTimeout ?? 1000;

  @override
  Future<ClientTransportConnection> getConnection(
      RequestOptions options) async {
    if (_closed) {
      throw Exception(
          "Can't establish connection after [ConnectionManager] closed!");
    }
    Uri uri = options.uri;
    String domain = "${uri.host}:${uri.port}";
    var transportState = _transportsMap[domain];
    if (transportState == null) {
      var _initFuture = _connectFutures[domain];
      if (_initFuture == null) {
        _connectFutures[domain] = _initFuture = _connect(options);
      }
      transportState = await _initFuture;
      if (_forceClosed) {
        transportState.dispose();
      } else {
        _transportsMap[domain] = transportState;
        var _ = _connectFutures.remove(domain);
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
      RequestOptions options) async {
    Uri uri = options.uri;
    String domain = "${uri.host}:${uri.port}";
    ClientSetting clientConfig = ClientSetting();
    if (onClientCreate != null) {
      onClientCreate(uri, clientConfig);
    }
    var socket;
    try {
      // Create socket
      socket = await SecureSocket.connect(
        uri.host,
        uri.port,
        timeout: options.connectTimeout > 0
            ? Duration(milliseconds: options.connectTimeout)
            : null,
        context: clientConfig.context,
        onBadCertificate: clientConfig.onBadCertificate,
        supportedProtocols: ['h2'],
      );
    } on SocketException catch (e) {
      if (e.osError == null) {
        if (e.message.contains("timed out")) {
          throw DioError(
            request: options,
            error: "Connecting timed out [${options.connectTimeout}ms]",
            type: DioErrorType.CONNECT_TIMEOUT,
          );
        }
      }
      rethrow;
    }
    // Config a ClientTransportConnection and save it
    var transport = ClientTransportConnection.viaSocket(socket);
    var _transportState = _ClientTransportConnectionState(transport);
    transport.onActiveStateChanged = (bool isActive) {
      _transportState.isActive = isActive;
      if (!isActive) {
        _transportState.latestIdleTimeStamp =
            DateTime.now().millisecondsSinceEpoch;
      }
    };
    //
    _transportState.delayClose(
      _closed ? 50 : _idleTimeout,
      () {
        _transportsMap.remove(domain);
        _transportState.transport.finish();
      },
    );
    return _transportState;
  }

  @override
  void removeConnection(ClientTransportConnection transport) {
    _ClientTransportConnectionState _transportState;
    _transportsMap.removeWhere((_, state) {
      if (state.transport == transport) {
        _transportState = state;
        return true;
      }
      return false;
    });
    _transportState?.dispose();
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
    latestIdleTimeStamp = DateTime.now().millisecondsSinceEpoch;
    return transport;
  }

  bool isActive = true;
  int latestIdleTimeStamp;
  Timer _timer;

  void delayClose(int idleTimeout, void Function() callback) {
    idleTimeout = idleTimeout < 100 ? 100 : idleTimeout;
    _startTimer(callback, idleTimeout, idleTimeout);
  }

  void dispose() {
    _timer?.cancel();
    transport.finish();
  }

  void _startTimer(void Function() callback, int duration, int idleTimeout) {
    _timer = Timer(Duration(milliseconds: duration), () {
      if (!isActive) {
        int interval =
            DateTime.now().millisecondsSinceEpoch - latestIdleTimeStamp;
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
