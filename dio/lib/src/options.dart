import 'dart:async';

import 'package:meta/meta.dart';

import 'adapter.dart';
import 'cancel_token.dart';
import 'headers.dart';
import 'transformer.dart';
import 'utils.dart';

/// {@template dio.options.ProgressCallback}
/// The type of a progress listening callback when sending or receiving data.
///
/// [count] is the length of the bytes have been sent/received.
///
/// [total] is the content length of the response/request body.
/// 1. When sending data, [total] is the request body length.
/// 2. When receiving data, [total] will be -1 if the size of the response body,
///    typically with no `content-length` header.
/// {@endtemplate}
typedef ProgressCallback = void Function(int count, int total);

/// Indicates which transformation should be applied to the response data.
enum ResponseType {
  /// Transform the response data to JSON object only when the
  /// content-type of response is "application/json" .
  json,

  /// Get the response stream directly,
  /// the [Response.data] will be [ResponseBody].
  ///
  /// ```dart
  /// Response<ResponseBody> rs = await Dio().get<ResponseBody>(
  ///   url,
  ///   options: Options(responseType: ResponseType.stream),
  /// );
  stream,

  /// Transform the response data to an UTF-8 encoded [String].
  plain,

  /// Get the original bytes, the [Response.data] will be [List<int>].
  bytes,
}

/// {@template dio.options.ListFormat}
/// Specifies the array format (a single parameter with multiple parameter
/// or multiple parameters with the same name).
/// and the separator for array items.
/// {@endtemplate}
enum ListFormat {
  /// Comma-separated values.
  /// e.g. (foo,bar,baz)
  csv,

  /// Space-separated values.
  /// e.g. (foo bar baz)
  ssv,

  /// Tab-separated values.
  /// e.g. (foo\tbar\tbaz)
  tsv,

  /// Pipe-separated values.
  /// e.g. (foo|bar|baz)
  pipes,

  /// Multiple parameter instances rather than multiple values.
  /// e.g. (foo=value&foo=another_value)
  multi,

  /// Forward compatibility.
  /// e.g. (foo[]=value&foo[]=another_value)
  multiCompatible,
}

/// The type of a response status code validate callback.
typedef ValidateStatus = bool Function(int? status);

/// The type of a response decoding callback.
typedef ResponseDecoder = FutureOr<String?> Function(
  List<int> responseBytes,
  RequestOptions options,
  ResponseBody responseBody,
);

/// The type of a request encoding callback.
typedef RequestEncoder = FutureOr<List<int>> Function(
  String request,
  RequestOptions options,
);

/// The mixin class for options that provides common attributes.
mixin OptionsMixin {
  /// Request base url, it can be multiple forms:
  ///  - Contains sub paths, e.g. `https://pub.dev/api/`.
  ///  - Relative path on Web, e.g. `api/`.
  String get baseUrl => _baseUrl;
  late String _baseUrl;

  set baseUrl(String value) {
    if (value.isNotEmpty && !kIsWeb && Uri.parse(value).host.isEmpty) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'Must be a valid URL on platforms other than Web.',
      );
    }
    _baseUrl = value;
  }

  /// Common query parameters.
  ///
  /// List values use the default [ListFormat.multiCompatible].
  /// The value can be overridden per parameter by adding a [ListParam]
  /// object wrapping the actual List value and the desired format.
  late Map<String, dynamic /*String|Iterable<String>*/ > queryParameters;

  /// Timeout when opening a request.
  ///
  /// Throws the [DioException] with
  /// [DioExceptionType.connectionTimeout] type when time out.
  ///
  /// `null` or `Duration.zero` means no timeout limit.
  Duration? get connectTimeout => _connectTimeout;
  Duration? _connectTimeout;

  set connectTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('connectTimeout should be positive');
    }
    _connectTimeout = value;
  }
}

/// A set of base settings for each `Dio()`.
/// {@template dio.options.compose_merging}
/// [BaseOptions] and [Options] will be merged into one [RequestOptions] before
/// sending the requests. See [Options.compose].
/// {@endtemplate}
class BaseOptions extends _RequestConfig with OptionsMixin {
  BaseOptions({
    super.method,
    Duration? connectTimeout,
    super.receiveTimeout,
    super.sendTimeout,
    String baseUrl = '',
    Map<String, dynamic>? queryParameters,
    super.extra,
    super.headers,
    super.preserveHeaderCase = false,
    super.responseType = ResponseType.json,
    super.contentType,
    super.validateStatus,
    super.receiveDataWhenStatusError,
    super.followRedirects,
    super.maxRedirects,
    super.persistentConnection,
    super.requestEncoder,
    super.responseDecoder,
    super.listFormat,
  }) {
    this.baseUrl = baseUrl;
    this.queryParameters = queryParameters ?? {};
    this.connectTimeout = connectTimeout;
  }

