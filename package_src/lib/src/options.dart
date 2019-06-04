import 'dart:io';
import 'dio.dart';
import 'cancel_token.dart';
import 'transformer.dart';
import 'adapter.dart';

/// ResponseType indicates which transformation should
/// be automatically applied to the response data by Dio.
enum ResponseType {
  /// Transform the response data to JSON object.
  json,

  /// Get the response stream without any transformation. The
  /// Response data will be a `ResponseBody` instance.
  ///
  ///    Response<ResponseBody> rs = await Dio().get<ResponseBody>(
  ///      url,
  ///      options: Options(
  ///        responseType: ResponseType.stream,
  ///      ),
  ///    );
  stream,

  /// Transform the response data to a String encoded with UTF8.
  plain,

  /// Get original bytes, the type of [Response.data] will be List<int>
  bytes
}

typedef ValidateStatus = bool Function(int status);
typedef ResponseDecoder = String Function(
    List<int> responseBytes, RequestOptions options, ResponseBody responseBody);
typedef RequestEncoder = List<int> Function(
    String request, RequestOptions options);

/// The common config for the Dio instance.
/// `dio.options` is a instance of [BaseOptions]
class BaseOptions extends _RequestConfig {
  BaseOptions({
    String method,
    int connectTimeout,
    int receiveTimeout,
    Iterable<Cookie> cookies,
    this.baseUrl,
    this.queryParameters,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType = ResponseType.json,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError = true,
    bool followRedirects = true,
    int maxRedirects = 5,
   RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          cookies: cookies,
          maxRedirects: maxRedirects,
          requestEncoder:requestEncoder,
          responseDecoder: responseDecoder,
        );

  /// Create a new Option from current instance with merging attributes.
  BaseOptions merge({
    String method,
    String baseUrl,
    Map<String, dynamic> queryParameters,
    String path,
    int connectTimeout,
    int receiveTimeout,
    dynamic data,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder  requestEncoder,
    ResponseDecoder responseDecoder,
  }) {
    return new BaseOptions(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? new Map.from(this.extra ?? {}),
      headers: headers ?? new Map.from(this.headers ?? {}),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
    );
  }

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// Common query parameters
  Map<String, dynamic> queryParameters;
}

/// Every request can pass an [Options] object which will be merged with [Dio.options]
class Options extends _RequestConfig {
  Options({
    String method,
    int connectTimeout,
    int sendTimeout,
    int receiveTimeout,
    Iterable<Cookie> cookies,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder  requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          connectTimeout: connectTimeout,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          cookies: cookies,
          maxRedirects: maxRedirects,
          requestEncoder:requestEncoder,
          responseDecoder: responseDecoder,
        );

  /// Create a new Option from current instance with merging attributes.
  Options merge({
    String method,
    int connectTimeout,
    int receiveTimeout,
    dynamic data,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    Iterable<Cookie> cookies,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder  requestEncoder,
    ResponseDecoder responseDecoder,
  }) {
    return new Options(
      method: method ?? this.method,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? new Map.from(this.extra ?? {}),
      headers: headers ?? new Map.from(this.headers ?? {}),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      cookies: cookies ?? this.cookies ?? [],
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
    );
  }
}

class RequestOptions extends Options {
  RequestOptions({
    String method,
    int connectTimeout,
    int sendTimeout,
    int receiveTimeout,
    Iterable<Cookie> cookies,
    this.data,
    this.path,
    this.queryParameters,
    this.baseUrl,
    this.onReceiveProgress,
    this.cancelToken,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError = true,
    bool followRedirects = true,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          connectTimeout: connectTimeout,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
          cookies: cookies,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
        );

  /// generate uri
  Uri get uri {
    String _url = path;
    if (!_url.startsWith(new RegExp(r"https?:"))) {
      _url = baseUrl + _url;
      List<String> s = _url.split(":/");
      _url = s[0] + ':/' + s[1].replaceAll("//", "/");
    }
    String query = Transformer.urlEncodeMap(queryParameters);
    if (query.isNotEmpty) {
      _url += (_url.contains("?") ? "&" : "?") + query;
    }
    // Normalize the url.
    return Uri.parse(_url).normalizePath();
  }

  /// Request data, can be any type.
  dynamic data;

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// If the `path` starts with "http(s)", the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = "";

  /// See [Uri.queryParameters]
  Map<String, dynamic> queryParameters;

  CancelToken cancelToken;

  ProgressCallback onReceiveProgress;

  ProgressCallback onSendProgress;
}

/// The [_RequestConfig] class describes the http request information and configuration.
class _RequestConfig {
  _RequestConfig({
    this.method,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    this.responseType,
    this.contentType,
    this.validateStatus,
    this.cookies,
    this.receiveDataWhenStatusError = true,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.requestEncoder,
    this.responseDecoder,
  })  : this.headers = headers ?? {},
        this.extra = extra ?? {};

  /// Http method.
  String method;

  /// Http request headers.
  Map<String, dynamic> headers;

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioError] with [DioErrorType.CONNECT_TIMEOUT] type
  ///  when time out.
  int connectTimeout;

  /// Timeout in milliseconds for sending data.
  /// [Dio] will throw the [DioError] with [DioErrorType.SEND_TIMEOUT] type
  ///  when time out.
  int sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT] type
  ///  when time out.
  int receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with "application/x-www-form-urlencoded",
  /// you can set `ContentType.parse("application/x-www-form-urlencoded")`, and [Dio]
  /// will automatically encode the request body.
  ContentType contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `json`, `stream`, `plain`.
  ///
  /// The default value is `json`, dio will parse response string to json object automatically
  /// when the content-type of response is "application/json".
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `stream`.
  ///
  /// If you want to receive the response data with String, use `plain`.
  ///
  /// If you want to receive the response data with  original bytes,
  /// that's to say the type of [Response.data] will be List<int>, use `bytes`
  ResponseType responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus validateStatus;

  /// Whether receiving response data when http status code is not successful.
  bool receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the [Response] object.
  Map<String, dynamic> extra;

  /// see [HttpClientRequest.followRedirects]
  bool followRedirects;

  /// Set this property to the maximum number of redirects to follow
  /// when [followRedirects] is `true`. If this number is exceeded
  /// an error event will be added with a [RedirectException].
  ///
  /// The default value is 5.
  int maxRedirects;

  /// Custom Cookies for every request
  List<Cookie> cookies;

  /// The default request encoder is utf8encoder, you can set custom
  /// encoder by this option.
  RequestEncoder requestEncoder;

  /// The default response decoder is utf8decoder, you can set custom
  /// decoder by this option, it will be used in [Transformer].
  ResponseDecoder responseDecoder;
}
