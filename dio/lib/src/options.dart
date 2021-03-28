import 'adapter.dart';
import 'cancel_token.dart';
import 'headers.dart';
import 'transformer.dart';
import 'utils.dart';

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

/// ListFormat specifies the array format
/// (a single parameter with multiple parameter or multiple parameters with the same name)
/// and the separator for array items.
enum ListFormat {
  /// Comma-separated values
  /// e.g. (foo,bar,baz)
  csv,

  /// Space-separated values
  /// e.g. (foo bar baz)
  ssv,

  /// Tab-separated values
  /// e.g. (foo\tbar\tbaz)
  tsv,

  /// Pipe-separated values
  /// e.g. (foo|bar|baz)
  pipes,

  /// Multiple parameter instances rather than multiple values.
  /// e.g. (foo=value&foo=another_value)
  multi,

  /// Forward compatibility
  /// e.g. (foo[]=value&foo[]=another_value)
  multiCompatible,
}

typedef ValidateStatus = bool Function(int? status);

typedef ResponseDecoder = String Function(
    List<int> responseBytes, RequestOptions options, ResponseBody responseBody);
typedef RequestEncoder = List<int> Function(
    String request, RequestOptions options);

/// The common config for the Dio instance.
/// `dio.options` is a instance of [BaseOptions]
class BaseOptions extends _RequestConfig with OptionsMixin {
  BaseOptions({
    String? method,
    int? connectTimeout,
    int? receiveTimeout,
    int? sendTimeout,
    String baseUrl = '',
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType = ResponseType.json,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    this.setRequestContentTypeWhenNoPayload = false,
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
          listFormat: listFormat,
        ) {
    this.queryParameters = queryParameters ?? {};
    this.baseUrl = baseUrl;
    this.connectTimeout = connectTimeout ?? 0;
  }

  /// Create a Option from current instance with merging attributes.
  BaseOptions copyWith({
    String? method,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
    String? path,
    int? connectTimeout,
    int? receiveTimeout,
    int? sendTimeout,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? setRequestContentTypeWhenNoPayload,
  }) {
    return BaseOptions(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      extra: extra ?? Map.from(this.extra),
      headers: headers ?? Map.from(this.headers),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
      setRequestContentTypeWhenNoPayload: setRequestContentTypeWhenNoPayload ??
          this.setRequestContentTypeWhenNoPayload,
    );
  }

  static const _allowPayloadMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];

  /// if false, content-type in request header will be deleted when method is not on of `_allowPayloadMethods`
  bool setRequestContentTypeWhenNoPayload;

  String? contentTypeWithRequestBody(String method) {
    if (setRequestContentTypeWhenNoPayload) {
      return contentType;
    } else {
      return _allowPayloadMethods.contains(method) ? contentType : null;
    }
  }
}

mixin OptionsMixin {
  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  late String baseUrl;

  /// Common query parameters.
  ///
  /// List values use the default [ListFormat.multiCompatible].
  ///
  /// The value can be overridden per parameter by adding a [MultiParam]
  /// object wrapping the actual List value and the desired format.
  late Map<String, dynamic> queryParameters;

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioError] with [DioErrorType.connectTimeout] type
  ///  when time out.
  late int connectTimeout;
}

/// Every request can pass an [Options] object which will be merged with [Dio.options]
class Options {
  Options({
    this.method,
    this.sendTimeout,
    this.receiveTimeout,
    this.extra,
    this.headers,
    this.responseType,
    this.contentType,
    this.validateStatus,
    this.receiveDataWhenStatusError,
    this.followRedirects,
    this.maxRedirects,
    this.requestEncoder,
    this.responseDecoder,
    this.listFormat,
  });

