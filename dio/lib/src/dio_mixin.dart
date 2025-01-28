import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import 'adapter.dart';
import 'cancel_token.dart';
import 'dio.dart';
import 'dio_exception.dart';
import 'form_data.dart';
import 'headers.dart';
import 'interceptors/imply_content_type.dart';
import 'options.dart';
import 'progress_stream/io_progress_stream.dart'
    if (dart.library.js_interop) 'progress_stream/browser_progress_stream.dart'
    if (dart.library.html) 'progress_stream/browser_progress_stream.dart';
import 'response.dart';
import 'response/response_stream_handler.dart';
import 'transformer.dart';

part 'interceptor.dart';

// TODO(EVERYONE): Use `mixin class` when the lower bound of SDK is raised to 3.0.0.
abstract class DioMixin implements Dio {
  /// The base request config for the instance.
  @override
  late BaseOptions options;

  /// Each Dio instance has a interceptor group by which you can
  /// intercept requests or responses before they are ended.
  @override
  Interceptors get interceptors => _interceptors;
  final Interceptors _interceptors = Interceptors();

  @override
  late HttpClientAdapter httpClientAdapter;

  /// The default [Transformer] that transfers requests and responses
  /// into corresponding content to send.
  /// For response bodies greater than 50KB, a new Isolate will be spawned to
  /// decode the response body to JSON.
  /// Taken from https://github.com/flutter/flutter/blob/135454af32477f815a7525073027a3ff9eff1bfd/packages/flutter/lib/src/services/asset_bundle.dart#L87-L93
  /// 50 KB of data should take 2-3 ms to parse on a Moto G4, and about 400 μs
  /// on a Pixel 4.
  @override
  Transformer transformer = FusedTransformer(
    contentLengthIsolateThreshold: 50 * 1024,
  );

  bool _closed = false;

  @override
  void close({bool force = false}) {
    _closed = true;
    httpClientAdapter.close(force: force);
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<Response> downloadUri(
    Uri uri,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
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
      fileAccessMode: fileAccessMode,
      options: options,
    );
  }

  @override
  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    FileAccessMode fileAccessMode = FileAccessMode.write,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) {
    throw UnimplementedError();
  }

  @override
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

  @override
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (cancelToken != null && cancelToken.isCancelled) {
      throw cancelToken.cancelError!;
    }

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

  @override
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
      InterceptorSendCallback cb,
    ) {
      return (dynamic incomingState) {
        final state = incomingState as InterceptorState;
        if (state.type == InterceptorResultType.next) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() async {
              final handler = RequestInterceptorHandler();
              cb(state.data as RequestOptions, handler);
              return handler.future;
            }),
          );
        }
        return state;
      };
    }

    // Convert the response interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic) responseInterceptorWrapper(
      InterceptorSuccessCallback cb,
    ) {
      return (dynamic incomingState) {
        final state = incomingState as InterceptorState;
        if (state.type == InterceptorResultType.next ||
            state.type == InterceptorResultType.resolveCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() async {
              final handler = ResponseInterceptorHandler();
              cb(state.data as Response, handler);
              return handler.future;
            }),
          );
        }
        return state;
      };
    }

    // Convert the error interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(Object) errorInterceptorWrapper(
      InterceptorErrorCallback cb,
    ) {
      return (dynamic error) {
        final state = error is InterceptorState
            ? error
            : InterceptorState(assureDioException(error, requestOptions));
        Future<InterceptorState> handleError() async {
          final handler = ErrorInterceptorHandler();
          cb(state.data, handler);
          return handler.future;
        }

        // The request has already been cancelled,
        // there is no need to listen for another cancellation.
        if (state.data is DioException &&
            state.data.type == DioExceptionType.cancel) {
          return handleError();
        }
        if (state.type == InterceptorResultType.next ||
            state.type == InterceptorResultType.rejectCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(handleError),
          );
        }
        throw error;
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
      ) async {
        requestOptions = reqOpt;
        try {
          final value = await _dispatchRequest<T>(reqOpt);
          handler.resolve(value, true);
        } on DioException catch (e) {
          handler.reject(e, true);
        }
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
    try {
      final data = await future;
      return assureResponse<T>(
        data is InterceptorState ? data.data : data,
        requestOptions,
      );
    } catch (e) {
      final isState = e is InterceptorState;
      if (isState) {
        if (e.type == InterceptorResultType.resolve) {
          return assureResponse<T>(e.data, requestOptions);
        }
      }
      throw assureDioException(isState ? e.data : e, requestOptions);
    }
  }

  Future<Response<dynamic>> _dispatchRequest<T>(RequestOptions reqOpt) async {
    final cancelToken = reqOpt.cancelToken;
    try {
      final stream = await _transformData(reqOpt);
      final operation = CancelableOperation.fromFuture(
        httpClientAdapter.fetch(
          reqOpt,
          stream,
          cancelToken?.whenCancel,
        ),
      );
      final operationWeakReference = WeakReference(operation);
      cancelToken?.whenCancel.whenComplete(() {
        operationWeakReference.target?.cancel();
      });
      final responseBody = await operation.value;
      final headers = Headers.fromMap(
        responseBody.headers,
        preserveHeaderCase: reqOpt.preserveHeaderCase,
      );
      // Make sure headers and [ResponseBody.headers] are the same instance.
      responseBody.headers = headers.map;
      final ret = Response<dynamic>(
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
        responseBody.stream = handleResponseStream(reqOpt, responseBody);

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
        responseBody.close();
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
    _checkNotNullable(token, 'token');
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
    if (cancelToken == null) {
      return future;
    }
    return Future.any([future, cancelToken.whenCancel.then((e) => throw e)]);
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
      final T? data = response.data as T?;
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

  @override
  Dio clone({
    BaseOptions? options,
    Interceptors? interceptors,
    HttpClientAdapter? httpClientAdapter,
    Transformer? transformer,
  }) {
    final dio = Dio(options ?? this.options);
    dio.interceptors.removeImplyContentTypeInterceptor();
    dio.interceptors.addAll(interceptors ?? this.interceptors);
    dio.httpClientAdapter = httpClientAdapter ?? this.httpClientAdapter;
    dio.transformer = transformer ?? this.transformer;
    return dio;
  }
}

/// A null-check function for function parameters in Null Safety enabled code.
///
/// Because Dart does not have full null safety until all legacy code has been
/// removed from a program, a non-nullable parameter can still end up with a
/// `null` value. This function can be used to guard those functions against
/// null arguments. It throws a [TypeError] because we are really seeing
/// the failure to assign `null` to a non-nullable type.
///
/// See http://dartbug.com/40614 for context.
T _checkNotNullable<T extends Object>(T value, String name) {
  if ((value as dynamic) == null) {
    throw NotNullableError<T>(name);
  }
  return value;
}

/// A [TypeError] thrown by [_checkNotNullable].
class NotNullableError<T> extends Error implements TypeError {
  NotNullableError(this._name);

  final String _name;

  @override
  String toString() => "Null is not a valid value for '$_name' of type '$T'";
}
