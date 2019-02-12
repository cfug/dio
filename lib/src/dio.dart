import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'cancel_token.dart';
import 'dio_error.dart';
import 'form_data.dart';
import 'interceptor.dart';
import 'options.dart';
import 'response.dart';
import 'transformer.dart';
import 'adapter.dart';

/// Callback to listen the file downloading progress.
///
/// [received] is the length of the bytes have been received.
///
/// [total] is the content length of the response body. Returns -1 if
/// the size of the response body is not known in advance,
/// such as response data is compressed with gzip.
typedef void OnDownloadProgress(int received, int total);

/// Callback to listen request uploading progress.
///
/// [sent] is the length of the bytes have been sent.
///
/// [total] is the content length of the post body.
typedef OnUploadProgress(int sent, int total);

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Dio is
/// very easy to use.
class Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  Dio([BaseOptions options]) {
    if (options == null) {
      options = new BaseOptions();
    }
    this.options = options;
  }

  /// The Dio version.
  static const version = "2.0.1";

  /// Default Request config. More see [BaseOptions] .
  BaseOptions options;

  /// Each Dio instance has a interceptor by which you can intercept requests or responses before they are
  /// handled by `then` or `catchError`. the [interceptor] field
  /// contains a [RequestInterceptor] and a [ResponseInterceptor] instance.
  ///

  Interceptors _interceptors = new Interceptors();

  Interceptors get interceptors => _interceptors;

  HttpClientAdapter _httpClientAdapter = new DefaultHttpClientAdapter();

  HttpClientAdapter get httpClientAdapter => _httpClientAdapter;

  set httpClientAdapter(HttpClientAdapter adapter) {
    if (adapter != null) _httpClientAdapter = adapter;
  }

  /// [transformer] allows changes to the request/response data before it is sent/received to/from the server
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
  Transformer transformer = new DefaultTransformer();

  /// Handy method to make http GET request, which is a alias of  [Dio.request].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    Options options,
    CancelToken cancelToken,
  }) {
    return request<T>(
      path,
      queryParameters: queryParameters,
      options: _checkOptions("GET", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http GET request, which is a alias of [Dio.request].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Options options,
    CancelToken cancelToken,
  }) {
    return requestUri<T>(
      uri,
      options: _checkOptions("GET", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    Options options,
    CancelToken cancelToken,
    OnUploadProgress onUploadProgress,
  }) {
    return request<T>(path,
        data: data,
        options: _checkOptions("POST", options),
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onUploadProgress: onUploadProgress);
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
    OnUploadProgress onUploadProgress,
  }) {
    return requestUri<T>(uri,
        data: data,
        options: _checkOptions("POST", options),
        cancelToken: cancelToken,
        onUploadProgress: onUploadProgress);
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response<T>> put<T>(String path,
      {data,
      Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
      Options options,
      CancelToken cancelToken,
      OnUploadProgress onUploadProgress}) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("PUT", options),
      cancelToken: cancelToken,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
    OnUploadProgress onUploadProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("PUT", options),
      cancelToken: cancelToken,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Handy method to make http HEAD request, which is a alias of  [Dio.request].
  Future<Response<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    Options options,
    CancelToken cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("HEAD", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http HEAD request, which is a alias of  [Dio.request].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
  }) {
    return requestUri<T>(uri,
        data: data,
        options: _checkOptions("HEAD", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http DELETE request, which is a alias of  [Dio.request].
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    Options options,
    CancelToken cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("DELETE", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http DELETE request, which is a alias of  [Dio.request].
  Future<Response<T>> deleteUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("DELETE", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http PATCH request, which is a alias of  [Dio.request].
  Future<Response<T>> patch<T>(
    String path, {
    data,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    Options options,
    CancelToken cancelToken,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("PATCH", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http PATCH request, which is a alias of  [Dio.request].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("PATCH", options),
      cancelToken: cancelToken,
    );
  }

  /// Assure the final future state is succeed!
  Future<Response<T>> resolve<T>(response) {
    if (response is! Future) {
      response = new Future.value(response);
    }
    return response.then<Response<T>>((data) {
      return _assureResponse<T>(data);
    }, onError: (err) {
      // transform "error" to "success"
      return _assureResponse<T>(err);
    });
  }

  /// Assure the final future state is failed!
  Future<Response<T>> reject<T>(err) {
    if (err is! Future) {
      err = new Future.error(err);
    }
    return err.then<Response<T>>((v) {
      // transform "success" to "error"
      throw _assureDioError(v);
    }, onError: (e) {
      throw _assureDioError(e);
    });
  }

  /**
   * Lock the current Dio instance.
   *
   * Dio will enqueue the incoming request tasks instead
   * send them directly when [interceptor.request] is locked.
   *
   */
  lock() {
    interceptors.requestLock.lock();
  }

  /**
   * Unlock the current Dio instance.
   *
   * Dio instance dequeue the request task。
   */
  unlock() {
    interceptors.requestLock.unlock();
  }

  /**
   * Clear the current Dio instance waiting queue.
   */
  clear() {
    interceptors.requestLock.clear();
  }

  /**
   * Download the file and save it in local. The default http method is "GET",
   * you can custom it by [Options.method].
   *
   * [urlPath]: The file url.
   *
   * [savePath]: The path to save the downloading file later.
   *
   * [onProgress]: The callback to listen downloading progress.
   * please refer to [OnDownloadProgress].
   *
   * [lengthHeader] : The real size of original file (not compressed).
   * When file is compressed:
   * 1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
   * 2. If this value is not 'content-length', maybe a custom header indicates the original
   * file size , the `total` argument of `onProgress` will be this header value.
   *
   * you can also disable the compression by specifying the 'accept-encoding' header value as '*'
   * to assure the value of `total` argument of `onProgress` is not -1. for example:
   *
   *    await dio.download(url, "./example/flutter.svg",
   *    options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
   *    onProgress: (received, total) {
   *      if (total != -1) {
   *       print((received / total * 100).toStringAsFixed(0) + "%");
   *      }
   *    });
   */
  Future<Response> download(
    String urlPath,
    savePath, {
    OnDownloadProgress onProgress,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    CancelToken cancelToken,
    lengthHeader: HttpHeaders.contentLengthHeader,
    data,
    Options options,
  }) async {
    // We set the `responseType` to [ResponseType.STREAM] to retrieve the
    // response stream.
    if (options != null) {
      options.method = options.method ?? "GET";
    } else {
      options = _checkOptions("GET", options);
    }

    // Receive data with stream.
    options.responseType = ResponseType.stream;
    Response<ResponseBody> response;
    try {
      response = await _request(
        urlPath,
        data: data,
        options: options,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? CancelToken(),
      );
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE) {
        if (options.receiveDataWhenStatusError) {
          var res = await transformer.transformResponse(
            e.response.request..responseType = ResponseType.json,
            e.response.data,
          );
          e.response.data = res;
        } else {
          e.response.data.close();
          e.response.data = null;
        }
      }
      rethrow;
    }

    File file = new File(savePath);

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the
    // file with a very big size(up 1G), it will be expensive in memory.
    var raf = file.openSync(mode: FileMode.write);

    //Create a new Completer to notify the success/error state.
    Completer completer = new Completer<Response>();
    Future future = completer.future;
    int received = 0;

    // Stream<List<int>>
    Stream<List<int>> stream = response.data.stream;
    // Handle  timeout
    if (options.receiveTimeout > 0) {
      stream = stream.timeout(
        new Duration(milliseconds: options.receiveTimeout),
        onTimeout: (EventSink sink) {
          sink.addError(new DioError(
              request: response.request,
              message: "Receiving data timeout[${options.receiveTimeout}ms]",
              type: DioErrorType.RECEIVE_TIMEOUT));
          sink.close();
        },
      );
    }

    bool compressed = false;
    int total = 0;
    String contentEncoding =
        response.headers.value(HttpHeaders.contentEncodingHeader);
    if (contentEncoding != null) {
      compressed = ["gzip", 'deflate', 'compress'].contains(contentEncoding);
    }
    if (lengthHeader == HttpHeaders.contentLengthHeader && compressed) {
      total = -1;
    } else {
      total = int.parse(response.headers.value(lengthHeader) ?? "-1");
    }

    stream.listen(
      (data) {
        // Check if cancelled.
        if (cancelToken != null && cancelToken.cancelError != null) {
          response.data.close();
          return;
        }
        // Write file.
        raf.writeFromSync(data);
        // Notify progress
        received += data.length;
        if (onProgress != null) {
          onProgress(received, total);
        }
      },
      onDone: () {
        raf.closeSync();
        response.headers = response.data.headers;
        completer.complete(response);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(_assureDioError(e));
      },
      cancelOnError: true,
    );
    return _listenCancelForAsyncTask(cancelToken, future);
  }

  /**
   * Download the file and save it in local. The default http method is "GET",
   * you can custom it by [Options.method].
   *
   * [uri]: The file uri.
   *
   * [savePath]: The path to save the downloading file later.
   *
   * [onProgress]: The callback to listen downloading progress.
   * please refer to [OnDownloadProgress].
   *
   * [lengthHeader] : The real size of original file (not compressed).
   * When file is compressed:
   * 1. If this value is 'content-length', the `total` argument of `onProgress` will be -1
   * 2. If this value is not 'content-length', maybe a custom header indicates the original
   * file size , the `total` argument of `onProgress` will be this header value.
   *
   * you can also disable the compression by specifying the 'accept-encoding' header value as '*'
   * to assure the value of `total` argument of `onProgress` is not -1. for example:
   *
   *    await dio.download(url, "./example/flutter.svg",
   *    options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
   *    onProgress: (received, total) {
   *      if (total != -1) {
   *       print((received / total * 100).toStringAsFixed(0) + "%");
   *      }
   *    });
   */
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    OnDownloadProgress onProgress,
    CancelToken cancelToken,
    lengthHeader: HttpHeaders.contentLengthHeader,
    data,
    Options options,
  }) {
    return download(
      uri.toString(),
      savePath,
      onProgress: onProgress,
      lengthHeader: lengthHeader,
      cancelToken: cancelToken,
      data: data,
      options: options,
    );
  }

  /**
   * Make http request with options.
   *
   * [path] The url path.
   * [data] The request data
   * [options] The request options.
   */
  Future<Response<T>> request<T>(
    String path, {
    data,
    Map<String, dynamic /*String|Iterable<String>*/ > queryParameters,
    CancelToken cancelToken,
    Options options,
    OnUploadProgress onUploadProgress,
  }) async {
    return _request<T>(path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
        onUploadProgress: onUploadProgress);
  }

  /**
   * Make http request with options.
   *
   * [uri] The uri.
   * [data] The request data
   * [options] The request options.
   */
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    data,
    CancelToken cancelToken,
    Options options,
    OnUploadProgress onUploadProgress,
  }) {
    return request(uri.toString(),
        data: data,
        cancelToken: cancelToken,
        options: options,
        onUploadProgress: onUploadProgress);
  }

  Future _assureFuture(e) {
    if (e is! Future) {
      return Future.value(e);
    }
    return e;
  }

  Future _executeInterceptors<T>(T ob, f(Interceptor inter, T ob)) async {
    for (var inter in interceptors) {
      var res = await _assureFuture(f(inter, ob));
      if (res != null) {
        if (res is T) {
          ob = res;
          continue;
        }
        if (res is Response || res is DioError) return res;
        return res;
      }
    }
    return ob;
  }

  Future<Response<T>> _request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    Options options,
    OnUploadProgress onUploadProgress,
  }) async {
    Completer cancelCompleter;
    if (cancelToken != null) {
      cancelCompleter = Completer();
    }
    RequestOptions requestOptions =
        _mergeOptions(options, path, data, queryParameters);
    Future<Response<T>> future =
        _checkIfNeedEnqueue<T>(interceptors.requestLock, () {
      Future ret = _executeInterceptors<RequestOptions>(
          requestOptions, (Interceptor inter, ob) => inter.onRequest(ob));
      return ret.then<Response<T>>((data) {
        FutureOr<Response<T>> response;
        // If the Future value type is Options, continue the network request.
        if (data is RequestOptions) {
          requestOptions.method = data.method.toUpperCase();
          response = _makeRequest<T>(
              data, cancelToken, cancelCompleter, onUploadProgress);
        } else {
          // Otherwise, use the Future value as the request result.
          // If the return type is Error, we should throw it
          if (data is Error) throw _assureDioError(data);
          response = _assureResponse(data);
        }
        return response;
      }).catchError((err) => throw _assureDioError(err));
    });

    return await _listenCancelForAsyncTask<Response<T>>(cancelToken, future);
  }

  Future<Response<T>> _makeRequest<T>(
      RequestOptions options, CancelToken cancelToken,
      [Completer cancelCompleter, OnUploadProgress onUploadProgress]) async {
    _checkCancelled(cancelToken);
    ResponseBody responseBody;
    try {
      var stream = await _transformData(options, onUploadProgress);
      responseBody = await httpClientAdapter.sendRequest(
        options,
        stream,
        (future) => _listenCancelForAsyncTask(cancelToken, future),
        cancelCompleter?.future,
      );
      Response ret = new Response(
          headers: responseBody.headers,
          request: options,
          statusCode: responseBody.statusCode);
      Future future;
      bool statusOk = options.validateStatus(responseBody.statusCode);
      if (statusOk || options.receiveDataWhenStatusError) {
        ret.data = await _listenCancelForAsyncTask(
            cancelToken, transformer.transformResponse(options, responseBody));
      } else {
        responseBody.stream.drain();
        if (cancelToken != null) cancelCompleter.complete();
      }
      _checkCancelled(cancelToken);
      if (statusOk) {
        future = _onResponse<T>(ret);
      } else {
        var err = new DioError(
          response: ret,
          message: 'Http status error [${responseBody.statusCode}]',
          type: DioErrorType.RESPONSE,
        );
        future = _onError<T>(err);
      }
      return _listenCancelForAsyncTask<Response<T>>(cancelToken, future);
    } catch (e) {
      DioError err = _assureDioError(e);
      if (CancelToken.isCancel(err)) {
        cancelCompleter?.complete();
        throw err;
      } else {
        // Response onError
        _checkCancelled(cancelToken);
        // Listen in error interceptor.
        return _listenCancelForAsyncTask<Response<T>>(
            cancelToken, _onError<T>(err));
      }
    }
  }

  // If the request has been cancelled, stop request and throw error.
  _checkCancelled(CancelToken cancelToken) {
    if (cancelToken != null && cancelToken.cancelError != null) {
      throw cancelToken.cancelError;
    }
  }

  Future<T> _listenCancelForAsyncTask<T>(
      CancelToken cancelToken, Future<T> future) {
    Completer completer = new Completer();
    if (cancelToken != null && cancelToken.cancelError == null) {
      cancelToken.addCompleter(completer);
      return Future.any([completer.future, future]).then<T>((result) {
        cancelToken.removeCompleter(completer);
        return result;
      }).catchError((e) {
        cancelToken.removeCompleter(completer);
        throw e;
      });
    } else {
      return future;
    }
  }

  Future<Stream<List<int>>> _transformData(RequestOptions options,
      [OnUploadProgress onUploadProgress]) async {
    var data = options.data;
    List<int> bytes;
    if (data != null && ["POST", "PUT", "PATCH"].contains(options.method)) {
      // Handle the FormData
      if (data is FormData) {
        options.headers[HttpHeaders.contentTypeHeader] =
            'multipart/form-data; boundary=${data.boundary.substring(2)}';
        bytes = data.bytes();
      } else {
        options.headers[HttpHeaders.contentTypeHeader] =
            options.contentType.toString();
        // If Byte Array
        if (data is List<int>) {
          bytes = data;
        } else {
          // Call request transformer.
          String _data = await transformer.transformRequest(options);
          // Convert to utf8
          bytes = utf8.encode(_data);
        }
      }
      options.headers[HttpHeaders.contentLengthHeader] = bytes.length;
      // support data sending progress
      int length = bytes.length;
      int complete = 0;
      var group = new List<List<int>>();
      const size = 1024;
      int groupCount = (bytes.length / size).ceil();
      for (int i = 0; i < groupCount; ++i) {
        int start = i * size;
        group.add(bytes.sublist(start, math.min(start + size, bytes.length)));
      }
      var stream = Stream.fromIterable(group);
      Stream<List<int>> byteStream = stream
          .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data);
        complete += data.length;
        if (onUploadProgress != null) {
          onUploadProgress(complete, length);
        }
      }));
      return byteStream;
    }
    return null;
  }