  /// Create a Option from current instance with merging attributes.
  Options copyWith({
    String? method,
    int? sendTimeout,
    int? receiveTimeout,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
  }) {
    Map<String, dynamic>? _headers;
    if (headers == null && this.headers != null) {
      _headers = caseInsensitiveKeyMap(this.headers!);
    }

    if (headers != null) {
      headers = caseInsensitiveKeyMap(headers);
      assert(
        !(contentType != null &&
            headers.containsKey(Headers.contentTypeHeader)),
        'You cannot set both contentType param and a content-type header',
      );
    }

    Map<String, dynamic>? _extra;
    if (extra == null && this.extra != null) {
      _extra = Map.from(this.extra!);
    }

    return Options(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? _extra,
      headers: headers ?? _headers,
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
    );
  }

  RequestOptions compose(
    BaseOptions baseOpt,
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    var query = <String, dynamic>{};
    if (queryParameters != null) query.addAll(queryParameters);
    query.addAll(baseOpt.queryParameters);

    var _headers = caseInsensitiveKeyMap(baseOpt.headers);
    _headers.remove(Headers.contentTypeHeader);

    var _contentType;

    if (headers != null) {
      _headers.addAll(headers!);
      _contentType = _headers[Headers.contentTypeHeader];
    }

    var _extra = Map<String, dynamic>.from(baseOpt.extra);
    if (extra != null) {
      _extra.addAll(extra!);
    }
    var _method = (method ?? baseOpt.method).toUpperCase();
    var requestOptions = RequestOptions(
      method: _method,
      headers: _headers,
      extra: _extra,
      baseUrl: baseOpt.baseUrl,
      path: path,
      data: data,
      connectTimeout: baseOpt.connectTimeout,
      sendTimeout: sendTimeout ?? baseOpt.sendTimeout,
      receiveTimeout: receiveTimeout ?? baseOpt.receiveTimeout,
      responseType: responseType ?? baseOpt.responseType,
      validateStatus: validateStatus ?? baseOpt.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? baseOpt.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? baseOpt.followRedirects,
      maxRedirects: maxRedirects ?? baseOpt.maxRedirects,
      queryParameters: query,
      requestEncoder: requestEncoder ?? baseOpt.requestEncoder,
      responseDecoder: responseDecoder ?? baseOpt.responseDecoder,
      listFormat: listFormat ?? baseOpt.listFormat,
    );

    requestOptions.onReceiveProgress = onReceiveProgress;
    requestOptions.onSendProgress = onSendProgress;
    requestOptions.cancelToken = cancelToken;

    requestOptions.contentType = _contentType ??
        contentType ??
        baseOpt.contentTypeWithRequestBody(_method);
    return requestOptions;
  }

  /// Http method.
  String? method;

  /// Http request headers. The keys of initial headers will be converted to lowercase,
  /// for example 'Content-Type' will be converted to 'content-type'.
  ///
  /// The key of Header Map is case-insensitive, eg: content-type and Content-Type are
  /// regard as the same key.
  Map<String, dynamic>? headers;

  /// Timeout in milliseconds for sending data.
  /// [Dio] will throw the [DioError] with [DioErrorType.sendTimeout] type
  ///  when time out.
  int? sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///  [Dio] will throw the [DioError] with [DioErrorType.receiveTimeout] type
  ///  when time out.
  ///
  /// [0] meanings no timeout limit.
  int? receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with 'application/x-www-form-urlencoded',
  /// you can set `ContentType.parse('application/x-www-form-urlencoded')`, and [Dio]
  /// will automatically encode the request body.
  String? contentType;

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
  ResponseType? responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus? validateStatus;

  /// Whether receiving response data when http status code is not successful.
  /// The default value is true
  bool? receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the [Response] object.
  Map<String, dynamic>? extra;

  /// see [HttpClientRequest.followRedirects],
  /// The default value is true
  bool? followRedirects;

  /// Set this property to the maximum number of redirects to follow
  /// when [followRedirects] is `true`. If this number is exceeded
  /// an error event will be added with a [RedirectException].
  ///
  /// The default value is 5.
  int? maxRedirects;

