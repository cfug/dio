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
/// 1.When sending data:
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
  /// Response data will be a [ResponseBody] instance.
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

typedef ResponseDecoder = String? Function(
  List<int> responseBytes,
  RequestOptions options,
  ResponseBody responseBody,
);
typedef RequestEncoder = List<int> Function(
  String request,
  RequestOptions options,
);

/// The common config for the Dio instance.
/// `dio.options` is a instance of [BaseOptions]
class BaseOptions extends _RequestConfig with OptionsMixin {
  BaseOptions({
    String? method,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
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
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
  })  : assert(connectTimeout == null || !connectTimeout.isNegative),
        assert(baseUrl.isEmpty || Uri.parse(baseUrl).host.isNotEmpty),
        super(
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
          persistentConnection: persistentConnection,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
          listFormat: listFormat,
        ) {
    this.queryParameters = queryParameters ?? {};
    this.baseUrl = baseUrl;
    this.connectTimeout = connectTimeout;
  }

  /// Create a Option from current instance with merging attributes.
  BaseOptions copyWith({
    String? method,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
    String? path,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, Object?>? extra,
    Map<String, Object?>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
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
      persistentConnection: persistentConnection ?? this.persistentConnection,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
    );
  }
}

mixin OptionsMixin {
  /// Request base url, it can contain sub paths like: https://pub.dev/api/.
  late String baseUrl;

  /// Common query parameters.
  ///
  /// List values use the default [ListFormat.multiCompatible].
  ///
  /// The value can be overridden per parameter by adding a [ListParam]
  /// object wrapping the actual List value and the desired format.
  late Map<String, dynamic> queryParameters;

  /// Timeout in milliseconds for opening url.
  /// [Dio] will throw the [DioError] with [DioErrorType.connectionTimeout] type
  ///  when time out.
  Duration? get connectTimeout => _connectTimeout;

  set connectTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('connectTimeout should be positive');
    }
    _connectTimeout = value;
  }

  Duration? _connectTimeout;
}

/// Every request can pass an [Options] object which will be merged with [Dio.options]
class Options {
  Options({
    this.method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    this.extra,
    this.headers,
    this.responseType,
    this.contentType,
    this.validateStatus,
    this.receiveDataWhenStatusError,
    this.followRedirects,
    this.maxRedirects,
    this.persistentConnection,
    this.requestEncoder,
    this.responseDecoder,
    this.listFormat,
  })  : assert(receiveTimeout == null || !receiveTimeout.isNegative),
        _receiveTimeout = receiveTimeout,
        assert(sendTimeout == null || !sendTimeout.isNegative),
        _sendTimeout = sendTimeout;

  /// Create a Option from current instance with merging attributes.
  Options copyWith({
    String? method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, Object?>? extra,
    Map<String, Object?>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
  }) {
    Map<String, dynamic>? effectiveHeaders;
    if (headers == null && this.headers != null) {
      effectiveHeaders = caseInsensitiveKeyMap(this.headers!);
    }

    if (headers != null) {
      headers = caseInsensitiveKeyMap(headers);
      assert(
        !(contentType != null &&
            headers.containsKey(Headers.contentTypeHeader)),
        'You cannot set both contentType param and a content-type header',
      );
    }

    Map<String, dynamic>? effectiveExtra;
    if (extra == null && this.extra != null) {
      effectiveExtra = Map.from(this.extra!);
    }

    return Options(
      method: method ?? this.method,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? effectiveExtra,
      headers: headers ?? effectiveHeaders,
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      requestEncoder: requestEncoder ?? this.requestEncoder,
      responseDecoder: responseDecoder ?? this.responseDecoder,
      listFormat: listFormat ?? this.listFormat,
    );
  }

