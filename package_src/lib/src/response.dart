import 'dart:convert';
import 'dart:io';
import 'options.dart';

/// Response describes the http Response info.
class Response<T> {
  Response({
    this.data,
    this.headers,
    this.request,
    this.redirects,
    this.statusCode ,
    this.statusMessage,
    this.extra,
  });

  /// Response body. may have been transformed, please refer to [ResponseType].
  T data;

  /// Response headers.
  HttpHeaders headers;

  /// The corresponding request info.
  RequestOptions request;

  /// Http status code.
  int statusCode;

  /// Returns the reason phrase associated with the status code.
  /// The reason phrase must be set before the body is written
  /// to. Setting the reason phrase after writing to the body.
  String statusMessage;

  /// Returns the series of redirects this connection has been through. The
  /// list will be empty if no redirects were followed. [redirects] will be
  /// updated both in the case of an automatic and a manual redirect.
  List<RedirectInfo> redirects;

  /// Returns whether the status code is one of the normal redirect
  /// codes [HttpStatus.movedPermanently], [HttpStatus.found],
  /// [HttpStatus.movedTemporarily], [HttpStatus.seeOther] and
  /// [HttpStatus.temporaryRedirect].
  bool get isRedirect => redirects.isNotEmpty;

  /// Returns the final real request uri (maybe redirect).
  Uri get realUri => redirects.last?.location ?? request.uri;

  /// Custom field that you can retrieve it later in `then`.
  Map<String, dynamic> extra;

  /// We are more concerned about `data` field.
  @override
  String toString() {
    if (data is Map) {
      return json.encode(data);
    }
    return data.toString();
  }
}
