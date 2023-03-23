part of 'dio_mixin.dart';

/// Internal enum
/// @nodoc
enum InterceptorResultType {
  next,
  resolve,
  resolveCallFollowing,
  reject,
  rejectCallFollowing,
}

/// Internal class, It is used to pass state between current and next interceptors.
/// @nodoc
class InterceptorState<T> {
  const InterceptorState(this.data, [this.type = InterceptorResultType.next]);

  final T data;
  final InterceptorResultType type;
}

abstract class _BaseHandler {
  final _completer = Completer<InterceptorState>();
  void Function()? _processNextInQueue;

  Future<InterceptorState> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;
}

/// Handler for request interceptor.
class RequestInterceptorHandler extends _BaseHandler {
  /// Continue to call the next request interceptor.
  void next(RequestOptions requestOptions) {
    _completer.complete(InterceptorState<RequestOptions>(requestOptions));
    _processNextInQueue?.call();
  }

  /// Return the response directly! Other request interceptor(s) will not be executed,
  /// but response and error interceptor(s) may be executed, which depends on whether
  /// the value of parameter [callFollowingResponseInterceptor] is true.
  ///
  /// [response]: Response object to return.
  /// [callFollowingResponseInterceptor]: Whether to call the response interceptor(s).
  void resolve(
    Response response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    _completer.complete(
      InterceptorState<Response>(
        response,
        callFollowingResponseInterceptor
            ? InterceptorResultType.resolveCallFollowing
            : InterceptorResultType.resolve,
      ),
    );
    _processNextInQueue?.call();
  }

  /// Complete the request with an error! Other request/response interceptor(s) will not
  /// be executed, but error interceptor(s) may be executed, which depends on whether the
  /// value of parameter [callFollowingErrorInterceptor] is true.
  ///
  /// [error]: Error info to reject.
  /// [callFollowingErrorInterceptor]: Whether to call the error interceptor(s).
  void reject(DioError error, [bool callFollowingErrorInterceptor = false]) {
    _completer.completeError(
      InterceptorState<DioError>(
        error,
        callFollowingErrorInterceptor
            ? InterceptorResultType.rejectCallFollowing
            : InterceptorResultType.reject,
      ),
      error.stackTrace,
    );
    _processNextInQueue?.call();
  }
}

/// Handler for response interceptor.
class ResponseInterceptorHandler extends _BaseHandler {
  /// Continue to call the next response interceptor.
  void next(Response response) {
    _completer.complete(
      InterceptorState<Response>(response),
    );
    _processNextInQueue?.call();
  }

  /// Return the response directly! Other response i02
  void resolve(Response response) {
    _completer.complete(
      InterceptorState<Response>(
        response,
        InterceptorResultType.resolve,
      ),
    );
    _processNextInQueue?.call();
  }

  /// Complete the request with an error! Other response interceptor(s) will not
  /// be executed, but error interceptor(s) may be executed, which depends on whether the
  /// value of parameter [callFollowingErrorInterceptor] is true.
  ///
  /// [error]: Error info to reject.
  /// [callFollowingErrorInterceptor]: Whether to call the error interceptor(s).
  void reject(DioError error, [bool callFollowingErrorInterceptor = false]) {
    _completer.completeError(
      InterceptorState<DioError>(
        error,
        callFollowingErrorInterceptor
            ? InterceptorResultType.rejectCallFollowing
            : InterceptorResultType.reject,
      ),
      error.stackTrace,
    );
    _processNextInQueue?.call();
  }
}

/// Handler for error interceptor.
class ErrorInterceptorHandler extends _BaseHandler {
  /// Continue to call the next error interceptor.
  void next(DioError err) {
    _completer.completeError(
      InterceptorState<DioError>(err),
      err.stackTrace,
    );
    _processNextInQueue?.call();
  }