  RequestOptions compose(
    BaseOptions baseOpt,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final query = <String, dynamic>{};
    query.addAll(baseOpt.queryParameters);
    if (queryParameters != null) query.addAll(queryParameters);

    final headers = caseInsensitiveKeyMap(baseOpt.headers);
    if (this.headers != null) {
      headers.addAll(this.headers!);
    }
    if (this.contentType != null) {
      headers[Headers.contentTypeHeader] = this.contentType;
    }
    final String? contentType = headers[Headers.contentTypeHeader];
    final extra = Map<String, dynamic>.from(baseOpt.extra);
    if (this.extra != null) {
      extra.addAll(this.extra!);
    }
    final method = (this.method ?? baseOpt.method).toUpperCase();
    final requestOptions = RequestOptions(
      method: method,
      headers: headers,
      extra: extra,
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
      persistentConnection:
          persistentConnection ?? baseOpt.persistentConnection,
      queryParameters: query,
      requestEncoder: requestEncoder ?? baseOpt.requestEncoder,
      responseDecoder: responseDecoder ?? baseOpt.responseDecoder,
      listFormat: listFormat ?? baseOpt.listFormat,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      contentType: contentType ?? this.contentType ?? baseOpt.contentType,
    );
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
  Duration? get sendTimeout => _sendTimeout;

  set sendTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('sendTimeout should be positive');
    }
    _sendTimeout = value;
  }

  Duration? _sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///
  ///  Note: [receiveTimeout]  represents a timeout during data transfer! That is to say the
  ///  client has connected to the server, and the server starts to send data to the client.
  ///
  /// `null` meanings no timeout limit.
  Duration? get receiveTimeout => _receiveTimeout;

  set receiveTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('receiveTimeout should be positive');
    }
    _receiveTimeout = value;
  }

  Duration? _receiveTimeout;

  /// The request Content-Type.
  ///
  /// [Dio] will automatically encode the request body accordingly.
  ///
  /// {@macro dio.interceptors.ImplyContentTypeInterceptor}
  String? contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `json`, `stream`, `plain`.
  ///
  /// The default value is [ResponseType.json], [Dio] will parse response string
  /// to JSON object automatically when the content-type of response is
  /// [Headers.jsonContentType].
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `stream`.
  ///
  /// If you want to receive the response data with String, use `plain`.
  ///
  /// If you want to receive the response data with original bytes,
  /// that's to say the type of [Response.data] will be List<int>, use `bytes`
  ResponseType? responseType;

  /// [validateStatus] defines whether the request is successful for a given
  /// HTTP response status code. If [validateStatus] returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus? validateStatus;

  /// Whether receiving response data when http status code is not successful.
  /// The default value is true
  bool? receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in
  /// [Interceptor], [Transformer] and the [Response] object.
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

  /// see [HttpClientRequest.persistentConnection],
  /// The default value is true
  bool? persistentConnection;

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
    this.path = '',
    this.data,
    this.onReceiveProgress,
    this.onSendProgress,
    this.cancelToken,
    String? method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Duration? connectTimeout,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
    bool? receiveDataWhenStatusError,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? setRequestContentTypeWhenNoPayload,
  })  : assert(connectTimeout == null || !connectTimeout.isNegative),
        super(
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
          persistentConnection: persistentConnection,
          requestEncoder: requestEncoder,
          responseDecoder: responseDecoder,
          listFormat: listFormat,
        ) {
    this.queryParameters = queryParameters ?? {};
    this.baseUrl = baseUrl ?? '';
    this.connectTimeout = connectTimeout;
  }

  /// Create a Option from current instance with merging attributes.
  RequestOptions copyWith({
    String? method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Duration? connectTimeout,
    dynamic data,
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
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
    ListFormat? listFormat,
    bool? setRequestContentTypeWhenNoPayload,
  }) {
    final contentTypeInHeader = headers != null &&
        headers.keys
            .map((e) => e.toLowerCase())
            .contains(Headers.contentTypeHeader);

    assert(
      !(contentType != null && contentTypeInHeader),
      'You cannot set both contentType param and a content-type header',
    );

    final ro = RequestOptions(
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
      persistentConnection: persistentConnection ?? this.persistentConnection,
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
    String url = path;
    if (!url.startsWith(RegExp(r'https?:'))) {
      url = baseUrl + url;
      final s = url.split(':/');
      if (s.length == 2) {
        url = '${s[0]}:/${s[1].replaceAll('//', '/')}';
      }
    }
    final query = Transformer.urlEncodeQueryMap(queryParameters, listFormat);
    if (query.isNotEmpty) {
      url += (url.contains('?') ? '&' : '?') + query;
    }
    // Normalize the url.
    return Uri.parse(url).normalizePath();
  }

  /// Request data, can be any type.
  ///
  /// When using `x-www-url-encoded` body data,
  /// List values use the default [ListFormat.multi].
  ///
  /// The value can be overridden per value by adding a [ListParam]
  /// object wrapping the actual List value and the desired format.
  dynamic data;

  /// If the `path` starts with 'http(s)', the `baseURL` will be ignored,
  /// otherwise, it will be combined and then resolved with the baseUrl.
  String path;

  CancelToken? cancelToken;

  ProgressCallback? onReceiveProgress;

  ProgressCallback? onSendProgress;
}

