import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/src/adapters/download/download_adapter.dart';
import 'package:meta/meta.dart';

import 'adapters/adapter.dart';
import 'dio_exception.dart';
import 'form_data.dart';
import 'interceptors/imply_content_type.dart';
import 'options.dart';
import 'headers.dart';
import 'cancel_token.dart';
import 'progress_stream/io_progress_stream.dart';
import 'response.dart';
import 'transformer.dart';
import 'transformers/background_transformer.dart';

part 'interceptor.dart';

/// Dio enables you to make HTTP requests easily.
///
/// Creating a [Dio] instance with configurations:
/// ```dart
/// final dio = Dio(
///   BaseOptions(
///     baseUrl: "https://pub.dev",
///     connectTimeout: const Duration(seconds: 5),
///     receiveTimeout: const Duration(seconds: 5),
///     headers: {
///       HttpHeaders.userAgentHeader: 'dio',
///       'common-header': 'xx',
///     },
///   )
/// );
/// ```
///
/// The [Dio.options] can be updated in anytime:
/// ```dart
/// dio.options.baseUrl = "https://pub.dev";
/// dio.options.connectTimeout = const Duration(seconds: 5);
/// dio.options.receiveTimeout = const Duration(seconds: 5);
/// ```
class Dio {
  /// Create the default [Dio] instance with the default implementation
  /// based on different platforms.
  Dio([BaseOptions? options]) : options = options ?? BaseOptions();

  /// Default Request config. More see [BaseOptions] .
  BaseOptions options;

  /// Return the interceptors added into the instance.
  final Interceptors interceptors = Interceptors();

  /// The adapter that the instance is using.
  HttpClientAdapter httpClientAdapter = HttpClientAdapter();

  /// The download adapter that the instance is using.
  final DownloadAdapter downloadAdapter = DownloadAdapter();

  /// [Transformer] allows changes to the request/response data before it is
  /// sent/received to/from the server.
  /// This is only applicable for requests that have payload.
  Transformer transformer = BackgroundTransformer();

  bool _closed = false;

  /// Shuts down the dio client.
  ///
  /// If [force] is `false` (the default) the [Dio] will be kept alive
  /// until all active connections are done. If [force] is `true` any active
  /// connections will be closed to immediately release all resources. These
  /// closed connections will receive an error event to indicate that the client
  /// was shut down. In both cases trying to establish a new connection after
  /// calling [close] will throw an exception.
  void close({bool force = false}) {
    _closed = true;
    httpClientAdapter.close(force: force);
  }