  /// The default request encoder is utf8encoder, you can set custom
  /// encoder by this option.
  RequestEncoder? requestEncoder;

  /// The default response decoder is utf8decoder, you can set custom
  /// decoder by this option, it will be used in [Transformer].
  ResponseDecoder? responseDecoder;

  /// The [listFormat] indicates the format of collection data in request
  /// query parameters and `x-www-url-encoded` body data.
  /// Possible values defined in [ListFormat] are `csv`, `ssv`, `tsv`, `pipes`, `multi`, `multiCompatible`.
  /// The default value is `multi`.
  ListFormat? listFormat;
}

class RequestOptions extends _RequestConfig with OptionsMixin {
  RequestOptions({
    String? method,
    int? sendTimeout,
    int? receiveTimeout,
    int? connectTimeout,
    this.data,
    required this.path,
    Map<String, dynamic>? queryParameters,
    this.onReceiveProgress,
    this.onSendProgress,
    this.cancelToken,
    String? baseUrl,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? setRequestContentTypeWhenNoPayload,
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
          listFormat: listFormat,
        ) {
    this.queryParameters = queryParameters ?? {};
    this.baseUrl = baseUrl ?? '';
    this.connectTimeout = connectTimeout ?? 0;
  }

  /// Create a Option from current instance with merging attributes.
  RequestOptions copyWith({
    String? method,
    int? sendTimeout,
    int? receiveTimeout,
    int? connectTimeout,
    String? data,
    String? path,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
    ProgressCallback? onReceiveProgress,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? setRequestContentTypeWhenNoPayload,
  }) {
    var contentTypeInHeader = headers != null &&
        headers.keys
            .map((e) => e.toLowerCase())
            .contains(Headers.contentTypeHeader);

    assert(
      !(contentType != null && contentTypeInHeader),
      'You cannot set both contentType param and a content-type header',
    );

    var ro = RequestOptions(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      data: data ?? this.data,
      path: path ?? this.path,
      baseUrl: baseUrl ?? this.baseUrl,
      queryParameters: queryParameters ?? Map.from(this.queryParameters),
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      cancelToken: cancelToken ?? this.cancelToken,
      extra: extra ?? Map.from(this.extra),
      headers: headers ?? Map.from(this.headers),
      responseType: responseType ?? this.responseType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
    );

    if (contentType != null) {
      ro.headers.remove(Headers.contentTypeHeader);
      ro.contentType = contentType;
    } else if (!contentTypeInHeader) {
      ro.contentType = this.contentType;
    }

    return ro;
  }

  /// generate uri
  Uri get uri {
    var _url = path;
    if (!_url.startsWith(RegExp(r'https?:'))) {
      _url = baseUrl + _url;
      var s = _url.split(':/');
      _url = s[0] + ':/' + s[1].replaceAll('//', '/');
    }
    var query = Transformer.urlEncodeMap(queryParameters, listFormat);
    if (query.isNotEmpty) {
      _url += (_url.contains('?') ? '&' : '?') + query;
    }
    // Normalize the url.
    return Uri.parse(_url).normalizePath();
  }

  /// Request data, can be any type.
  ///
  /// When using `x-www-url-encoded` body data,
  /// List values use the default [ListFormat.multi].
  ///
  /// The value can be overridden per value by adding a [MultiParam]
  /// object wrapping the actual List value and the desired format.
  dynamic? data;

  /// If the `path` starts with 'http(s)', the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path;

  CancelToken? cancelToken;

  ProgressCallback? onReceiveProgress;

  ProgressCallback? onSendProgress;
}

/// The [_RequestConfig] class describes the http request information and configuration.
class _RequestConfig {
  _RequestConfig({
    int? receiveTimeout,
    int? sendTimeout,
    String? method,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    String? contentType,
    ListFormat? listFormat,
    bool? followRedirects,
    int? maxRedirects,
    bool? receiveDataWhenStatusError,
    ValidateStatus? validateStatus,
    ResponseType? responseType,
    this.requestEncoder,
    this.responseDecoder,
  }) {
    this.headers = headers;

    var contentTypeInHeader =
        this.headers.containsKey(Headers.contentTypeHeader);
    assert(
      !(contentType != null && contentTypeInHeader),
      'You cannot set both contentType param and a content-type header',
    );

    this.method = method ?? 'GET';
    this.sendTimeout = sendTimeout ?? 0;
    this.receiveTimeout = receiveTimeout ?? 0;
    this.listFormat = listFormat ?? ListFormat.multi;
    this.extra = extra ?? {};
    this.followRedirects = followRedirects ?? true;
    this.maxRedirects = maxRedirects ?? 5;
    this.receiveDataWhenStatusError = receiveDataWhenStatusError ?? true;
    this.validateStatus = validateStatus ??
        (int? status) {
          return status != null && status >= 200 && status < 300;
        };
    this.responseType = responseType ?? ResponseType.json;
    if (!contentTypeInHeader) {
      this.contentType = contentType ?? Headers.jsonContentType;
    }
  }

