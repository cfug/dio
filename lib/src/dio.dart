import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'cancel_token.dart';
import 'form_data.dart';
import 'dio_error.dart';
import 'interceptor.dart';
import 'options.dart';
import 'response.dart';
import 'transformer.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// Callback to listen the file downloading progress.
///
/// [received] is the length of the bytes have been received.
///
/// [total] is the content length of the response body. Returns -1 if
/// the size of the response body is not known in advance,
/// such as response data is compressed with gzip.
typedef OnDownloadProgress(int received, int total);

typedef dynamic OnHttpClientCreate(HttpClient client);

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

  /// Cookie manager for http requests。Learn more details about
  /// CookieJar please refer to [cookie_jar](https://github.com/flutterchina/cookie_jar)
  CookieJar cookieJar = new CookieJar();

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

  /// [transformer] allows changes to the request/response data before it is sent/received to/from the server
  /// This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
  Transformer transformer = new DefaultTransformer();

  /// Handy method to make http GET request, which is a alias of  [Dio.request].
  Future<Response<T>> get<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request<T>(path,
        data: data,
        options: _checkOptions("GET", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http POST request, which is a alias of  [Dio.request].
  Future<Response<T>> post<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request<T>(path,
        data: data,
        options: _checkOptions("POST", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http PUT request, which is a alias of  [Dio.request].
  Future<Response<T>> put<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request<T>(path,
        data: data,
        options: _checkOptions("PUT", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http HEAD request, which is a alias of  [Dio.request].
  Future<Response<T>> head<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path,
        data: data,
        options: _checkOptions("HEAD", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http DELETE request, which is a alias of  [Dio.request].
  Future<Response<T>> delete<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path,
        data: data,
        options: _checkOptions("DELETE", options),
        cancelToken: cancelToken);
  }

  /// Handy method to make http PATCH request, which is a alias of  [Dio.request].
  Future<Response<T>> patch<T>(String path,
      {data, Options options, CancelToken cancelToken}) {
    return request(path,
        data: data,
        options: _checkOptions("PATCH", options),
        cancelToken: cancelToken);
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
   * Clear the current Dio instance waiting queue.
   */
  clear() {
    interceptor.request.clear();
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
   */
  Future<Response> download(
    String urlPath,
    savePath, {
    OnDownloadProgress onProgress,
    CancelToken cancelToken,
    data,
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
    httpClient = _configHttpClient(httpClient);

    // Receive data with stream.
    options.responseType = ResponseType.STREAM;

    Response<HttpClientResponse> response = await _request(urlPath,
        data: data,
        options: options,
        cancelToken: cancelToken,
        httpClient: httpClient);

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
    Stream<List<int>> stream = response.data;
    // Handle  timeout
    if (options.receiveTimeout > 0) {
      stream = response.data.timeout(
        new Duration(milliseconds: options.receiveTimeout),
        onTimeout: (EventSink sink) {
          sink.addError(new DioError(
              message: "Receiving data timeout[${options.receiveTimeout}ms]",
              type: DioErrorType.RECEIVE_TIMEOUT));
          sink.close();
        },
      );
    }

    stream.listen(
      (data) {
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
   * Make http request with options.
   *
   * [path] The url path.
   * [data] The request data
   * [options] The request options.
   */
  Future<Response<T>> request<T>(
    String path, {
    data,
    CancelToken cancelToken,
    Options options,
  }) async {
    var httpClient = _httpClient;
    if (cancelToken != null) {
      httpClient = _configHttpClient(new HttpClient());
    } else if (!_httpClientInited) {
      _httpClient = httpClient = _configHttpClient(_httpClient, true);
      _httpClientInited = true;
    }
    return _request<T>(path,
        data: data,
        cancelToken: cancelToken,
        options: options,
        httpClient: httpClient);
  }

  HttpClient _configHttpClient(HttpClient httpClient,
      [bool isDefault = false]) {
    httpClient.idleTimeout = new Duration(seconds: isDefault ? 3 : 0);
    if (onHttpClientCreate != null) {
      //user can return a new HttpClient instance
      httpClient = onHttpClientCreate(httpClient) ?? httpClient;
    }
    return httpClient;
  }

  Future<Response<T>> _request<T>(String path,
      {data,
      CancelToken cancelToken,
      Options options,
      HttpClient httpClient}) async {
    Future<Response<T>> future =
        _checkIfNeedEnqueue<T>(interceptor.request, () {
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
        Future<Response<T>> future;
        //todo here test results are inconsistent between Dart VM and flutter.
        //https://github.com/dart-lang/sdk/issues/33000
        if (ret is Future<Response>) {
          future = ret;
        } else {
          future = ret.then<Response<T>>((data) {
            FutureOr<Response<T>> response;
            // If the Future value type is Options, continue the network request.
            if (data is Options) {
              options.method = data.method.toUpperCase();
              response = _makeRequest<T>(data, cancelToken, httpClient);
            } else {
              // Otherwise, use the Future value as the request result.
              // If the return type is Error, we should throw it
              if (data is Error) {
                throw _assureDioError(data);
              }
              response = _assureResponse(data);
            }
            return response;
          });
        }
        return future.catchError((err) => throw _assureDioError(err));
      } else {
        // If user don't provide the request interceptor, make request directly.
        return _makeRequest<T>(options, cancelToken, httpClient);
      }
    });
    return _listenCancelForAsyncTask<Response<T>>(cancelToken, future)
        .then((d) {
      if (cancelToken != null) {
        httpClient.close();
      }
      return d;
    });
  }

  Future<Response<T>> _makeRequest<T>(Options options, CancelToken cancelToken,
      [HttpClient httpClient]) async {
    _checkCancelled(cancelToken);
    HttpClientResponse response;
    try {
      // Normalize the url.
      String url = options.path;
      if (!url.startsWith(new RegExp(r"https?:"))) {
        url = options.baseUrl + url;
        List<String> s = url.split(":/");
        url = s[0] + ':/' + s[1].replaceAll("//", "/");
      }
      options.method = options.method.toUpperCase();
      bool isGet = options.method == "GET";
      if (isGet && options.data is Map) {
        url += (url.contains("?") ? "&" : "?") +
            Transformer.urlEncodeMap(options.data);
      }
      Uri uri = Uri.parse(url).normalizePath();
      Future requestFuture;
      // Handle timeout
      if (options.connectTimeout > 0) {
        requestFuture = httpClient
            .openUrl(options.method, uri)
            .timeout(new Duration(milliseconds: options.connectTimeout));
      } else {
        requestFuture = httpClient.openUrl(options.method, uri);
      }
      HttpClientRequest request;
      try {
        request = await _listenCancelForAsyncTask(cancelToken, requestFuture);
      } on TimeoutException {
        throw new DioError(
          message: "Connecting timeout[${options.connectTimeout}ms]",
          type: DioErrorType.CONNECT_TIMEOUT,
        );
      }
      request.followRedirects = options.followRedirects;
      request.cookies.addAll(cookieJar.loadForRequest(uri));

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

      response = await _listenCancelForAsyncTask(cancelToken, request.close());
      cookieJar.saveFromResponse(uri, response.cookies);

      var retData = await _listenCancelForAsyncTask(
          cancelToken, transformer.transformResponse(options, response));

      Response ret = new Response(
          data: retData,
          headers: response.headers,
          request: options,
          statusCode: response.statusCode);

      Future<Response<T>> future =
          _checkIfNeedEnqueue<T>(interceptor.response, () {
        _checkCancelled(cancelToken);
        if (options.validateStatus(response.statusCode)) {
          return _listenCancelForAsyncTask<Response<T>>(
              cancelToken, _onSuccess<T>(ret));
        } else {
          var err = new DioError(
            response: ret,
            message: 'Http status error [${response.statusCode}]',
            type: DioErrorType.RESPONSE,
          );
          return _listenCancelForAsyncTask<Response<T>>(
              cancelToken, _onError(err));
        }
      });
      return _listenCancelForAsyncTask<Response<T>>(cancelToken, future);
    } catch (e) {
      DioError err = _assureDioError(e);
      if (CancelToken.isCancel(err)) {
        httpClient.close(force: true);
        throw err;
      } else {
        // Response onError
        Future<Response<T>> future =
            _checkIfNeedEnqueue<T>(interceptor.response, () {
          _checkCancelled(cancelToken);
          // Listen in error interceptor.
          return _listenCancelForAsyncTask<Response<T>>(
              cancelToken, _onError(err));
        });
        // Listen if in the queue.
        return _listenCancelForAsyncTask<Response<T>>(cancelToken, future);
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

  _transformData(Options options, HttpClientRequest request) async {
    var data = options.data;
    List<int> bytes;
    if (data != null) {
      if (["POST", "PUT", "PATCH"].contains(options.method)) {
        // Handle the FormData
        if (data is FormData) {
          request.headers.set(HttpHeaders.contentTypeHeader,
              'multipart/form-data; boundary=${data.boundary.substring(2)}');
          bytes = data.bytes();
          //Must set the content-length
          request.contentLength = bytes.length;
          _setHeaders(options, request);
          request.add(bytes);
          return;
        }
      }
      options.headers[HttpHeaders.contentTypeHeader] =
          options.contentType.toString();

      // If Byte Array
      if (options.data is List<int>) {
        bytes = options.data;
      } else {
        // Call request transformer.
        String _data = await transformer.transformRequest(options);

        // Set the headers, must before `request.write`
        _setHeaders(options, request);

        // Convert to utf8
        bytes = utf8.encode(_data);
      }

      // Set Content-Length
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);

      request.add(bytes);
    } else {
      _setHeaders(options, request);
    }
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

  Future<Response<T>> _onSuccess<T>(response) {
    if (interceptor.response.onSuccess != null) {
      response = interceptor.response.onSuccess(response) ?? response;
    }
    if (response is! Future) {
      // Assure response is a Future
      response = new Future.value(response);
    }
    return _transFutureStatusIfNecessary<T>(response);
  }

  Future<Response<T>> _onError<T>(err) {
    if (interceptor.response.onError != null) {
      err = interceptor.response.onError(err) ?? err;
    }
    if (err is! Future) {
      err = new Future.error(err);
    }
    return _transFutureStatusIfNecessary<T>(err);
  }

  void _mergeOptions(Options opt) {
    opt.method ??= options.method ?? "GET";
    opt.method = opt.method.toUpperCase();
    opt.headers = (new Map.from(options.headers))..addAll(opt.headers);
    opt.baseUrl ??= options.baseUrl ?? "";
    opt.connectTimeout ??= options.connectTimeout ?? 0;
    opt.receiveTimeout ??= options.receiveTimeout ?? 0;
    opt.responseType ??= options.responseType ?? ResponseType.JSON;
    opt.data ??= options.data;
    opt.extra = (new Map.from(options.extra))..addAll(opt.extra);
    opt.contentType ??= options.contentType ?? ContentType.json;
    opt.validateStatus ??= options.validateStatus ??
        (int status) => status >= 200 && status < 300 || status == 304;
    opt.followRedirects ??= options.followRedirects ?? true;
  }

  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
    }
    options.method = method;
    return options;
  }

  Future<Response<T>> _checkIfNeedEnqueue<T>(interceptor, callback()) {
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

  void _setHeaders(Options options, HttpClientRequest request) {
    options.headers.forEach((k, v) => request.headers.set(k, v));
  }
}
