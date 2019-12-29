part of 'http2_adapter.dart';

/// ConnectionManager is used to manager the connections that should be reusable.
/// The main responsibility of ConnectionManager is to implement a connection reuse
/// strategy for http2.
abstract class ConnectionManager {
  factory ConnectionManager({
    int idleTimeout = 15000,
    void Function(Uri uri, ClientSetting) onClientCreate,
  }) =>
      _ConnectionManager(
        idleTimeout: idleTimeout,
        onClientCreate: onClientCreate,
      );

  /// Get the connection(may reuse) for each request.
  Future<ClientTransportConnection> getConnection(RequestOptions options);

  void removeConnection(ClientTransportConnection transport);

  void close({bool force = false});
}