  /// Create a [BaseOptions] from current instance with merged attributes.
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
    bool? preserveHeaderCase,
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
      preserveHeaderCase: preserveHeaderCase ?? this.preserveHeaderCase,
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

/// The configuration for a single request.
/// {@macro dio.options.compose_merging}
class Options {
  Options({
    this.method,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    this.extra,
    this.headers,
    this.preserveHeaderCase,
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
    bool? preserveHeaderCase,
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
      preserveHeaderCase: preserveHeaderCase ?? this.preserveHeaderCase,
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

  /// Merge a [BaseOptions] with the current [Options]
  /// and compose them into the [RequestOptions].
  RequestOptions compose(
    BaseOptions baseOpt,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    StackTrace? sourceStackTrace,
  }) {
    final query = <String, dynamic>{};
    query.addAll(baseOpt.queryParameters);
    if (queryParameters != null) {
      query.addAll(queryParameters);
    }

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
      preserveHeaderCase: preserveHeaderCase ?? baseOpt.preserveHeaderCase,
      sourceStackTrace: sourceStackTrace ?? StackTrace.current,
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
    requestOptions.cancelToken?.requestOptions = requestOptions;
    return requestOptions;
  }

  /// The HTTP request method.
  String? method;

  /// HTTP request headers.
  ///
  /// The keys of the header are case-insensitive,
  /// e.g.: `content-type` and `Content-Type` will be treated as the same key.
  Map<String, dynamic>? headers;

  /// Whether the case of header keys should be preserved.
  ///
  /// Defaults to false.
  ///
  /// This option WILL NOT take effect on these circumstances:
  /// - XHR ([HttpRequest]) does not support handling this explicitly.
  /// - The HTTP/2 standard only supports lowercase header keys.
  bool? preserveHeaderCase;

  /// Timeout when sending data.
  ///
  /// Throws the [DioException] with
  /// [DioExceptionType.sendTimeout] type when timed out.
  ///
  /// `null` or `Duration.zero` means no timeout limit.
  Duration? get sendTimeout => _sendTimeout;
  Duration? _sendTimeout;

  set sendTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw ArgumentError.value(value, 'sendTimeout', 'should be positive');
    }
    _sendTimeout = value;
  }

  /// Timeout when receiving data.
  ///
  /// The timeout represents:
  ///  - a timeout before the connection is established
  ///    and the first received response bytes.
  ///  - the duration during data transfer of each byte event,
  ///    rather than the total duration of the receiving.
  ///
  /// Throws the [DioException] with
  /// [DioExceptionType.receiveTimeout] type when timed out.
  ///
  /// `null` or `Duration.zero` means no timeout limit.
  Duration? get receiveTimeout => _receiveTimeout;
  Duration? _receiveTimeout;

  set receiveTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw ArgumentError.value(value, 'receiveTimeout', 'should be positive');
    }
    _receiveTimeout = value;
  }

  /// The request content-type.
  ///
  /// {@macro dio.interceptors.ImplyContentTypeInterceptor}
  String? contentType;

  /// The type of data that [Dio] handles with options.
  ///
  /// The default value is [ResponseType.json].
  /// [Dio] will parse response string to JSON object automatically
  /// when the content-type of response is [Headers.jsonContentType].
  ///
  /// See also:
  ///  - `plain` if you want to receive the data as `String`.
  ///  - `bytes` if you want to receive the data as the complete bytes.
  ///  - `stream` if you want to receive the data as streamed binary bytes.
  ResponseType? responseType;

  /// Defines whether the request is considered to be successful
  /// with the given status code.
  /// The request will be treated as succeed if the callback returns true.
  ValidateStatus? validateStatus;

  /// Whether to retrieve the data if status code indicates a failed request.
  ///
  /// Defaults to true.
  bool? receiveDataWhenStatusError;

  /// An extra map that you can retrieve in [Interceptor], [Transformer]
  /// and [Response.requestOptions].
  ///
  /// The field is designed to be non-identical with [Response.extra].
  Map<String, dynamic>? extra;

  /// See [HttpClientRequest.followRedirects].
  ///
  /// Defaults to true.
  bool? followRedirects;

  /// The maximum number of redirects when [followRedirects] is `true`.
  /// [RedirectException] will be thrown if redirects exceeded the limit.
  ///
  /// Defaults to 5.
  int? maxRedirects;

  /// See [HttpClientRequest.persistentConnection].
  ///
  /// Defaults to true.
  bool? persistentConnection;

  /// The type of a request encoding callback.
  ///
  /// Defaults to [Utf8Encoder].
  RequestEncoder? requestEncoder;

  /// The type of a response decoding callback.
  ///
  /// Defaults to [Utf8Decoder].
  ResponseDecoder? responseDecoder;

  /// Indicates the format of collection data in request query parameters and
  /// `x-www-url-encoded` body data.
  ///
  /// Defaults to [ListFormat.multi].
  ListFormat? listFormat;
}

