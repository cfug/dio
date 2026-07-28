part of 'http2_adapter.dart';

/// {@template dio_http2_adapter.ConnectionManager}
/// Manages the connections that should be reusable.
/// It implements a connection reuse strategy for HTTP/2.
/// {@endtemplate}
abstract class ConnectionManager {
  /// Creates a [ConnectionManager].
  ///
  /// [supportedProtocols] sets the ALPN protocol list advertised during TLS
  /// handshake. Set to `['h2', 'http/1.1']` together with a
  /// [Http2Adapter.fallbackAdapter] to support servers that strictly disable h2
  factory ConnectionManager({
    Duration idleTimeout = const Duration(seconds: 15),
    Duration handshakeTimout = const Duration(seconds: 15),
    void Function(Uri uri, ClientSetting)? onClientCreate,
    ProxyConnectedPredicate proxyConnectedPredicate =
        defaultProxyConnectedPredicate,
    List<String> supportedProtocols = const ['h2'],
  }) =>
      _ConnectionManager(
        idleTimeout: idleTimeout,
        handshakeTimeout: handshakeTimout,
        onClientCreate: onClientCreate,
        proxyConnectedPredicate: proxyConnectedPredicate,
        supportedProtocols: supportedProtocols,
      );

  /// Get the connection(may reuse) for each request.
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
    List<RedirectRecord> redirects,
  );

  void removeConnection(ClientTransportConnection transport);

  void close({bool force = false});

  /// Returns the number of cached connections.
  ///
  /// This is exposed for testing purposes to verify that connections
  /// are properly cleaned up after idle timeout.
  @visibleForTesting
  int get cachedConnectionsCount;
}

/// {@template dio_http2_adapter.ProxyConnectedPredicate}
/// Checks whether the proxy has been connected through the given [status].
/// {@endtemplate}
typedef ProxyConnectedPredicate = bool Function(String protocol, String status);

/// Accepts HTTP/1.x connections for proxies.
bool defaultProxyConnectedPredicate(String protocol, String status) {
  return status.startsWith(RegExp(r'HTTP/1+\.\d 200'));
}
