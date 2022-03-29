import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'adapter.dart';
import 'cancel_token.dart';
import 'dio.dart';
import 'dio_error.dart';
import 'form_data.dart';
import 'headers.dart';
import 'options.dart';
import 'response.dart';
import 'transformer.dart';

import 'progress_stream_stub.dart'
// ignore: uri_does_not_exist
    if (dart.library.html) 'progress_stream/browser_progress_stream.dart'
// ignore: uri_does_not_exist
    if (dart.library.io) 'progress_stream/io_progress_stream.dart';

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
  Transformer transformer = DefaultTransformer();

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
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
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
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      options: checkOptions('GET', options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [BaseDio.requestOptions].
  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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
    data,
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

  /// Lock the current Dio instance.
  ///
  /// Dio will enqueue the incoming request tasks instead
  /// send them directly when [interceptor.requestOptions] is locked.
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  @override
  void lock() {
    interceptors.requestLock.lock();
  }

  /// Unlock the current Dio instance.
  ///
  /// Dio instance dequeue the request task。
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  @override
  void unlock() {
    interceptors.requestLock.unlock();
  }

  ///Clear the current Dio instance waiting queue.
  @Deprecated(
      'Will delete in v5.0. Use `QueuedInterceptor` instead, more detail see'
      ' https://github.com/flutterchina/dio/issues/1308')
  @override
  void clear() {
    interceptors.requestLock.clear();
  }

  ///  Download the file and save it in local. The default http method is 'GET',
  ///  you can custom it by [Options.method].
  ///
  ///  [urlPath]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg 'xs.jpg'
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await dio.download(url,(HttpHeaders responseHeaders){
  ///      ...
  ///      return '...';
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  /// [deleteOnError] Whether delete the file when error occurs. The default value is [true].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await dio.download(url, './example/flutter.svg',
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: '*'}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + '%');
  ///       }
  ///     });

  @override
  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) async {
    throw UnsupportedError('Unsupport download API in browser');
  }

  ///  Download the file and save it in local. The default http method is 'GET',
  ///  you can custom it by [Options.method].
  ///
  ///  [uri]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg 'xs.jpg'
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await dio.downloadUri(uri,(HttpHeaders responseHeaders){
  ///      ...
  ///      return '...';
  ///    });
  ///  ```
  ///
  ///  [onReceiveProgress]: The callback to listen downloading progress.
  ///  please refer to [ProgressCallback].
  ///
  ///  [lengthHeader] : The real size of original file (not compressed).
  ///  When file is compressed:
  ///  1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
  ///  2. If this value is not 'content-length', maybe a custom header indicates the original
  ///  file size , the `total` argument of `onProgress` will be this header value.
  ///
  ///  you can also disable the compression by specifying the 'accept-encoding' header value as '*'
  ///  to assure the value of `total` argument of `onProgress` is not -1. for example:
  ///
  ///     await dio.downloadUri(uri, './example/flutter.svg',
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: '*'}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + '%');
  ///       }
  ///     });
  @override
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
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

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
  @override
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    data,
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
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    options ??= Options();
    var requestOptions = options.compose(
      this.options,
      path,
      data: data,
      queryParameters: queryParameters,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    requestOptions.onReceiveProgress = onReceiveProgress;
    requestOptions.onSendProgress = onSendProgress;
    requestOptions.cancelToken = cancelToken;

    if (_closed) {
      throw DioError(
        requestOptions: requestOptions,
        error: "Dio can't establish new connection after closed.",
      );
    }

    return fetch<T>(requestOptions);
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    final stackTrace = StackTrace.current;

    if (requestOptions.cancelToken != null) {
      requestOptions.cancelToken!.requestOptions = requestOptions;
    }

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
    FutureOr Function(dynamic) _requestInterceptorWrapper(
      InterceptorSendCallback interceptor,
    ) {
      return (dynamic _state) async {
        var state = _state as InterceptorState;
        if (state.type == InterceptorResultType.next) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() {
              return checkIfNeedEnqueue(interceptors.requestLock, () {
                var requestHandler = RequestInterceptorHandler();
                interceptor(state.data as RequestOptions, requestHandler);
                return requestHandler.future;
              });
            }),
          );
        } else {
          return state;
        }
      };
    }

    // Convert the response interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic) _responseInterceptorWrapper(
      InterceptorSuccessCallback interceptor,
    ) {
      return (_state) async {
        var state = _state as InterceptorState;
        if (state.type == InterceptorResultType.next ||
            state.type == InterceptorResultType.resolveCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() {
              return checkIfNeedEnqueue(interceptors.responseLock, () {
                var responseHandler = ResponseInterceptorHandler();
                interceptor(state.data as Response, responseHandler);
                return responseHandler.future;
              });
            }),
          );
        } else {
          return state;
        }
      };
    }

    // Convert the error interceptor to a functional callback in which
    // we can handle the return value of interceptor callback.
    FutureOr<dynamic> Function(dynamic, StackTrace) _errorInterceptorWrapper(
        InterceptorErrorCallback interceptor) {
      return (err, stackTrace) {
        if (err is! InterceptorState) {
          err = InterceptorState(
            assureDioError(
              err,
              requestOptions,
            ),
          );
        }

        if (err.type == InterceptorResultType.next ||
            err.type == InterceptorResultType.rejectCallFollowing) {
          return listenCancelForAsyncTask(
            requestOptions.cancelToken,
            Future(() {
              return checkIfNeedEnqueue(interceptors.errorLock, () {
                var errorHandler = ErrorInterceptorHandler();
                interceptor(err.data as DioError, errorHandler);
                return errorHandler.future;
              });
            }),
          );
        } else {
          throw err;
        }
      };
    }

    // Build a request flow in which the processors(interceptors)
    // execute in FIFO order.

    // Start the request flow
    var future = Future<dynamic>(() => InterceptorState(requestOptions));

    // Add request interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      var fun = interceptor is QueuedInterceptor
          ? interceptor._handleRequest
          : interceptor.onRequest;
      future = future.then(_requestInterceptorWrapper(fun));
    });

    // Add dispatching callback to request flow
    future = future.then(_requestInterceptorWrapper((
      RequestOptions reqOpt,
      RequestInterceptorHandler handler,
    ) {
      requestOptions = reqOpt;
      _dispatchRequest(reqOpt)
          .then((value) => handler.resolve(value, true))
          .catchError((e) {
        handler.reject(e as DioError, true);
      });
    }));

    // Add response interceptors to request flow
    interceptors.forEach((Interceptor interceptor) {
      var fun = interceptor is QueuedInterceptor
          ? interceptor._handleResponse
          : interceptor.onResponse;
      future = future.then(_responseInterceptorWrapper(fun));
    });

    // Add error handlers to request flow
    interceptors.forEach((Interceptor interceptor) {
      var fun = interceptor is QueuedInterceptor
          ? interceptor._handleError
          : interceptor.onError;
      future = future.catchError(_errorInterceptorWrapper(fun));
    });

    // Normalize errors, we convert error to the DioError
    return future.then<Response<T>>((data) {
      return assureResponse<T>(
        data is InterceptorState ? data.data : data,
        requestOptions,
      );
    }).catchError((err, _) {
      var isState = err is InterceptorState;

      if (isState) {
        if ((err as InterceptorState).type == InterceptorResultType.resolve) {
          return assureResponse<T>(err.data, requestOptions);
        }
      }

      throw assureDioError(
        isState ? err.data : err,
        requestOptions,
        stackTrace,
      );
    });
  }

  // Initiate Http requests
  Future<Response<T>> _dispatchRequest<T>(RequestOptions reqOpt) async {
    var cancelToken = reqOpt.cancelToken;
    ResponseBody responseBody;
    try {
      var stream = await _transformData(reqOpt);
      responseBody = await httpClientAdapter.fetch(
        reqOpt,
        stream,
        cancelToken?.whenCancel,
      );
      responseBody.headers = responseBody.headers;
      var headers = Headers.fromMap(responseBody.headers);
      var ret = Response<T>(
        headers: headers,
        requestOptions: reqOpt,
        redirects: responseBody.redirects ?? [],
        isRedirect: responseBody.isRedirect,
        statusCode: responseBody.statusCode,
        statusMessage: responseBody.statusMessage,
        extra: responseBody.extra,
      );
      var statusOk = reqOpt.validateStatus(responseBody.statusCode);
      if (statusOk || reqOpt.receiveDataWhenStatusError == true) {
        var forceConvert = !(T == dynamic || T == String) &&
            !(reqOpt.responseType == ResponseType.bytes ||
                reqOpt.responseType == ResponseType.stream);
        String? contentType;
        if (forceConvert) {
          contentType = headers.value(Headers.contentTypeHeader);
          headers.set(Headers.contentTypeHeader, Headers.jsonContentType);
        }
        ret.data =
            (await transformer.transformResponse(reqOpt, responseBody)) as T?;
        if (forceConvert) {
          headers.set(Headers.contentTypeHeader, contentType);
        }
      } else {
        await responseBody.stream.listen(null).cancel();
      }
      checkCancelled(cancelToken);
      if (statusOk) {
        return checkIfNeedEnqueue(interceptors.responseLock, () => ret);
      } else {
        throw DioError(
          requestOptions: reqOpt,
          response: ret,
          error: 'Http status error [${responseBody.statusCode}]',
          type: DioErrorType.response,
        );
      }
    } catch (e) {
      throw assureDioError(e, reqOpt);
    }
  }

  Future<Stream<Uint8List>?> _transformData(RequestOptions options) async {
    var data = options.data;
    List<int> bytes;
    Stream<List<int>> stream;
    const allowPayloadMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
    if (data != null && allowPayloadMethods.contains(options.method)) {
      // Handle the FormData
      int? length;
      if (data is Stream) {
        assert(data is Stream<List>,
            'Stream type must be `Stream<List>`, but ${data.runtimeType} is found.');
        stream = data as Stream<List<int>>;
        options.headers.keys.any((String key) {
          if (key.toLowerCase() == Headers.contentLengthHeader) {
            length = int.parse(options.headers[key].toString());
            return true;
          }
          return false;
        });
      } else if (data is FormData) {
        options.headers[Headers.contentTypeHeader] =
            'multipart/form-data; boundary=${data.boundary}';

        stream = data.finalize();
        length = data.length;
        options.headers[Headers.contentLengthHeader] = length.toString();
      } else {
        // Call request transformer.
        var _data = await transformer.transformRequest(options);

        if (options.requestEncoder != null) {
          bytes = options.requestEncoder!(_data, options);
        } else {
          //Default convert to utf8
          bytes = utf8.encode(_data);
        }
        // support data sending progress
        length = bytes.length;
        options.headers[Headers.contentLengthHeader] = length.toString();

        var group = <List<int>>[];
        const size = 1024;
        var groupCount = (bytes.length / size).ceil();
        for (var i = 0; i < groupCount; ++i) {
          var start = i * size;
          group.add(bytes.sublist(start, math.min(start + size, bytes.length)));
        }
        stream = Stream.fromIterable(group);
      }
      return addProgress(stream, length, options);
    }
    return null;
  }

  // If the request has been cancelled, stop request and throw error.
  static void checkCancelled(CancelToken? cancelToken) {
    if (cancelToken != null && cancelToken.cancelError != null) {
      throw cancelToken.cancelError!;
    }
  }

  static Future<T> listenCancelForAsyncTask<T>(
      CancelToken? cancelToken, Future<T> future) {
    return Future.any([
      if (cancelToken != null) cancelToken.whenCancel.then((e) => throw e),
      future,
    ]);
  }

  static Options checkOptions(String method, Options? options) {
    options ??= Options();
    options.method = method;
    return options;
  }

  static FutureOr<T> checkIfNeedEnqueue<T>(
    Lock lock,
    _WaitCallback<T> callback,
  ) {
    if (lock.locked) {
      return lock._wait(callback)!;
    } else {
      return callback();
    }
  }

  static DioError assureDioError(
    err,
    RequestOptions requestOptions, [
    StackTrace? sourceStackTrace,
  ]) {
    DioError dioError;
    if (err is DioError) {
      dioError = err;
    } else {
      dioError = DioError(requestOptions: requestOptions, error: err);
    }

    dioError.stackTrace = sourceStackTrace ?? dioError.stackTrace;

    return dioError;
  }

  static Response<T> assureResponse<T>(response,
      [RequestOptions? requestOptions]) {
    if (response is! Response) {
      return Response<T>(
        data: response as T,
        requestOptions: requestOptions ?? RequestOptions(path: ''),
      );
    } else if (response is! Response<T>) {
      T? data = response.data as T?;
      return Response<T>(
        data: data,
        headers: response.headers,
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