/// The internal request option class that is the eventual result after
/// [BaseOptions] and [Options] are composed.
class RequestOptions extends _RequestConfig with OptionsMixin {
  RequestOptions({
    this.path = '',
    this.data,
    this.onReceiveProgress,
    this.onSendProgress,
    this.cancelToken,
    super.method,
    super.sendTimeout,
    super.receiveTimeout,
    Duration? connectTimeout,
    Map<String, dynamic>? queryParameters,
    String? baseUrl,
    super.extra,
    super.headers,
    super.preserveHeaderCase,
    super.responseType,
    super.contentType,
    super.validateStatus,
    super.receiveDataWhenStatusError,
    super.followRedirects,
    super.maxRedirects,
    super.persistentConnection,
    super.requestEncoder,
    super.responseDecoder,
    super.listFormat,
    bool? setRequestContentTypeWhenNoPayload,
    StackTrace? sourceStackTrace,
  }) : assert(connectTimeout == null || !connectTimeout.isNegative) {
    this.sourceStackTrace = sourceStackTrace ?? StackTrace.current;
    this.queryParameters = queryParameters ?? {};
    this.baseUrl = baseUrl ?? '';
    this.connectTimeout = connectTimeout;
  }

  /// Create a [RequestOptions] from current instance with merged attributes.
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
    bool? preserveHeaderCase,
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
      preserveHeaderCase: preserveHeaderCase ?? this.preserveHeaderCase,
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
      sourceStackTrace: sourceStackTrace,
    );

    if (contentType != null) {
      ro.headers.remove(Headers.contentTypeHeader);
      ro.contentType = contentType;
    } else if (!contentTypeInHeader) {
      ro.contentType = this.contentType;
    }

    return ro;
  }

  /// The source [StackTrace] which should always point to the invocation of
  /// [DioMixin.request] or if not provided, to the construction of the
  /// [RequestOptions] instance. In both instances the source context should
  /// still be available before it is lost due to asynchronous operations.
  @internal
  StackTrace? sourceStackTrace;

  /// Generate the requesting [Uri] from the options.
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

  /// Request data in dynamic types.
  dynamic data;

  /// Defines the path of the request. If it starts with "http(s)",
  /// [baseUrl] will be ignored. Otherwise, it will be combined and resolved
  /// with the [baseUrl].
  String path;

  /// {@macro dio.CancelToken}
  CancelToken? cancelToken;

  /// {@macro dio.options.ProgressCallback}
  ProgressCallback? onReceiveProgress;

  /// {@macro dio.options.ProgressCallback}
  ProgressCallback? onSendProgress;
}

bool _defaultValidateStatus(int? status) {
  return status != null && status >= 200 && status < 300;
}

class _RequestConfig {
  _RequestConfig({
    Duration? receiveTimeout,
    Duration? sendTimeout,
    String? method,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? headers,
    bool? preserveHeaderCase,
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
        _sendTimeout = sendTimeout,
        method = method ?? 'GET',
        preserveHeaderCase = preserveHeaderCase ?? false,
        listFormat = listFormat ?? ListFormat.multi,
        extra = extra ?? {},
        followRedirects = followRedirects ?? true,
        maxRedirects = maxRedirects ?? 5,
        persistentConnection = persistentConnection ?? true,
        receiveDataWhenStatusError = receiveDataWhenStatusError ?? true,
        validateStatus = validateStatus ?? _defaultValidateStatus,
        responseType = responseType ?? ResponseType.json {
    this.headers = headers;
    final hasContentTypeHeader =
        this.headers.containsKey(Headers.contentTypeHeader);
    if (contentType != null &&
        hasContentTypeHeader &&
        this.headers[Headers.contentTypeHeader] != contentType) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Unable to set different values for '
            '`contentType` and the content-type header.',
      );
    }
    if (!hasContentTypeHeader) {
      this.contentType = contentType;
    }
  }

  late String method;

  Map<String, dynamic> get headers => _headers;
  late Map<String, dynamic> _headers;

  set headers(Map<String, dynamic>? headers) {
    _headers = caseInsensitiveKeyMap(headers);
    if (!_headers.containsKey(Headers.contentTypeHeader) &&
        _defaultContentType != null) {
      _headers[Headers.contentTypeHeader] = _defaultContentType;
    }
  }

  late bool preserveHeaderCase;

  Duration? get sendTimeout => _sendTimeout;
  Duration? _sendTimeout;

  set sendTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('sendTimeout should be positive');
    }
    _sendTimeout = value;
  }

  Duration? get receiveTimeout => _receiveTimeout;
  Duration? _receiveTimeout;

  set receiveTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('receiveTimeout should be positive');
    }
    _receiveTimeout = value;
  }

  String? _defaultContentType;

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

  late ResponseType responseType;
  late ValidateStatus validateStatus;
  late bool receiveDataWhenStatusError;
  late Map<String, dynamic> extra;
  late bool followRedirects;
  late int maxRedirects;
  late bool persistentConnection;
  RequestEncoder? requestEncoder;
  ResponseDecoder? responseDecoder;
  late ListFormat listFormat;
}

/// {@template dio.options.FileAccessMode}
/// The file access mode when downloading a file, corresponds to a subset of
/// dart:io::[FileMode].
/// {@endtemplate}
enum FileAccessMode {
  /// Mode for opening a file for reading and writing. The file is overwritten
  /// if it already exists. The file is created if it does not already exist.
  write,

  /// Mode for opening a file for reading and writing to the end of it.
  /// The file is created if it does not already exist.
  append,
}
