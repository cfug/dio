import 'dart:convert';
import 'options.dart';
import 'headers.dart';
import 'redirect_record.dart';

/// Response describes the http Response info.
class Response<T> {
  Response({
    this.data,
    required this.requestOptions,
    this.statusCode,
    this.statusMessage,
    this.isRedirect = false,
    this.redirects = const [],
    this.extra = const {},
    Headers? headers,
  }) : headers = headers ?? Headers();

  /// Response body. may have been transformed, please refer to [ResponseType].
  T? data;

  /// The corresponding request info.
  RequestOptions requestOptions;

  /// HTTP status code.
  int? statusCode;

  /// Returns the reason phrase associated with the status code.
  /// The reason phrase must be set before the body is written
  /// to. Setting the reason phrase after writing to the body.
  String? statusMessage;

  /// Whether this response is a redirect.
  /// ** Attention **: Whether this field is available depends on whether the
  /// implementation of the adapter supports it or not.
  bool isRedirect;

  /// The series of redirects this connection has been through. The list will be
  /// empty if no redirects were followed. [redirects] will be updated both
  /// in the case of an automatic and a manual redirect.
  ///
  /// ** Attention **: Whether this field is available depends on whether the
  /// implementation of the adapter supports it or not.
  List<RedirectRecord> redirects;

  /// Custom fields that are constructed in the [RequestOptions].
  Map<String, dynamic> extra;

  /// Response headers.
  Headers headers;

  /// Return the final real request URI (may be redirected).
  ///
  /// Note: Whether the field is available depends on whether the adapter
  /// supports or not.
  Uri get realUri =>
      redirects.isNotEmpty ? redirects.last.location : requestOptions.uri;

  /// We are more concerned about [data] field.
  @override
  String toString() {
    if (data is Map) {
      return json.encode(data);
    }
    return data.toString();
  }
}