  /// Complete the request with Response object and other error interceptor(s) will not be executed.
  /// This will be considered a successful request!
  ///
  /// [response]: Response object to return.
  void resolve(Response response) {
    _completer.complete(
      InterceptorState<Response>(
        response,
        InterceptorResultType.resolve,
      ),
    );
    _processNextInQueue?.call();
  }

  /// Complete the request with a error directly! Other error interceptor(s) will not be executed.
  void reject(DioError error) {
    _completer.completeError(
      InterceptorState<DioError>(
        error,
        InterceptorResultType.reject,
      ),
      error.stackTrace,
    );
    _processNextInQueue?.call();
  }
}

/// Dio instance may have one or more interceptors by which you can intercept
/// requests/responses/errors before they are handled by `then` or `catchError`.
///
/// Interceptors are called once per request and response. That means that redirects
/// aren't triggering interceptors.
///
/// See also:
///  - [InterceptorsWrapper]  A helper class to create Interceptor(s).
///  - [QueuedInterceptor] Serialize the request/response/error before they enter the interceptor.
///  - [QueuedInterceptorsWrapper]  A helper class to create QueuedInterceptor(s).
class Interceptor {
  const Interceptor();

  /// The callback will be executed before the request is initiated.
  ///
  /// If you want to continue the request, call [handler.next].
  ///
  /// If you want to complete the request with some custom data，
  /// you can resolve a [Response] object with [handler.resolve].
  ///
  /// If you want to complete the request with an error message,
  /// you can reject a [DioError] object with [handler.reject].
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    handler.next(options);
  }

  /// The callback will be executed on success.
  /// If you want to continue the response, call [handler.next].
  ///
  /// If you want to complete the response with some custom data directly,
  /// you can resolve a [Response] object with [handler.resolve] and other
  /// response interceptor(s) will not be executed.
  ///
  /// If you want to complete the response with an error message,
  /// you can reject a [DioError] object with [handler.reject].
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// The callback will be executed on error.
  ///
  /// If you want to continue the error , call [handler.next].
  ///
  /// If you want to complete the response with some custom data directly,
  /// you can resolve a [Response] object with [handler.resolve] and other
  /// error interceptor(s) will be skipped.
  ///
  /// If you want to complete the response with an error message directly,
  /// you can reject a [DioError] object with [handler.reject], and other
  ///  error interceptor(s) will be skipped.
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(err);
  }
}

typedef InterceptorSendCallback = void Function(
  RequestOptions options,
  RequestInterceptorHandler handler,
);

typedef InterceptorSuccessCallback = void Function(
  Response<dynamic> e,
  ResponseInterceptorHandler handler,
);

typedef InterceptorErrorCallback = void Function(
  DioError e,
  ErrorInterceptorHandler handler,
);

mixin _InterceptorWrapperMixin on Interceptor {
  InterceptorSendCallback? _onRequest;
  InterceptorSuccessCallback? _onResponse;
  InterceptorErrorCallback? _onError;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_onRequest != null) {
      _onRequest!(options, handler);
    } else {
      handler.next(options);
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_onResponse != null) {
      _onResponse!(response, handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    if (_onError != null) {
      _onError!(err, handler);
    } else {
      handler.next(err);
    }
  }
}

/// [InterceptorsWrapper] is a helper class, which is used to conveniently
/// create interceptor(s).
/// See also:
///  - [Interceptor]
///  - [QueuedInterceptor] Serialize the request/response/error before they enter the interceptor.
///  - [QueuedInterceptorsWrapper]  A helper class to create QueuedInterceptor(s).
class InterceptorsWrapper extends Interceptor with _InterceptorWrapperMixin {
  InterceptorsWrapper({
    InterceptorSendCallback? onRequest,
    InterceptorSuccessCallback? onResponse,
    InterceptorErrorCallback? onError,
  })  : __onRequest = onRequest,
        __onResponse = onResponse,
        __onError = onError;

  @override
  InterceptorSendCallback? get _onRequest => __onRequest;
  final InterceptorSendCallback? __onRequest;

