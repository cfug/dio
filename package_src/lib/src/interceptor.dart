import 'dart:async';
import 'dart:collection';

import 'dio_error.dart';
import 'options.dart';
import 'response.dart';

typedef InterceptorSendCallback = dynamic Function(RequestOptions options);
typedef InterceptorErrorCallback = dynamic Function(DioError e);
typedef InterceptorSuccessCallback = dynamic Function(Response e);

/// Add lock/unlock API for interceptors.
class Lock {
  Future _lock;
  Completer _completer;

  /// Whether this interceptor has been locked.
  bool get locked => _lock != null;

  /// Lock the interceptor.
  ///
  /// Once the request/response interceptor is locked, the incoming request/response
  /// will be added to a queue  before they enter the interceptor, they will not be
  /// continued until the interceptor is unlocked.
  void lock() {
    if (!locked) {
      _completer = new Completer();
      _lock = _completer.future;
    }
  }

  /// Unlock the interceptor. please refer to [lock()]
  void unlock() {
    if (locked) {
      _completer.complete();
      _lock = null;
    }
  }

  /// Clean the interceptor queue.
  void clear([String msg = "cancelled"]) {
    if (locked) {
      _completer.completeError(msg);
      _lock = null;
    }
  }

  /// If the interceptor is locked, the incoming request/response task
  /// will enter a queue.
  ///
  /// [callback] the function  will return a `Future<Response>`
  /// @nodoc
  Future<Response> enqueue(Future<Response> callback()) {
    if (locked) {
      // we use a future as a queue
      return _lock.then((d) => callback());
    }
    return null;
  }
}

///  Dio instance may have interceptor(s) by which you can intercept
///  requests or responses before they are handled by `then` or `catchError`.
class Interceptor {
  /// The callback will be executed before the request is initiated.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [dio.resolve].
  /// If you want to reject the request with a error message,
  /// you can return a [DioError] object or return [dio.reject] .
  /// If you want to continue the request, return the [Options] object.
  onRequest(RequestOptions options) => options;

  /// The callback will be executed on success.
  ///
  /// If you want to reject the request with a error message,
  /// you can return a [DioError] object or return [dio.reject] .
  /// If you want to continue the request, return the [Response] object.
  onResponse(Response response) => response;

  /// The callback will be executed on error.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [dio.resolve].
  /// If you want to continue the request, return the [DioError] object.
  onError(DioError err) => err;
}

class InterceptorsWrapper extends Interceptor {
  final InterceptorSendCallback _onRequest;
  final InterceptorSuccessCallback _onResponse;
  final InterceptorErrorCallback _onError;

  InterceptorsWrapper({
    InterceptorSendCallback onRequest,
    InterceptorSuccessCallback onResponse,
    InterceptorErrorCallback onError,
  })  : _onRequest = onRequest,
        _onResponse = onResponse,
        _onError = onError;

  @override
  onRequest(RequestOptions options) {
    if (_onRequest != null) {
      return _onRequest(options);
    }
  }

  @override
  onResponse(Response response) {
    if (_onResponse != null) {
      return _onResponse(response);
    }
  }

  @override
  onError(DioError err) {
    if (_onError != null) {
      return _onError(err);
    }
  }
}

class Interceptors extends ListMixin<Interceptor> {
  List<Interceptor> _list = new List();

  Lock _requestLock = new Lock();
  Lock _responseLock = new Lock();
  Lock _errorLock = new Lock();

  Lock get requestLock => _requestLock;

  Lock get responseLock => _responseLock;

  Lock get errorLock => _errorLock;

  @override
  int length = 0;

  @override
  operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, value) {
    if (_list.length == index) {
      _list.add(value);
    } else {
      _list[index] = value;
    }
  }
}
