import 'adapter.dart';
import 'headers.dart';
import 'transformer.dart';
import 'cancel_token.dart';

/// Callback to listen the progress for sending/receiving data.
///
/// [count] is the length of the bytes have been sent/received.
///
/// [total] is the content length of the response/request body.
/// 1.When receiving data:
///   [total] is the request body length.
/// 2.When receiving data:
///   [total] will be -1 if the size of the response body is not known in advance,
///   for example: response data is compressed with gzip or no content-length header.
typedef ProgressCallback = void Function(int count, int total);

/// ResponseType indicates which transformation should
/// be automatically applied to the response data by Dio.
enum ResponseType {
  /// Transform the response data to JSON object only when the
  /// content-type of response is "application/json" .
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
    this.connectTimeout,
    int receiveTimeout,
    int sendTimeout,
    this.baseUrl,
    this.queryParameters,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType = ResponseType.json,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError = true,
    bool followRedirects = true,
    int maxRedirects = 5,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          receiveTimeout: receiveTimeout,
          sendTimeout: sendTimeout,
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

  /// Create a Option from current instance with merging attributes.
  BaseOptions merge({
    String method,
    String baseUrl,
    Map<String, dynamic> queryParameters,
    String path,
    int connectTimeout,
    int receiveTimeout,
    int sendTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) {
    return BaseOptions(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      extra: extra ?? Map.from(this.extra ?? {}),
      headers: headers ?? Map.from(this.headers ?? {}),
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

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioError] with [DioErrorType.CONNECT_TIMEOUT] type
  ///  when time out.
  int connectTimeout;
}

/// Every request can pass an [Options] object which will be merged with [Dio.options]
class Options extends _RequestConfig {
 Options({
    String method,
    int sendTimeout,
    int receiveTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
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

  /// Create a Option from current instance with merging attributes.
  Options merge({
    String method,
    int sendTimeout,
    int receiveTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) {
    return Options(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? Map.from(this.extra ?? {}),
      headers: headers ?? Map.from(this.headers ?? {}),
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
}

class RequestOptions extends Options {
  RequestOptions({
    String method,
    int sendTimeout,
    int receiveTimeout,
    this.connectTimeout,
    this.data,
    this.path,
    this.queryParameters,
    this.baseUrl,
    this.onReceiveProgress,
    this.onSendProgress,
    this.cancelToken,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) : super(
          method: method,
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
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

  /// Create a Option from current instance with merging attributes.
  @override
  RequestOptions merge({
    String method,
    int sendTimeout,
    int receiveTimeout,
    int connectTimeout,
    String data,
    String path,
    Map<String, dynamic> queryParameters,
    String baseUrl,
    ProgressCallback onReceiveProgress,
    ProgressCallback onSendProgress,
    CancelToken cancelToken,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    String contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
    int maxRedirects,
    RequestEncoder requestEncoder,
    ResponseDecoder responseDecoder,
  }) {
    return RequestOptions(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      data: data ?? this.data,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      baseUrl: baseUrl ?? this.baseUrl,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      cancelToken: cancelToken ?? this.cancelToken,
      extra: extra ?? Map.from(this.extra ?? {}),
      headers: headers ?? Map.from(this.headers ?? {}),
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

  /// generate uri
  Uri get uri {
    var _url = path;
    if (!_url.startsWith(RegExp(r'https?:'))) {
      _url = baseUrl + _url;
      var s = _url.split(':/');
      _url = s[0] + ':/' + s[1].replaceAll('//', '/');
    }
    var query = Transformer.urlEncodeMap(queryParameters);
    if (query.isNotEmpty) {
      _url += (_url.contains('?') ? '&' : '?') + query;
    }
    // Normalize the url.
    return Uri.parse(_url).normalizePath();
  }

  /// Request data, can be any type.
  dynamic data;

  /// Request base url, it can contain sub path, like: 'https://www.google.com/api/'.
  String baseUrl;

  /// If the `path` starts with 'http(s)', the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = '';

  /// See [Uri.queryParameters]
  Map<String, dynamic> queryParameters;

  CancelToken cancelToken;

  ProgressCallback onReceiveProgress;

  ProgressCallback onSendProgress;

  int connectTimeout;
}

/// The [_RequestConfig] class describes the http request information and configuration.
class _RequestConfig {
  _RequestConfig({
    this.method,
    this.receiveTimeout,
    this.sendTimeout,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    String contentType,
    this.responseType,
    this.validateStatus,
    this.receiveDataWhenStatusError = true,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.requestEncoder,
    this.responseDecoder,
  }) {
    this.headers = headers ?? {};
    this.extra = extra ?? {};
    this.contentType = contentType;
  }

  /// Http method.
  String method;

  /// Http request headers. The keys of initial headers will be converted to lowercase,
  /// for example 'Content-Type' will be converted to 'content-type'.
  ///
  /// You should use lowercase as the key name when you need to set the request header.
  Map<String, dynamic> headers;

  /// Timeout in milliseconds for sending data.
  /// [Dio] will throw the [DioError] with [DioErrorType.SEND_TIMEOUT] type
  ///  when time out.
  int sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT] type
  ///  when time out.
  ///
  /// [0] meanings no timeout limit.
  int receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with 'application/x-www-form-urlencoded',
  /// you can set `ContentType.parse('application/x-www-form-urlencoded')`, and [Dio]
  /// will automatically encode the request body.
  set contentType(String contentType) {
    headers[Headers.contentTypeHeader] = contentType?.trim();
  }

  String get contentType => headers[Headers.contentTypeHeader];

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `json`, `stream`, `plain`.
  ///
  /// The default value is `json`, dio will parse response string to json object automatically
  /// when the content-type of response is 'application/json'.
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

  /// The default request encoder is utf8encoder, you can set custom
  /// encoder by this option.
  RequestEncoder requestEncoder;

  /// The default response decoder is utf8decoder, you can set custom
  /// decoder by this option, it will be used in [Transformer].
  ResponseDecoder responseDecoder;
}