  @override
  InterceptorSuccessCallback? get _onResponse => __onResponse;
  final InterceptorSuccessCallback? __onResponse;

  @override
  InterceptorErrorCallback? get _onError => __onError;
  final InterceptorErrorCallback? __onError;
}

/// Interceptors are a queue, and you can add any number of interceptors,
/// All interceptors will be executed in first in first out order.
class Interceptors extends ListMixin<Interceptor> {
  /// Define a nullable list to be capable with growable elements.
  final List<Interceptor?> _list = [const ImplyContentTypeInterceptor()];

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  Interceptor operator [](int index) => _list[index]!;

  @override
  void operator []=(int index, Interceptor value) {
    if (_list.length == index) {
      _list.add(value);
    } else {
      _list[index] = value;
    }
  }

  /// Remove the default imply content type interceptor.
  void removeImplyContentTypeInterceptor() {
    _list.removeWhere((e) => e is ImplyContentTypeInterceptor);
  }
}

class _InterceptorParams<T, V> {
  const _InterceptorParams(this.data, this.handler);

  final T data;
  final V handler;
}

class _TaskQueue {
  final queue = Queue<_InterceptorParams>();
  bool processing = false;
}

/// Serialize the request/response/error before they enter the interceptor.
///
/// If there are multiple concurrent requests, the request is added to a queue before
/// entering the interceptor. Only one request at a time enters the interceptor, and
/// after that request is processed by the interceptor, the next request will enter
/// the interceptor.
class QueuedInterceptor extends Interceptor {
  final _TaskQueue _requestQueue = _TaskQueue();
  final _TaskQueue _responseQueue = _TaskQueue();
  final _TaskQueue _errorQueue = _TaskQueue();

  void _handleRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _handleQueue(_requestQueue, options, handler, onRequest);
  }

  void _handleResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _handleQueue(_responseQueue, response, handler, onResponse);
  }

  void _handleError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    _handleQueue(_errorQueue, err, handler, onError);
  }

  void _handleQueue<T, V extends _BaseHandler>(
    _TaskQueue taskQueue,
    T data,
    V handler,
    callback,
  ) {
    final task = _InterceptorParams<T, V>(data, handler);
    task.handler._processNextInQueue = _processNextTaskInQueueCallback(
      taskQueue,
      callback,
    );
    taskQueue.queue.add(task);
    if (!taskQueue.processing) {
      taskQueue.processing = true;
      final task = taskQueue.queue.removeFirst();
      try {
        callback(task.data, task.handler);
      } catch (e) {
        task.handler._processNextInQueue();
      }
    }
  }
}

void Function() _processNextTaskInQueueCallback(_TaskQueue taskQueue, cb) {
  return () {
    if (taskQueue.queue.isNotEmpty) {
      final next = taskQueue.queue.removeFirst();
      assert(next.handler._processNextInQueue != null);
      cb(next.data, next.handler);
    } else {
      taskQueue.processing = false;
    }
  };
}

/// [QueuedInterceptorsWrapper] is a helper class, which is used to conveniently
/// create [QueuedInterceptor]s.
///
/// See also:
///  - [Interceptor]
///  - [InterceptorsWrapper]
///  - [QueuedInterceptors]
class QueuedInterceptorsWrapper extends QueuedInterceptor
    with _InterceptorWrapperMixin {
  QueuedInterceptorsWrapper({
    InterceptorSendCallback? onRequest,
    InterceptorSuccessCallback? onResponse,
    InterceptorErrorCallback? onError,
  })  : __onRequest = onRequest,
        __onResponse = onResponse,
        __onError = onError;

  @override
  InterceptorSendCallback? get _onRequest => __onRequest;
  final InterceptorSendCallback? __onRequest;

  @override
  InterceptorSuccessCallback? get _onResponse => __onResponse;
  final InterceptorSuccessCallback? __onResponse;

  @override
  InterceptorErrorCallback? get _onError => __onError;
  final InterceptorErrorCallback? __onError;
}
