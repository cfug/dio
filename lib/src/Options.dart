import 'dart:io';
import 'package:dio/src/Dio.dart';

/// ResponseType indicates which transformation should
/// be automatically applied to the response data by Dio.
enum ResponseType {
  /// Transform the response data to JSON object.
  JSON,

  /// Get the response stream without any transformation.
  STREAM,

  /// Transform the response data to a String encoded with UTF8.
  PLAIN
}

/**
 * The Options class describes the http request information and configuration.
 */
class Options{
  Options({this.method,
    this.baseUrl,
    this.connectTimeout,
    this.receiveTimeout,
    this.data,
    this.extra,
    this.headers,
    this.responseType,
    this.contentType}) {
    // set the default user-agent with Dio version
    this.headers = headers ?? {};
    this.contentType;
    this.extra = extra ?? {};
  }

  /// Http method.
  String method;

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// Http request headers.
  Map<String, dynamic> headers;

  /// Timeout in milliseconds for opening  url.
  int connectTimeout;

  ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT].
  ///
  ///  Note: This is not the receiving time limitation.
  int receiveTimeout;

  /// Request data, can be any type.
  var data;

  /// If the `path` starts with "http(s)", the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = "";

  /// The request Content-Type. The default value is [ContentType.JSON].
  /// If you want to encode request body with "application/x-www-form-urlencoded",
  /// you can set `ContentType.parse("application/x-www-form-urlencoded")`, and [Dio]
  /// will automatically encode the request body.
  ContentType contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `JSON`, `STREAM`, `PLAIN`.
  ///
  /// The default value is `JSON`, dio will parse response string to json object automatically
  /// when the content-type of response is "application/json".
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `STREAM`.
  ///
  /// If you want to receive the response data with String, use `PLAIN`.
  ResponseType responseType;

  /// Custom field that you can retrieve it later in [Interceptor]、[TransFormer] and the [Response] object.
  Map<String, dynamic> extra;
}