  /// Convenience method to make an HTTP HEAD request.
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('HEAD', options),
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make an HTTP HEAD request with [Uri].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('HEAD', options),
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make an HTTP GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make an HTTP GET request with [Uri].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make an HTTP POST request.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      options: checkOptions('POST', options),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP POST request with [Uri].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('POST', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP PUT request.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('PUT', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP PUT request with [Uri].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('PUT', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('PATCH', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP PATCH request with [Uri].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('PATCH', options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Convenience method to make an HTTP DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: checkOptions('DELETE', options),
      cancelToken: cancelToken,
    );
  }

  /// Convenience method to make an HTTP DELETE request with [Uri].
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: checkOptions('DELETE', options),
      cancelToken: cancelToken,
    );
  }

  /// {@template dio.Dio.download}
  /// Download the file and save it in local. The default http method is "GET",
  /// you can custom it by [Options.method].
  ///
  /// [urlPath] is the file url.
  ///
  /// The file will be saved to the path specified by [savePath].
  /// The following two types are accepted:
  /// 1. `String`: A path, eg "xs.jpg"
  /// 2. `FutureOr<String> Function(Headers headers)`, for example:
  ///    ```dart
  ///    await dio.download(
  ///      url,
  ///      (Headers headers) {
  ///        // Extra info: redirect counts
  ///        print(headers.value('redirects'));
  ///        // Extra info: real uri
  ///        print(headers.value('uri'));
  ///        // ...
  ///        return (await getTemporaryDirectory()).path + 'file_name';
  ///      },
  ///    );
  ///    ```
  ///
  /// [onReceiveProgress] is the callback to listen downloading progress.
  /// Please refer to [ProgressCallback].
  ///
  /// [deleteOnError] whether delete the file when error occurs.
  /// The default value is [true].
  ///
  /// [lengthHeader] : The real size of original file (not compressed).
  /// When file is compressed:
  /// 1. If this value is 'content-length', the `total` argument of
  ///    [onReceiveProgress] will be -1.
  /// 2. If this value is not 'content-length', maybe a custom header indicates
  ///    the original file size, the `total` argument of [onReceiveProgress]
  ///    will be this header value.
  ///
  /// You can also disable the compression by specifying the 'accept-encoding'
  /// header value as '*' to assure the value of `total` argument of
  /// [onReceiveProgress] is not -1. For example:
  ///
  /// ```dart
  /// await dio.download(
  ///   url,
  ///   (await getTemporaryDirectory()).path + 'flutter.svg',
  ///   options: Options(
  ///     headers: {HttpHeaders.acceptEncodingHeader: '*'}, // Disable gzip
  ///   ),
  ///   onReceiveProgress: (received, total) {
  ///     if (total <= 0) return;
  ///     print('percentage: ${(received / total * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) =>
      downloadAdapter.download(
        urlPath,
        savePath,
        request: request,
        transformer: transformer,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );

  /// {@macro dio.Dio.download}
  Future<Response> downloadUri(
    Uri uri,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    return download(
      uri.toString(),
      savePath,
      onReceiveProgress: onReceiveProgress,
      lengthHeader: lengthHeader,
      deleteOnError: deleteOnError,
      cancelToken: cancelToken,
      data: data,
      options: options,
    );
  }

  /// Make HTTP request with options.
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final requestOptions = (options ?? Options()).compose(
      this.options,
      path,
      data: data,
      queryParameters: queryParameters,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      sourceStackTrace: StackTrace.current,
    );

    if (_closed) {
      throw DioException.connectionError(
        reason: "Dio can't establish a new connection after it was closed.",
        requestOptions: requestOptions,
      );
    }

    return fetch<T>(requestOptions);
  }

  /// Make http request with options with [Uri].
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    Object? data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request(
      uri.toString(),
      data: data,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// The eventual method to submit requests. All callers for requests should
  /// eventually go through this method.
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }

