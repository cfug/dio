/// A record that records the redirection happens during requests,
/// including status code, request method, and the location.
class RedirectRecord {
  const RedirectRecord(this.statusCode, this.method, this.location);

  /// Returns the status code used for the redirect.
  final int statusCode;

  /// Returns the method used for the redirect.
  final String method;

  /// Returns the location for the redirect.
  final Uri location;

  @override
  String toString() {
    return 'RedirectRecord'
        '{statusCode: $statusCode, method: $method, location: $location}';
  }
}
