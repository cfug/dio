import 'dart:async';

import 'dio_error.dart';
import 'options.dart';
import 'response.dart';

typedef InterceptorCallback(Options options);
typedef InterceptorErrorCallback(DioError e);
typedef InterceptorsSuccessCallback(Response e);


/**
 * Add lock/unlock API for interceptor.
 */
abstract class _InterceptorBase {
  Future _lock;
  Completer _completer;

  /// Whether this interceptor has been locked.
  bool get locked => _lock != null;

  /**
   * Lock the interceptor.
   *
   * Once the request/response interceptor is locked, the incoming request/response
   * will be added to a queue  before they enter the interceptor, they will not be
   * continued until the interceptor is unlocked.
   */
  void lock() {
    if (!locked) {
      _completer = new Completer();
      _lock = _completer.future;
    }
  }

  /**
   * Unlock the interceptor. please refer to [lock()]
   */
  void unlock() {
    if (locked) {
      _completer.complete();
      _lock=null;
    }
  }

  /**
   * Clean the interceptor queue.
   */
  void clear([String msg="cancelled"]){
    if(locked) {
      _completer.completeError(msg);
      _lock = null;
    }
  }

  /**
   * If the interceptor is locked, the incoming request/response task
   * will enter a queue.
   *
   * [callback] the function  will return a `Future<Response>`
   * @nodoc
   */
  Future<Response> enqueue(Future<Response> callback()) {
    if (locked) {
      // we use a future as a queue
      return _lock.then((d) => callback());
    }
    return null;
  }
}

/**
 *  Each Dio instance has a [RequestInterceptor] and a [ResponseInterceptor],
 *  by which you can intercept requests or responses before they are
 *  handled by `then` or `catchError`.
 */
class RequestInterceptor extends _InterceptorBase {

  /// The callback will be executed before the request is initiated.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [dio.resolve].
  /// If you want to reject the request with a error message,
  /// you can return a [DioError] object or return [dio.reject] .
  /// If you want to continue the request, return the [Options] object.
  InterceptorCallback onSend;
}

class ResponseInterceptor extends _InterceptorBase {

  /// The callback will be executed on success.
  ///
  /// If you want to reject the request with a error message,
  /// you can return a [DioError] object or return [dio.reject] .
  /// If you want to continue the request, return the [Response] object.
  InterceptorsSuccessCallback onSuccess;

  /// The callback will be executed on error.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [dio.resolve].
  /// If you want to continue the request, return the [DioError] object.
  InterceptorErrorCallback onError;

}

/**
 *  Each Dio instance has a interceptor by which you can intercept
 *  requests or responses before they are handled by `then` or `catchError`.
 */
class Interceptor {
  var _request = new RequestInterceptor();
  var _response = new ResponseInterceptor();

  /// The request interceptor.
  RequestInterceptor get request => _request;

  /// The Response interceptor.
  ResponseInterceptor get response => _response;
}