// Transform current Future status("success" and "error") if necessary
  Future<Response<T>> _transFutureStatusIfNecessary<T>(Future future) {
    return future.then<Response<T>>((data) {
      // Strictly be a DioError instance, but we relax the restrictions
      // if (data is DioError)
      if (data is Error) {
        return reject<T>(data);
      }
      return resolve<T>(data);
    }, onError: (err) {
      if (err is Response) {
        return resolve<T>(err);
      }
      return reject<T>(err);
    });
  }

  Future<Response<T>> _onResponse<T>(Response response) {
    return _checkIfNeedEnqueue(interceptors.responseLock, () {
      return _transFutureStatusIfNecessary<T>(_executeInterceptors(
          response, (Interceptor inter, ob) => inter.onResponse(ob)));
    });
  }

  Future<Response<T>> _onError<T>(err) {
    return _checkIfNeedEnqueue(interceptors.errorLock, () {
      return _transFutureStatusIfNecessary<T>(_executeInterceptors(
          err, (Interceptor inter, ob) => inter.onError(err)));
    });
  }

  RequestOptions _mergeOptions(
      Options opt, String url, data, Map<String, dynamic> queryParameters) {
    var query = (new Map<String, dynamic>.from(options.queryParameters ?? {}))
      ..addAll(queryParameters ?? {});
    return RequestOptions(
      method: opt.method.toUpperCase(),
      headers: (new Map.from(options.headers))..addAll(opt.headers),
      baseUrl: options.baseUrl ?? "",
      path: url,
      data: data,
      connectTimeout: opt.connectTimeout ?? options.connectTimeout ?? 0,
      receiveTimeout: opt.receiveTimeout ?? options.receiveTimeout ?? 0,
      responseType:
          opt.responseType ?? options.responseType ?? ResponseType.json,
      extra: (new Map.from(options.extra))..addAll(opt.extra),
      contentType: opt.contentType ?? options.contentType ?? ContentType.json,
      validateStatus: opt.validateStatus ??
          options.validateStatus ??
          (int status) => status >= 200 && status < 300 || status == 304,
      followRedirects: opt.followRedirects ?? options.followRedirects ?? true,
      queryParameters: query,
      cookies: new List.from(options.cookies ?? [])..addAll(opt.cookies ?? []),
    );
  }

  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
    }
    options.method = method;
    return options;
  }

  Future<Response<T>> _checkIfNeedEnqueue<T>(Lock lock, callback()) {
    if (lock.locked) {
      return lock.enqueue(callback);
    } else {
      return callback();
    }
  }

  DioError _assureDioError(err) {
    if (err is DioError) {
      return err;
    } else if (err is Error) {
      err = new DioError(
          response: null, message: err.toString(), stackTrace: err.stackTrace);
    } else {
      err = new DioError(message: err.toString());
    }
    return err;
  }

  Response<T> _assureResponse<T>(response) {
    if (response is Response<T>) {
      return response;
    } else if (response is! Response) {
      response = new Response<T>(data: response);
    } else {
      T data = response.data;
      response = new Response<T>(
        data: data,
        headers: response.headers,
        request: response.request,
        statusCode: response.statusCode,
      );
    }
    return response;
  }
}
