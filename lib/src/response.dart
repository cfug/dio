import 'dart:convert';
import 'dart:io';
import 'options.dart';

/**
 * Response describes the http Response info.
 */
class Response<T> {
  Response({this.data, this.headers, this.request, this.statusCode = 0});

  /// Response body. may have been transformed, please refer to [ResponseType].
  T data;

  /// Response headers.
  HttpHeaders headers;

  /// The corresponding request info.
  RequestOptions request;

  /// Http status code.
  int statusCode;

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
