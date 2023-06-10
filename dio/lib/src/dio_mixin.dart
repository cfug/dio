import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'adapter.dart';
import 'cancel_token.dart';
import 'dio.dart';
import 'dio_exception.dart';
import 'form_data.dart';
import 'headers.dart';
import 'interceptors/imply_content_type.dart';
import 'options.dart';
import 'response.dart';
import 'transformer.dart';
import 'transformers/background_transformer.dart';

import 'progress_stream/io_progress_stream.dart'
    if (dart.library.html) 'progress_stream/browser_progress_stream.dart';

part 'interceptor.dart';

abstract class DioMixin implements Dio {
  /// Default Request config. More see [BaseOptions].
  @override
  late BaseOptions options;

  /// Each Dio instance has a interceptor by which you can intercept requests or responses before they are
  /// handled by `then` or `catchError`. the [interceptor] field
  /// contains a [RequestInterceptor] and a [ResponseInterceptor] instance.
  final Interceptors _interceptors = Interceptors();

  @override
  Interceptors get interceptors => _interceptors;

  @override
  late HttpClientAdapter httpClientAdapter;

  @override
  Transformer transformer = BackgroundTransformer();

  bool _closed = false;

  @override
  void close({bool force = false}) {
    _closed = true;
    httpClientAdapter.close(force: force);
  }

  /// Handy method to make http GET request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http GET request, which is a alias of [BaseDio.requestOptions].
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

  /// Handy method to make http POST request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http POST request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http PUT request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http PUT request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http HEAD request, which is a alias of [BaseDio.requestOptions].
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

  /// Handy method to make http HEAD request, which is a alias of [BaseDio.requestOptions].
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

  /// Handy method to make http DELETE request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http DELETE request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http PATCH request, which is a alias of  [BaseDio.requestOptions].
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

  /// Handy method to make http PATCH request, which is a alias of  [BaseDio.requestOptions].
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

  @override
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
  }) {
    throw UnsupportedError(
      'download() is not available in the current environment.',
    );
  }

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
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

  /// Make http request with options.
  ///
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
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
      return (err) {
        final state = err is InterceptorState
            ? err
            : InterceptorState(assureDioException(err, requestOptions));
        Future<InterceptorState> handleError() async {
          final errorHandler = ErrorInterceptorHandler();
          interceptor(state.data, errorHandler);
          return errorHandler.future;
        }

        // The request has already been canceled,
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
          throw err;
        }
      };
    }

    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.

    // Start the request flow
    Future<dynamic> future = Future<dynamic>(
      () => InterceptorState(requestOptions),
    );

    // Add request interceptors to request flow
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleRequest
          : interceptor.onRequest;
      future = future.then(requestInterceptorWrapper(fun));
    }

    // Add dispatching callback to request flow
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

    // Add response interceptors to request flow
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleResponse
          : interceptor.onResponse;
      future = future.then(responseInterceptorWrapper(fun));
    }

    // Add error handlers to request flow
    for (final interceptor in interceptors) {
      final fun = interceptor is QueuedInterceptor
          ? interceptor._handleError
          : interceptor.onError;
      future = future.catchError(errorInterceptorWrapper(fun));
    }
    // Normalize errors, we convert error to the DioException.
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

  // Initiate Http requests
  Future<Response<dynamic>> _dispatchRequest<T>(RequestOptions reqOpt) async {
    final cancelToken = reqOpt.cancelToken;
    ResponseBody responseBody;
    try {
      final stream = await _transformData(reqOpt);
      responseBody = await httpClientAdapter.fetch(
        reqOpt,
        stream,
        cancelToken?.whenCancel,
      );
      final headers = Headers.fromMap(responseBody.headers);
      // Make sure headers and responseBody.headers point to a same Map
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
        ret.data = await transformer.transformResponse(reqOpt, responseBody);
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
      // Handle the FormData
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
          // Handle binary data which does not need to be transformed
          bytes = data;
        } else {
          // Call request transformer for anything else
          final transformed = await transformer.transformRequest(options);
          if (options.requestEncoder != null) {
            bytes = options.requestEncoder!(transformed, options);
          } else {
            // Default convert to utf8
            bytes = utf8.encode(transformed);
          }
        }

        // support data sending progress
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

  // If the request has been cancelled, stop request and throw error.
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
    Object err,
    RequestOptions requestOptions,
  ) {
    if (err is DioException) {
      // nothing to be done
      return err;
    }
    return DioException(
      requestOptions: requestOptions,
      error: err,
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
        headers = Headers.fromMap(data.headers);
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

/// A null-check function for function parameters in Null Safety enabled code.
///
/// Because Dart does not have full null safety
/// until all legacy code has been removed from a program,
/// a non-nullable parameter can still end up with a `null` value.
/// This function can be used to guard those functions against null arguments.
/// It throws a [TypeError] because we are really seeing the failure to
/// assign `null` to a non-nullable type.
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
