import 'dart:async';
import 'dart:io';
import 'package:dio/src/CancelToken.dart';
import 'package:dio/src/FormData.dart';
import 'package:dio/src/DioError.dart';
import 'package:dio/src/Interceptor.dart';
import 'package:dio/src/Options.dart';
import 'package:dio/src/Response.dart';
import 'package:dio/src/TransFormer.dart';

/// Callback to listen the file downloading progress.
///
/// [received] is the length of the bytes have been received.
///
/// [total] is the content length of the response body. Returns -1 if
/// the size of the response body is not known in advance,
/// such as response data is compressed with gzip.
typedef OnDownloadProgress(int received, int total);

typedef OnHttpClientCreate(HttpClient client);

/// A powerful Http client for Dart, which supports Interceptors,
/// Global configuration, FormData, File downloading etc. and Dio is
/// very easy to use.
class Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  Dio([Options options]) {
    if (options == null) {
      options = new Options();
    }
    this.options = options;
  }

  /// The Dio version.
  static const version = "0.0.4";

  /// Default Request config. More see [Options] .
  Options options;

  /// [Dio] will create new HttpClient when it is needed.
  /// If [onHttpClientCreate] is provided, [Dio] will call
  /// it when a new HttpClient created.
  OnHttpClientCreate onHttpClientCreate;

  bool _httpClientInited = false;
  HttpClient _httpClient = new HttpClient();

  /// Each Dio instance has a interceptor by which you can intercept requests or responses before they are
  /// handled by `then` or `catchError`. the [interceptor] field
  /// contains a [RequestInterceptor] and a [ResponseInterceptor] instance.
  Interceptor get interceptor => _interceptor;

  var _interceptor = new Interceptor();

  /// [TransFormer] allows changes to the request/response data before it is sent/received to/from the server
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
  TransFormer transFormer = new DefaultTransformer();

  /// Handy method to make http GET request, which is a alias of  [Dio.request].
  Future<Response> get(path, {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("GET", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response> post(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("POST", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response> put(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("PUT", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http HEAD request, which is a alias of  [Dio.request].
  Future<Response> head(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("HEAD", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http DELETE request, which is a alias of  [Dio.request].
  Future<Response> delete(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("DELETE", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http PATCH request, which is a alias of  [Dio.request].
  Future<Response> patch(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path, data: data,
        options: _checkOptions("PATCH", options),
        cancelToken: cancelToken);
  }

  /// Assure the final future state is succeed!
  Future<Response> resolve(response) {
    if (response is! Future) {
      response = new Future.value(response);
    }
    return response.then((data) {
      return _assureResponse(data);
    }, onError: (err) {
      // transform "error" to "success"
      return _assureResponse(err);
    });
  }

  /// Assure the final future state is failed!
  Future<Response> reject(err) {
    if (err is! Future) {
      err = new Future.error(err);
    }
    return err.then((v) {
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
    interceptor.request.lock();
  }

  /**
   * Unlock the current Dio instance.
   *
   * Dio instance dequeue the request task。
   */
  unlock() {
    interceptor.request.unlock();
  }

  /**
   * Download the file and save it in local. The default http method is "GET",
   * you can custom it by [Options.method].
   *
   * [urlPath]: The file url.
   *
   * [savePath]: The path to save the downloading file later.
   *
   * If the [flush] argument is set to `true` data written will be
   * flushed to the file system before returning.
   *
   * [onProgress]: The callback to listen downloading progress.
   * please refer to [OnDownloadProgress].
   *
   */
  Future<Response> download(String urlPath,
      savePath, {
        OnDownloadProgress onProgress,
        CancelToken cancelToken,
        data,
        bool flush: false,
        Options options,
      }) async {
    // We set the `responseType` to [ResponseType.STREAM] to retrieve the
    // response stream.
    if (options != null) {
      options.method ?? "GET";
    } else {
      options = _checkOptions("GET", options);
    }

    HttpClient httpClient = new HttpClient();
    _configHttpClient(httpClient);

    // Receive data with stream.
    options.responseType = ResponseType.STREAM;

    Response<HttpClientResponse> response =
    await _request(urlPath, data: data,
        options: options, cancelToken: cancelToken, httpClient: httpClient);

    File file = new File(savePath);

    // Shouldn't call file.writeAsBytesSync(list, flush: flush),
    // because it can write all bytes by once. Consider that the
    // file with a very big size(up 1G), it will be expensive in memory.
    var raf = file.openSync(mode: FileMode.WRITE);

    //Create a new Completer to notify the success/error state.
    Completer completer = new Completer();
    Future future = completer.future;
    int received = 0;

    // Stream<List<int>>
    Stream<List<int>> stream = response.data;
    // Handle  timeout
    if (options.receiveTimeout > 0) {
      stream = response.data.timeout(
        new Duration(
            milliseconds: options.receiveTimeout),
        onTimeout: (EventSink sink) {
          print("");
          return new Future<Response>
              .error(new DioError(
              message: "Receiving data timeout[${options.receiveTimeout}ms]",
              type: DioErrorType.RECEIVE_TIMEOUT
          ));
        },
      );
    }

    stream.listen((data) {
      // Check if cancelled.
      if (cancelToken != null && cancelToken.cancelError != null) {
        httpClient.close(force: true);
        return;
      }
      // Write file.
      raf.writeFromSync(data);
      // Notify progress
      received += data.length;
      if (onProgress != null) {
        onProgress(received, response.data.contentLength);
      }
    }, onDone: () {
      raf.closeSync();
      completer.complete();
    },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(_assureDioError(e));
      },
      cancelOnError: true,
    );
    return future;
  }

  /**
   * Make http request with options.
   *
   * [path] The url path.
   * [data] The request data
   * [options] The request options.
   */
  Future<Response> request(String path, {data,
    CancelToken cancelToken,
    Options options,
  }) async {
    var httpClient = _httpClient;
    if (cancelToken != null) {
      httpClient = new HttpClient();
      _configHttpClient(httpClient);
    } else if (!_httpClientInited) {
      _configHttpClient(httpClient, true);
      _httpClientInited = true;
    }
    return _request(path,
        data: data,
        cancelToken: cancelToken,
        options: options,
        httpClient: httpClient
    );
  }

  _configHttpClient(HttpClient httpClient, [bool isDefault = false]) {
    httpClient.idleTimeout = new Duration(seconds: isDefault ? 3 : 0);
    if (onHttpClientCreate != null) {
      onHttpClientCreate(httpClient);
    }
  }

  Future<Response> _request(String path,
      {data, CancelToken cancelToken, Options options, HttpClient httpClient}) async {
    Future<Response> future = _checkIfNeedEnqueue(interceptor.request, () {
      _mergeOptions(options);
      options.data = data ?? options.data;
      options.path = path;
      // If user provide a request interceptor, enter the interceptor.
      InterceptorCallback preSend = interceptor.request.onSend;
      if (preSend != null) {
        _checkCancelled(cancelToken);
        var ret = preSend(options);
        // Assure the return value type of request interceptor is `Future`.
        if (ret is! Future) {
          ret = new Future.value(ret);
        }
        return ret.then((_options) {
          options.method = options.method.toUpperCase();
          // If the Future value type is Options, continue the network request.
          if (_options is Options) {
            return _makeRequest(_options, cancelToken, httpClient);
          } else {
            // Otherwise, use the Future value as the request result.
            // If the return type is Error, we should throw it
            if (_options is Error) {
              throw _assureDioError(_options);
            }
            return _assureResponse(_options);
          }
        }).catchError((err) => throw _assureDioError(err));
      } else {
        // If user don't provide the request interceptor, make request directly.
        return _makeRequest(options, cancelToken, httpClient);
      }
    });
    return _listenCancelForAsyncTask(cancelToken, future).then((d) {
      if (cancelToken != null) {
        httpClient.close();
      }
      return d;
    });
  }

  Future<Response> _makeRequest(Options options,
      CancelToken cancelToken, [HttpClient httpClient]) async {
    _checkCancelled(cancelToken);
    HttpClientResponse response;
    try {
      // Normalize the url.
      String url = options.path;
      if (!url.startsWith("http")) {
        url = options.baseUrl + url;
        List<String> s = url.split(":/");
        url = s[0] + ':/' + s[1].replaceAll("//", "/");
      }
      options.method = options.method.toUpperCase();
      bool isGet = options.method == "GET";
      if (isGet && options.data is Map) {
        url += (url.contains("?") ? "&" : "?") +
            TransFormer.urlEncodeMap(options.data);
      }
      Uri uri = Uri.parse(url);

      Future<HttpClientRequest> requestFuture;

      // Handle timeout
      if (options.connectTimeout > 0) {
        requestFuture = httpClient.openUrl(options.method, uri)
            .timeout(
            new Duration(milliseconds: options.connectTimeout),
            onTimeout: () {
              return new Future<HttpClientRequest>.error(new DioError(
                message: "Connecting timeout[${options.connectTimeout}ms]",
                type: DioErrorType.CONNECT_TIMEOUT,
              ));
            });
      } else {
        requestFuture = httpClient.openUrl(options.method, uri);
      }

      // Open the url.
      HttpClientRequest request = await _listenCancelForAsyncTask(
          cancelToken, requestFuture);

      try {
        if (!isGet) {
          // Transform the request data, set headers inner.
          await _listenCancelForAsyncTask(
              cancelToken, _transformData(options, request));
        } else {
          _setHeaders(options, request);
        }
      } catch (e) {
        //If user cancel  the request in transformer, close the connect by hand.
        request.addError(e);
      }

      response = await _listenCancelForAsyncTask(
          cancelToken, request.close());
      //
      var retData = await _listenCancelForAsyncTask(cancelToken,
          transFormer.transformResponse(options, response));

      Response ret = new Response(
          data: retData,
          headers: response.headers,
          request: options,
          statusCode: response.statusCode);

      Future<Response> future = _checkIfNeedEnqueue(interceptor.response, () {
        _checkCancelled(cancelToken);
        if ((response.statusCode >= HttpStatus.OK &&
            response.statusCode < HttpStatus.MULTIPLE_CHOICES) ||
            response.statusCode == HttpStatus.NOT_MODIFIED) {
          return _listenCancelForAsyncTask(cancelToken, _onSuccess(ret));
        } else {
          var err = new DioError(
            response: ret,
            message: 'Http status error [${response.statusCode}]',
            type: DioErrorType.RESPONSE,
          );
          return _listenCancelForAsyncTask(cancelToken, _onError(err));
        }
      });
      return _listenCancelForAsyncTask(cancelToken, future);
    } catch (e) {
      DioError err = _assureDioError(e);
      if (CancelToken.isCancel(err)) {
        httpClient.close(force: true);
        throw err;
      } else {
        // Response onError
        Future<Response> future = _checkIfNeedEnqueue(interceptor.response, () {
          _checkCancelled(cancelToken);
          // Listen in error interceptor.
          return _listenCancelForAsyncTask(
              cancelToken, _onError(err));
        });
        // Listen if in the queue.
        return _listenCancelForAsyncTask(cancelToken, future);
      }
    }
  }

  // If the request has been cancelled, stop request and throw error.
  _checkCancelled(CancelToken cancelToken) {
    if (cancelToken != null && cancelToken.cancelError != null) {
      throw cancelToken.cancelError;
    }
  }

  Future _listenCancelForAsyncTask(CancelToken cancelToken, Future future) {
    Completer<HttpClientRequest> completer = new Completer();
    if (cancelToken != null && cancelToken.cancelError == null) {
      cancelToken.addCompleter(completer);
      return Future.any([completer.future, future]).then((result) {
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

  _transformData(Options options, HttpClientRequest request) async {
    var data = options.data;
    if (data != null) {
      if ("POST" == options.method) {
        // Handle the FormData
        if (data is FormData) {
          request.headers.set(HttpHeaders.CONTENT_TYPE,
              'multipart/form-data; ${data.boundary}');
          List<int> content = data.bytes();
          //Must set the content-length
          request.contentLength = content.length;
          _setHeaders(options, request);
          request.add(content);
          return;
        }
      }
      options.headers[HttpHeaders.CONTENT_TYPE] =
          options.contentType.toString();

      // Call request transformer.
      data = await transFormer.transformRequest(options);

      // Set the headers, must before `request.write`
      _setHeaders(options, request);

      request.write(data);
    }
  }

// Transform current Future status("success" and "error") if necessary
  Future _transFutureStatusIfNecessary(Future future) {
    return future.then((data) {
      // Strictly be a DioError instance, but we loos the restrictions
      //if (data is DioError)
      if (data is Error) {
        return reject(data);
      }
      return resolve(data);
    }, onError: (err) {
      if (err is Response) {
        return resolve(err);
      }
      return reject(err);
    });
  }

  Future<Response> _onSuccess(response) {
    if (interceptor.response.onSuccess != null) {
      response = interceptor.response.onSuccess(response) ?? response;
      if (response is! Future) {
        // Assure response is a Future
        response = new Future.value(response);
      }
      return _transFutureStatusIfNecessary(response);
    }

    if (response is! Future) {
      // Assure response is a Future
      response = resolve(response);
    }
    return response;
  }

  Future<Response> _onError(err) {
    if (interceptor.response.onError != null) {
      err = interceptor.response.onError(err) ?? err;
      if (err is! Future) {
        // Assure err is a Future
        err = new Future.error(err);
      }
      return _transFutureStatusIfNecessary(err);
    }
    if (err is! Future) {
      err = new Future.error(err);
    }
    return err;
  }

  _mergeOptions(Options opt) {
    opt.method ??= options.method ?? "GET";
    opt.method = opt.method.toUpperCase();
    opt.headers.addAll(options.headers);
    opt.baseUrl ??= options.baseUrl ?? "";
    opt.connectTimeout ??= options.connectTimeout ?? 0;
    opt.receiveTimeout ??= options.receiveTimeout ?? 0;
    opt.responseType ??= options.responseType ?? ResponseType.JSON;
    opt.data ??= options.data;
    opt.extra.addAll(options.extra);
    opt.contentType ??= options.contentType ?? ContentType.JSON;
  }

  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
    }
    options.method = method;
    return options;
  }

  _checkIfNeedEnqueue(interceptor, callback()) {
    if (interceptor.locked) {
      return interceptor.enqueue(callback);
    } else {
      return callback();
    }
  }

  DioError _assureDioError(err) {
    if (err is DioError) {
      return err;
    } else if (err is Error) {
      err = new DioError(
          response: null,
          message: err.toString(),
          stackTrace: err.stackTrace);
    } else {
      err = new DioError(message: err.toString());
    }
    return err;
  }

  Response _assureResponse(response) {
    if (response is! Response) {
      response = new Response(data: response);
    }
    return response;
  }

  void _setHeaders(Options options, HttpClientRequest request) {
    options.headers.forEach((k, v) => request.headers.set(k, v));
  }

}