/// The [_RequestConfig] class describes the http request information and configuration.
class _RequestConfig {
  _RequestConfig({
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? method,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    String? contentType,
    ListFormat? listFormat,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    bool? receiveDataWhenStatusError,
    ValidateStatus? validateStatus,
    ResponseType? responseType,
    this.requestEncoder,
    this.responseDecoder,
  })  : assert(receiveTimeout == null || !receiveTimeout.isNegative),
        _receiveTimeout = receiveTimeout,
        assert(sendTimeout == null || !sendTimeout.isNegative),
        _sendTimeout = sendTimeout {
    this.headers = headers;

    final contentTypeInHeader =
        this.headers.containsKey(Headers.contentTypeHeader);
    assert(
      !(contentType != null && contentTypeInHeader) ||
          this.headers[Headers.contentTypeHeader] == contentType,
      'You cannot set different values for contentType param and a content-type header',
    );

    this.method = method ?? 'GET';
    this.listFormat = listFormat ?? ListFormat.multi;
    this.extra = extra ?? {};
    this.followRedirects = followRedirects ?? true;
    this.maxRedirects = maxRedirects ?? 5;
    this.persistentConnection = persistentConnection ?? true;
    this.receiveDataWhenStatusError = receiveDataWhenStatusError ?? true;
    this.validateStatus = validateStatus ??
        (int? status) {
          return status != null && status >= 200 && status < 300;
        };
    this.responseType = responseType ?? ResponseType.json;
    if (!contentTypeInHeader) {
      this.contentType = contentType;
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
    if (!_headers.containsKey(Headers.contentTypeHeader) &&
        _defaultContentType != null) {
      _headers[Headers.contentTypeHeader] = _defaultContentType;
    }
  }

  /// Timeout in milliseconds for sending data.
  /// [Dio] will throw the [DioError] with [DioErrorType.sendTimeout] type
  ///  when time out.
  ///
  /// `null` meanings no timeout limit.
  Duration? get sendTimeout => _sendTimeout;

  set sendTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('sendTimeout should be positive');
    }
    _sendTimeout = value;
  }

  Duration? _sendTimeout;

  ///  Timeout in milliseconds for receiving data.
  ///
  ///  Note: [receiveTimeout]  represents a timeout during data transfer! That is to say the
  ///  client has connected to the server, and the server starts to send data to the client.
  ///
  /// `null` meanings no timeout limit.
  Duration? get receiveTimeout => _receiveTimeout;

  set receiveTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('receiveTimeout should be positive');
    }
    _receiveTimeout = value;
  }

  Duration? _receiveTimeout;

  /// The request Content-Type.
  ///
  /// [Dio] will automatically encode the request body accordingly.
  ///
  /// {@macro dio.interceptors.ImplyContentTypeInterceptor}
  String? get contentType => _headers[Headers.contentTypeHeader] as String?;

  set contentType(String? contentType) {
    final newContentType = contentType?.trim();
    _defaultContentType = newContentType;
    if (newContentType != null) {
      _headers[Headers.contentTypeHeader] = newContentType;
    } else {
      _headers.remove(Headers.contentTypeHeader);
    }
  }

  String? _defaultContentType;

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

  /// see [HttpClientRequest.persistentConnection],
  /// The default value is true
  late bool persistentConnection;

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
  /// The value can be overridden per parameter by adding a [ListParam]
  /// object to the query or body data map.
  late ListFormat listFormat;
}