    // Convert the request interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr Function(dynamic) requestInterceptorWrapper(
      InterceptorSendCallback interceptor,
    ) {
      return (dynamic incomingState) async {
        final state = incomingState as InterceptorState;
        if (state.type == InterceptorResultType.next) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() {
              final requestHandler = RequestInterceptorHandler();
              interceptor(state.data as RequestOptions, requestHandler);
              return requestHandler.future;
            }),
          );
        } else {
          return state;
        }
      };
    }

    // Convert the response interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic) responseInterceptorWrapper(
      InterceptorSuccessCallback interceptor,
    ) {
      return (dynamic incomingState) async {
        final state = incomingState as InterceptorState;
        if (state.type == InterceptorResultType.next ||
            state.type == InterceptorResultType.resolveCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() {
              final responseHandler = ResponseInterceptorHandler();
              interceptor(state.data as Response, responseHandler);
              return responseHandler.future;
            }),
          );
        } else {
          return state;
        }
      };
    }

    // Convert the error interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(Object) errorInterceptorWrapper(
      InterceptorErrorCallback interceptor,
    ) {
      return (error) {
        final state = error is InterceptorState
            ? error
            : InterceptorState(assureDioException(error, requestOptions));
        Future<InterceptorState> handleError() async {
          final errorHandler = ErrorInterceptorHandler();
          interceptor(state.data, errorHandler);
          return errorHandler.future;
        }

        // The request has already been cancelled,
        // there is no need to listen for another cancellation.
        if (state.data is DioException &&
            state.data.type == DioExceptionType.cancel) {
          return handleError();
        } else if (state.type == InterceptorResultType.next ||
            state.type == InterceptorResultType.rejectCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(handleError),
          );
        } else {
          throw error;
        }
      };
    }

    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.
    Future<dynamic> future = Future<dynamic>(
      () => InterceptorState(requestOptions),
    );

    // Add request interceptors into the request flow.
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleRequest
          : interceptor.onRequest;
      future = future.then(requestInterceptorWrapper(fun));
    }

    // Add dispatching callback into the request flow.
    future = future.then(
      requestInterceptorWrapper((
        RequestOptions reqOpt,
        RequestInterceptorHandler handler,
      ) {
        requestOptions = reqOpt;
        _dispatchRequest<T>(reqOpt)
            .then((value) => handler.resolve(value, true))
            .catchError((e) {
          handler.reject(e as DioException, true);
        });
      }),
    );

    // Add response interceptors into the request flow
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleResponse
          : interceptor.onResponse;
      future = future.then(responseInterceptorWrapper(fun));
    }

    // Add error handlers into the request flow.
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleError
          : interceptor.onError;
      future = future.catchError(errorInterceptorWrapper(fun));
    }
    // Normalize errors, converts errors to [DioException].
    return future.then<Response<T>>((data) {
      return assureResponse<T>(
        data is InterceptorState ? data.data : data,
        requestOptions,
      );
    }).catchError((Object e) {
      final isState = e is InterceptorState;
      if (isState) {
        if (e.type == InterceptorResultType.resolve) {
          return assureResponse<T>(e.data, requestOptions);
        }
      }
      throw assureDioException(isState ? e.data : e, requestOptions);
    });
  }

  Future<Response<dynamic>> _dispatchRequest<T>(RequestOptions reqOpt) async {
    final cancelToken = reqOpt.cancelToken;
    try {
      final stream = await _transformData(reqOpt);
      final responseBody = await httpClientAdapter.fetch(
        reqOpt,
        stream,
        cancelToken?.whenCancel,
      );
      final headers = Headers.fromMap(
        responseBody.headers,
        preserveHeaderCase: reqOpt.preserveHeaderCase,
      );
      // Make sure headers and [ResponseBody.headers] are the same instance.
      responseBody.headers = headers.map;
      final ret = Response<dynamic>(
        data: null,
        headers: headers,
        requestOptions: reqOpt,
        redirects: responseBody.redirects ?? [],
        isRedirect: responseBody.isRedirect,
        statusCode: responseBody.statusCode,
        statusMessage: responseBody.statusMessage,
        extra: responseBody.extra,
      );
      final statusOk = reqOpt.validateStatus(responseBody.statusCode);
      if (statusOk || reqOpt.receiveDataWhenStatusError == true) {
        Object? data = await transformer.transformResponse(
          reqOpt,
          responseBody,
        );
        // Make the response as null before returned as JSON.
        if (data is String &&
            data.isEmpty &&
            T != dynamic &&
            T != String &&
            reqOpt.responseType == ResponseType.json) {
          data = null;
        }
        ret.data = data;
      } else {
        await responseBody.stream.listen(null).cancel();
      }
      checkCancelled(cancelToken);
      if (statusOk) {
        return ret;
      } else {
        throw DioException.badResponse(
          statusCode: responseBody.statusCode,
          requestOptions: reqOpt,
          response: ret,
        );
      }
    } catch (e) {
      throw assureDioException(e, reqOpt);
    }
  }

  bool _isValidToken(String token) {
    // from https://www.rfc-editor.org/rfc/rfc2616#page-15
    //
    // CTL            = <any US-ASCII control character
    //                  (octets 0 - 31) and DEL (127)>
    // separators     = "(" | ")" | "<" | ">" | "@"
    //                | "," | ";" | ":" | "\" | <">
    //                | "/" | "[" | "]" | "?" | "="
    //                | "{" | "}" | SP | HT
    // token          = 1*<any CHAR except CTLs or separators>
    const String validChars = r'                                '
        r" ! #$%&'  *+ -. 0123456789      "
        r' ABCDEFGHIJKLMNOPQRSTUVWXYZ   ^_'
        r'`abcdefghijklmnopqrstuvwxyz | ~ ';
    for (final int codeUnit in token.codeUnits) {
      if (codeUnit >= validChars.length ||
          validChars.codeUnitAt(codeUnit) == 0x20) {
        return false;
      }
    }
    return true;
  }

  Future<Stream<Uint8List>?> _transformData(RequestOptions options) async {
    if (!_isValidToken(options.method)) {
      throw ArgumentError.value(options.method, 'method');
    }
    final data = options.data;
    if (data != null) {
      final Stream<List<int>> stream;
      // Handle the FormData.
      int? length;
      if (data is Stream) {
        if (data is! Stream<List<int>>) {
          throw ArgumentError.value(
            data.runtimeType,
            'data',
            'Stream type must be `Stream<List<int>>`',
          );
        }
        stream = data;
        options.headers.keys.any((String key) {
          if (key.toLowerCase() == Headers.contentLengthHeader) {
            length = int.parse(options.headers[key].toString());
            return true;
          }
          return false;
        });
      } else if (data is FormData) {
        options.headers[Headers.contentTypeHeader] =
            '${Headers.multipartFormDataContentType}; '
            'boundary=${data.boundary}';
        stream = data.finalize();
        length = data.length;
        options.headers[Headers.contentLengthHeader] = length.toString();
      } else {
        final List<int> bytes;
        if (data is Uint8List) {
          // Handle binary data which does not need to be transformed.
          bytes = data;
        } else {
          // Call the request transformer.
          final transformed = await transformer.transformRequest(options);
          if (options.requestEncoder != null) {
            final encoded = options.requestEncoder!(transformed, options);

            if (encoded is Future) {
              bytes = await encoded;
            } else {
              bytes = encoded;
            }
          } else {
            // Converts the data to UTF-8 by default.
            bytes = utf8.encode(transformed);
          }
        }

        // Allocate send progress.
        length = bytes.length;
        options.headers[Headers.contentLengthHeader] = length.toString();

        final group = <List<int>>[];
        const size = 1024;
        final groupCount = (bytes.length / size).ceil();
        for (int i = 0; i < groupCount; ++i) {
          final start = i * size;
          group.add(bytes.sublist(start, math.min(start + size, bytes.length)));
        }
        stream = Stream.fromIterable(group);
      }
      return addProgress(stream, length, options);
    }
    return null;
  }

  // If the request has been cancelled, stop the request and throw error.
  @internal
  static void checkCancelled(CancelToken? cancelToken) {
    final error = cancelToken?.cancelError;
    if (error != null) {
      throw error;
    }
  }

  @internal
  static Future<T> listenCancelForAsyncTask<T>(
    CancelToken? cancelToken,
    Future<T> future,
  ) {
    return Future.any([
      if (cancelToken != null) cancelToken.whenCancel.then((e) => throw e),
      future,
    ]);
  }

  @internal
  static Options checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }

  @internal
  static DioException assureDioException(
    Object error,
    RequestOptions requestOptions,
  ) {
    if (error is DioException) {
      return error;
    }
    return DioException(
      requestOptions: requestOptions,
      error: error,
    );
  }

  @internal
  static Response<T> assureResponse<T>(
    Object response,
    RequestOptions requestOptions,
  ) {
    if (response is! Response) {
      return Response<T>(
        data: response as T,
        requestOptions: requestOptions,
      );
    } else if (response is! Response<T>) {
      final T data = response.data as T;
      final Headers headers;
      if (data is ResponseBody) {
        headers = Headers.fromMap(
          data.headers,
          preserveHeaderCase: requestOptions.preserveHeaderCase,
        );
      } else {
        headers = response.headers;
      }
      return Response<T>(
        data: data,
        headers: headers,
        requestOptions: response.requestOptions,
        statusCode: response.statusCode,
        isRedirect: response.isRedirect,
        redirects: response.redirects,
        statusMessage: response.statusMessage,
        extra: response.extra,
      );
    }
    return response;
  }
}
