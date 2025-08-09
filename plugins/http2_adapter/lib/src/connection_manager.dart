part of 'http2_adapter.dart';

/// {@template dio_http2_adapter.ConnectionManager}
/// Manages the connections that should be reusable.
/// It implements a connection reuse strategy for HTTP/2.
/// {@endtemplate}
abstract class ConnectionManager {
  factory ConnectionManager({
    Duration idleTimeout = const Duration(seconds: 15),
    Duration handshakeTimout = const Duration(seconds: 15),
    void Function(Uri uri, ClientSetting)? onClientCreate,
    ProxyConnectedPredicate proxyConnectedPredicate =
        defaultProxyConnectedPredicate,
  }) =>
      _ConnectionManager(
        idleTimeout: idleTimeout,
        handshakeTimeout: handshakeTimout,
        onClientCreate: onClientCreate,
        proxyConnectedPredicate: proxyConnectedPredicate,
      );

  /// Get the connection(may reuse) for each request.
  Future<ClientTransportConnection> getConnection(
    RequestOptions options,
    List<RedirectRecord> redirects,
  );

  void removeConnection(ClientTransportConnection transport);

  void close({bool force = false});
}

/// {@template dio_http2_adapter.ProxyConnectedPredicate}
/// Checks whether the proxy has been connected through the given [status].
/// {@endtemplate}
typedef ProxyConnectedPredicate = bool Function(String protocol, String status);

/// Accepts HTTP/1.x connections for proxies.
bool defaultProxyConnectedPredicate(String protocol, String status) {
  return status.startsWith(RegExp(r'HTTP/1+\.\d 200'));
}