  /// Http method.
  late String method;

  /// Http request headers. The keys of initial headers will be converted to lowercase,
  /// for example 'Content-Type' will be converted to 'content-type'.
  ///
  /// The key of Header Map is case-insensitive, eg: content-type and Content-Type are
  /// regard as the same key.

  Map<String, dynamic> get headers => _headers;
  late Map<String, dynamic> _headers;

  set headers(Map<String, dynamic>? headers) {
    _headers = caseInsensitiveKeyMap(headers);
    if (_defaultContentType != null &&
        !_headers.containsKey(Headers.contentTypeHeader)) {
      _headers[Headers.contentTypeHeader] = _defaultContentType;
    }
  }

  /// Timeout in milliseconds for sending data.
  /// [Dio] will throw the [DioError] with [DioErrorType.sendTimeout] type
  ///  when time out.
  late int sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///  [Dio] will throw the [DioError] with [DioErrorType.receiveTimeout] type
  ///  when time out.
  ///
  /// [0] meanings no timeout limit.
  late int receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with 'application/x-www-form-urlencoded',
  /// you can set `ContentType.parse('application/x-www-form-urlencoded')`, and [Dio]
  /// will automatically encode the request body.
  set contentType(String? contentType) {
    if (contentType != null) {
      _headers[Headers.contentTypeHeader] =
          _defaultContentType = contentType.trim();
    } else {
      _defaultContentType = null;
      _headers.remove(Headers.contentTypeHeader);
    }
  }

  String? _defaultContentType;

  String? get contentType => _headers[Headers.contentTypeHeader];

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
  late ResponseType responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  late ValidateStatus validateStatus;

  /// Whether receiving response data when http status code is not successful.
  /// The default value is true
  late bool receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the [Response] object.
  late Map<String, dynamic> extra;

  /// see [HttpClientRequest.followRedirects],
  /// The default value is true
  late bool followRedirects;

  /// Set this property to the maximum number of redirects to follow
  /// when [followRedirects] is `true`. If this number is exceeded
  /// an error event will be added with a [RedirectException].
  ///
  /// The default value is 5.
  late int maxRedirects;

  /// The default request encoder is utf8encoder, you can set custom
  /// encoder by this option.
  RequestEncoder? requestEncoder;

  /// The default response decoder is utf8decoder, you can set custom
  /// decoder by this option, it will be used in [Transformer].
  ResponseDecoder? responseDecoder;

  /// The [listFormat] indicates the format of collection data in request
  /// query parameters and `x-www-url-encoded` body data.
  /// Possible values defined in [ListFormat] are `csv`, `ssv`, `tsv`, `pipes`, `multi`, `multiCompatible`.
  /// The default value is `multi`.
  ///
  /// The value can be overridden per parameter by adding a [MultiParam]
  /// object to the query or body data map.
  late ListFormat listFormat;
}
