class RedirectRecord {
  RedirectRecord(this.statusCode, this.method, this.location);

  /// Returns the status code used for the redirect.
  final int statusCode;

  /// Returns the method used for the redirect.
  final String method;

  ///Returns the location for the redirect.
  final Uri location;
}
