part of 'http2_adapter.dart';

class ClientSetting {
  /// The certificate provided by the server is checked
  /// using the trusted certificates set in the SecurityContext object.
  /// The default SecurityContext object contains a built-in set of trusted
  /// root certificates for well-known certificate authorities.
  SecurityContext context;

  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  bool Function(X509Certificate certificate) onBadCertificate;
}
