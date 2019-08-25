import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'cancel_token.dart';
import 'dio_error.dart';
import 'form_data.dart';
import 'interceptor.dart';
import 'options.dart';
import 'response.dart';
import 'transformer.dart';
import 'adapter.dart';
import 'dio_http_headers.dart';

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

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Dio is
/// very easy to use.
///
/// You can create a dio instance and config it by two ways:
/// 1. create first , then config it
///
///   ```dart
///    var dio = Dio();
///    dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
///    dio.options.connectTimeout = 5000; //5s
///    dio.options.receiveTimeout = 5000;
///    dio.options.headers = {HttpHeaders.userAgentHeader: 'dio', 'common-header': 'xx'};
///   ```
/// 2. create and config it:
///
/// ```dart
///   var dio = Dio(BaseOptions(
///    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
///    connectTimeout: 5000,
///    receiveTimeout: 5000,
///    headers: {HttpHeaders.userAgentHeader: 'dio', 'common-header': 'xx'},
///   ));
///  ```

class Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  Dio([BaseOptions options]) {
    if (options == null) {
      options = new BaseOptions();
    }
    this.options = options;
  }

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
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onReceiveProgress,
  }) {
    return request<T>(
      path,
      queryParameters: queryParameters,
      options: _checkOptions("GET", options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http GET request, which is a alias of [Dio.request].
  Future<Response<T>> getUri<T>(
    Uri uri, {
    Options options,
    CancelToken cancelToken,
    ProgressCallback onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      options: _checkOptions("GET", options),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      options: _checkOptions("POST", options),
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response<T>> postUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("POST", options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response<T>> put<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("PUT", options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response<T>> putUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("PUT", options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http HEAD request, which is a alias of [Dio.request].
  Future<Response<T>> head<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
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

  /// Handy method to make http HEAD request, which is a alias of [Dio.request].
  Future<Response<T>> headUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("HEAD", options),
      cancelToken: cancelToken,
    );
  }

  /// Handy method to make http DELETE request, which is a alias of  [Dio.request].
  Future<Response<T>> delete<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
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
    Map<String, dynamic> queryParameters,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _checkOptions("PATCH", options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Handy method to make http PATCH request, which is a alias of  [Dio.request].
  Future<Response<T>> patchUri<T>(
    Uri uri, {
    data,
    Options options,
    CancelToken cancelToken,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) {
    return requestUri<T>(
      uri,
      data: data,
      options: _checkOptions("PATCH", options),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
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

  /// Lock the current Dio instance.
  ///
  /// Dio will enqueue the incoming request tasks instead
  /// send them directly when [interceptor.request] is locked.

  lock() {
    interceptors.requestLock.lock();
  }

  /// Unlock the current Dio instance.
  ///
  /// Dio instance dequeue the request task。
  unlock() {
    interceptors.requestLock.unlock();
  }

  ///Clear the current Dio instance waiting queue.

  clear() {
    interceptors.requestLock.clear();
  }

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [urlPath]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await dio.download(url,(HttpHeaders responseHeaders){
  ///      ...
  ///      return "...";
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
  ///     await dio.download(url, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });

  Future<Response> download(
    String urlPath,
    savePath, {
    ProgressCallback onReceiveProgress,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    bool deleteOnError = true,
    lengthHeader = HttpHeaders.contentLengthHeader,
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
        if (e.response.request.receiveDataWhenStatusError) {
          var res = await transformer.transformResponse(
            e.response.request..responseType = ResponseType.json,
            e.response.data,
          );
          e.response.data = res;
        } else {
          e.response.data = null;
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }

    response.headers = response.data.headers;
    File file;
    if (savePath is Function) {
      assert(savePath is String Function(HttpHeaders),
          "savePath callback type must be `String Function(HttpHeaders)`");
      file = File(savePath(response.headers));
    } else {
      file = File(savePath.toString());
    }

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the
    // file with a very big size(up 1G), it will be expensive in memory.
    var raf = file.openSync(mode: FileMode.write);

    //Create a new Completer to notify the success/error state.
    Completer completer = new Completer<Response>();
    Future future = completer.future;
    int received = 0;

    // Stream<Uint8List>
    Stream<Uint8List> stream = response.data.stream;
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

    StreamSubscription subscription;
    Future asyncWrite;
    bool closed = false;
    _closeAndDelete() async {
      if (!closed) {
        closed = true;
        await asyncWrite;
        await raf.close();
        if (deleteOnError) await file.delete();
      }
    }

    subscription = stream.listen(
      (data) {
        subscription.pause();
        // Write file asynchronously
        asyncWrite = raf.writeFrom(data).then((_raf) {
          // Notify progress
          received += data.length;
          if (onReceiveProgress != null) {
            onReceiveProgress(received, total);
          }
          raf = _raf;
          if (cancelToken == null || !cancelToken.isCancelled) {
            subscription.resume();
          }
        }).catchError((derr) async {
          try {
            await subscription.cancel();

          } finally {
            completer.completeError(_assureDioError(derr));
          }
        });
      },
      onDone: () async {
        try {
          await asyncWrite;
          await raf.close();
          completer.complete(response);
        } catch (e) {
          completer.completeError(_assureDioError(e));
        }
      },
      onError: (e) async {
        try {
          await _closeAndDelete();
        } finally {
          completer.completeError(_assureDioError(e));
        }
      },
      cancelOnError: true,
    );
    // ignore: unawaited_futures
    cancelToken?.whenCancel?.then((_) async {
      await subscription.cancel();
      await _closeAndDelete();
    });

    if (response.request.receiveTimeout > 0) {
      future = future
          .timeout(Duration(milliseconds: response.request.receiveTimeout))
          .catchError((err) async {
        await subscription.cancel();
        await _closeAndDelete();
        throw DioError(
          request: response.request,
          message:
              "Receiving data timeout[${response.request.receiveTimeout}ms]",
          type: DioErrorType.RECEIVE_TIMEOUT,
        );
      });
    }
    return await _listenCancelForAsyncTask(cancelToken, future);
  }

  ///  Download the file and save it in local. The default http method is "GET",
  ///  you can custom it by [Options.method].
  ///
  ///  [uri]: The file url.
  ///
  ///  [savePath]: The path to save the downloading file later. it can be a String or
  ///  a callback:
  ///  1. A path with String type, eg "xs.jpg"
  ///  2. A callback `String Function(HttpHeaders responseHeaders)`; for example:
  ///  ```dart
  ///   await dio.downloadUri(uri,(HttpHeaders responseHeaders){
  ///      ...
  ///      return "...";
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
  ///     await dio.downloadUri(uri, "./example/flutter.svg",
  ///     options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
  ///     onProgress: (received, total) {
  ///       if (total != -1) {
  ///        print((received / total * 100).toStringAsFixed(0) + "%");
  ///       }
  ///     });
  Future<Response> downloadUri(
    Uri uri,
    savePath, {
    ProgressCallback onReceiveProgress,
    CancelToken cancelToken,
    bool deleteOnError = true,
    lengthHeader = HttpHeaders.contentLengthHeader,
    data,
    Options options,
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
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.

  Future<Response<T>> request<T>(
    String path, {
    data,
    Map<String, dynamic> queryParameters,
    CancelToken cancelToken,
    Options options,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) async {
    return _request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Make http request with options.
  ///
  /// [uri] The uri.
  /// [data] The request data
  /// [options] The request options.
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    data,
    CancelToken cancelToken,
    Options options,
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
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
    ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress,
  }) async {
    if (options == null) options = Options();
    if (options is RequestOptions) {
      data = data ?? options.data;
      queryParameters = queryParameters ?? options.queryParameters;
      cancelToken = cancelToken ?? options.cancelToken;
      onSendProgress = onSendProgress ?? options.onSendProgress;
      onReceiveProgress = onReceiveProgress ?? options.onReceiveProgress;
    }
    RequestOptions requestOptions =
        _mergeOptions(options, path, data, queryParameters);
    requestOptions.onReceiveProgress = onReceiveProgress;
    requestOptions.onSendProgress = onSendProgress;
    requestOptions.cancelToken = cancelToken;
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    Future<Response<T>> future =
        _checkIfNeedEnqueue<T>(interceptors.requestLock, () {
      Future ret = _executeInterceptors<RequestOptions>(
          requestOptions, (Interceptor inter, ob) => inter.onRequest(ob));
      return ret.then<Response<T>>((data) {
        FutureOr<Response<T>> response;

        // If the Future value type is Options, continue the network request.
        if (data is RequestOptions) {
          requestOptions.method = data.method.toUpperCase();
          response = _makeRequest<T>(data, cancelToken);
        } else {
          // Otherwise, use the Future value as the request result.
          // If the return type is Exception, we should throw it
          if (data is Exception) throw _assureDioError(data);
          var r = _assureResponse<T>(data);

          response = r;
        }
        return response;
      }).catchError((err) => throw _assureDioError(err));
    });

    return await _listenCancelForAsyncTask<Response<T>>(cancelToken, future)
        .then((r) {
      r.request = r.request ?? requestOptions;
      return r;
    }).catchError((e) {
      throw e..request = e.request ?? requestOptions;
    });
  }

  Future<Response<T>> _makeRequest<T>(
      RequestOptions options, CancelToken cancelToken) async {
    _checkCancelled(cancelToken);
    ResponseBody responseBody;
    try {
      var stream = await _transformData(options);
      responseBody = await httpClientAdapter.fetch(
        options,
        stream,
        cancelToken?.whenCancel,
      );
      if (responseBody.headers == null) {
        responseBody.headers = DioHttpHeaders();
      } else {
        responseBody.headers =
            DioHttpHeaders(initialHeaders: responseBody.headers);
      }
      Response ret = new Response(
        headers: responseBody.headers,
        request: options,
        redirects: responseBody.redirects ?? [],
        statusCode: responseBody.statusCode,
        statusMessage: responseBody.statusMessage,
        extra: responseBody.extra,
      );
      Future future;
      bool statusOk = options.validateStatus(responseBody.statusCode);
      if (statusOk || options.receiveDataWhenStatusError) {
        bool forceConvert = !(T == dynamic || T == String) &&
            !(options.responseType == ResponseType.bytes ||
                options.responseType == ResponseType.stream);
        String contentType;
        if (forceConvert) {
          contentType =
              responseBody.headers.value(HttpHeaders.contentTypeHeader);
          responseBody.headers
              .set(HttpHeaders.contentTypeHeader, ContentType.json.toString());
        }
        ret.data = await _listenCancelForAsyncTask(
            cancelToken, transformer.transformResponse(options, responseBody));
        if (forceConvert) {
          responseBody.headers.set(HttpHeaders.contentTypeHeader, contentType);
        }
      } else {
        await responseBody.stream.listen(null).cancel();
      }
      _checkCancelled(cancelToken);
      if (statusOk) {
        future = _onResponse<T>(ret);
      } else {
        throw new DioError(
          response: ret,
          message: 'Http status error [${responseBody.statusCode}]',
          type: DioErrorType.RESPONSE,
        );
      }
      return await _listenCancelForAsyncTask<Response<T>>(cancelToken, future);
    } catch (e) {
      DioError err = _assureDioError(e);
      err.request = err.request ?? options;
      if (CancelToken.isCancel(err)) {
        throw err;
      } else {
        // Response onError
        _checkCancelled(cancelToken);
        // Listen in error interceptor.
        return await _listenCancelForAsyncTask<Response<T>>(
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

  Future<Stream<Uint8List>> _transformData(RequestOptions options) async {
    var data = options.data;
    List<int> bytes;
    Stream<List<int>> stream;
    if (data != null &&
        ["POST", "PUT", "PATCH", "DELETE"].contains(options.method)) {
      // Handle the FormData
      int length;
      if (data is Stream) {
        assert(data is Stream<List>,
            "Stream type must be `Stream<List>`, but ${data.runtimeType} is found.");
        stream = data;
        options.headers.keys.any((String key) {
          if (key.toLowerCase() == HttpHeaders.contentLengthHeader) {
            length = int.parse(options.headers[key].toString());
            return true;
          }
          return false;
        });
      } else if (data is FormData) {
        if (data is FormData) {
          options.headers[HttpHeaders.contentTypeHeader] =
              'multipart/form-data; boundary=${data.boundary.substring(2)}';
        }
        stream = data.stream;
        length = data.length;
      } else {
        // Call request transformer.
        String _data = await transformer.transformRequest(options);
        if (options.requestEncoder != null) {
          bytes = options.requestEncoder(_data, options);
        } else {
          //Default convert to utf8
          bytes = utf8.encode(_data);
        }
        // support data sending progress
        length = bytes.length;

        var group = List<List<int>>();
        const size = 1024;
        int groupCount = (bytes.length / size).ceil();
        for (int i = 0; i < groupCount; ++i) {
          int start = i * size;
          group.add(bytes.sublist(start, math.min(start + size, bytes.length)));
        }
        stream = Stream.fromIterable(group);
      }

      options.headers[HttpHeaders.contentTypeHeader] ??=
          options.contentType.toString();
      if (length != null) {
        options.headers[HttpHeaders.contentLengthHeader] = length.toString();
      }
      int complete = 0;
      Stream<Uint8List> byteStream =
          stream.transform(StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (options.cancelToken != null && options.cancelToken.isCancelled) {
            sink
              ..addError(options.cancelToken.cancelError)
              ..close();
          } else {
            sink.add(Uint8List.fromList(data));
            if (length != null) {
              complete += data.length;
              if (options.onSendProgress != null) {
                options.onSendProgress(complete, length);
              }
            }
          }
        },
      ));
      if (options.sendTimeout > 0) {
        byteStream.timeout(Duration(milliseconds: options.sendTimeout),
            onTimeout: (sink) {
          sink.addError(DioError(
            request: options,
            message: "Sending timeout[${options.connectTimeout}ms]",
            type: DioErrorType.SEND_TIMEOUT,
          ));
          sink.close();
        });
      }
      return byteStream;
    }
    return null;
  }

// Transform current Future status("success" and "error") if necessary
  Future<Response<T>> _transFutureStatusIfNecessary<T>(Future future) {
    return future.then<Response<T>>((data) {
      // Strictly be a DioError instance, but we relax the restrictions
      // if (data is DioError)
      if (data is Exception) {
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
    var query = (Map<String, dynamic>.from(options.queryParameters ?? {}))
      ..addAll(queryParameters ?? {});
    final optBaseUrl = (opt is RequestOptions) ? opt.baseUrl: null;
    return RequestOptions(
      method: (opt.method ?? options.method)?.toUpperCase() ?? "GET",
      headers: (Map.from(options.headers))..addAll(opt.headers),
      baseUrl: optBaseUrl ?? options.baseUrl ?? "",
      path: url,
      data: data,
      connectTimeout: opt.connectTimeout ?? options.connectTimeout ?? 0,
      sendTimeout: opt.sendTimeout ?? options.sendTimeout ?? 0,
      receiveTimeout: opt.receiveTimeout ?? options.receiveTimeout ?? 0,
      responseType:
          opt.responseType ?? options.responseType ?? ResponseType.json,
      extra: (Map.from(options.extra))..addAll(opt.extra),
      contentType: opt.contentType ?? options.contentType ?? ContentType.json,
      validateStatus: opt.validateStatus ??
          options.validateStatus ??
          (int status) => status >= 200 && status < 300 || status == 304,
      receiveDataWhenStatusError: opt.receiveDataWhenStatusError ??
          options.receiveDataWhenStatusError ??
          true,
      followRedirects: opt.followRedirects ?? options.followRedirects ?? true,
      maxRedirects: opt.maxRedirects ?? options.maxRedirects ?? 5,
      queryParameters: query,
      cookies: List.from(options.cookies ?? [])..addAll(opt.cookies ?? []),
      requestEncoder: opt.requestEncoder??options.requestEncoder,
      responseDecoder: opt.responseDecoder??options.responseDecoder
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
    } else {
      var _err = DioError(message: err.toString(), error: err);
      if (err is Error) {
        _err.stackTrace = err.stackTrace;
      }
      return _err;
    }
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
        redirects: response.redirects,
        statusMessage: response.statusMessage,
      );
    }
    return response;
  }
}
