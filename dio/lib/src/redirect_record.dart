/// The redirection happens during requests, contains the redirect status code,
/// the redirection method, and the redirect target location.
class RedirectRecord {
  const RedirectRecord(this.statusCode, this.method, this.location);

  /// Returns the status code used for the redirect.
  final int statusCode;

  /// Returns the method used for the redirect.
  final String method;

  /// Returns the location for the redirect.
  final Uri location;
}
