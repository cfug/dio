part of 'http2_adapter.dart';

typedef ValidateCertificate = bool Function(
  X509Certificate? certificate,
  String host,
  int port,
);

class ClientSetting {
  /// The certificate provided by the server is checked
  /// using the trusted certificates set in the SecurityContext object.
  /// The default SecurityContext object contains a built-in set of trusted
  /// root certificates for well-known certificate authorities.
  SecurityContext? context;

  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  bool Function(X509Certificate certificate)? onBadCertificate;

  /// Allows the user to decide if the response certificate is good.
  /// If this function is missing, then the certificate is allowed.
  /// This method is called only if both the [SecurityContext] and
  /// [badCertificateCallback] accept the certificate chain. Those
  /// methods evaluate the root or intermediate certificate, while
  /// [validateCertificate] evaluates the leaf certificate.
  ValidateCertificate? validateCertificate;

  /// Create clients with the given [proxy] setting.
  /// When it's set, all HTTP/2 traffic from [Dio] will go through the proxy tunnel.
  /// This setting uses [Uri] to correctly pass the scheme, address, and port of the proxy.
  Uri? proxy;
}
