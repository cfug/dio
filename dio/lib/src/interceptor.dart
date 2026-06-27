part of 'dio_mixin.dart';

/// The result type after handled by the interceptor.
enum InterceptorResultType {
  next,
  resolve,
  resolveCallFollowing,
  reject,
  rejectCallFollowing,
}

/// Used to pass state between interceptors.
class InterceptorState<T> {
  const InterceptorState(this.data, [this.type = InterceptorResultType.next]);

  final T data;
  final InterceptorResultType type;

  @override
  String toString() => 'InterceptorState<$T>(type: $type, data: $data)';
}

abstract class _BaseHandler {
  final _completer = Completer<InterceptorState>();
  void Function()? _processNextInQueue;

  @protected
  Future<InterceptorState> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void _throwIfCompleted() {
    if (_completer.isCompleted) {
      throw StateError(
        'The `handler` has already been called, '
        'make sure each handler gets called only once.',
      );
    }
  }
}

/// The handler for interceptors to handle before the request has been sent.
class RequestInterceptorHandler extends _BaseHandler {
  /// Deliver the [requestOptions] to the next interceptor.
  ///
  /// Typically, the method should be called once interceptors done
  /// manipulating the [requestOptions].
  void next(RequestOptions requestOptions) {
    _throwIfCompleted();
    _completer.complete(InterceptorState<RequestOptions>(requestOptions));
    _processNextInQueue?.call();
  }

  /// Completes the request by resolves the [response] as the result.
  ///
  /// Invoking the method will make the rest of interceptors in the queue
  /// skipped to handle the request,
  /// unless [callFollowingResponseInterceptor] is true
  /// which delivers [InterceptorResultType.resolveCallFollowing]
  /// to the [InterceptorState].
  void resolve(
    Response response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    _throwIfCompleted();
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

  /// Completes the request by reject with the [error] as the result.
  ///
  /// Invoking the method will make the rest of interceptors in the queue
  /// skipped to handle the request,
  /// unless [callFollowingErrorInterceptor] is true
  /// which delivers [InterceptorResultType.rejectCallFollowing]
  /// to the [InterceptorState].
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    _throwIfCompleted();
    _completer.completeError(
      InterceptorState<DioException>(
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

/// The handler for interceptors to handle after respond.
class ResponseInterceptorHandler extends _BaseHandler {
  /// Deliver the [response] to the next interceptor.
  ///
  /// Typically, the method should be called once interceptors done
  /// manipulating the [response].
  void next(Response response) {
    _throwIfCompleted();
    _completer.complete(
      InterceptorState<Response>(response),
    );
    _processNextInQueue?.call();
  }

  /// Completes the request by resolves the [response] as the result.
  void resolve(Response response) {
    _throwIfCompleted();
    _completer.complete(
      InterceptorState<Response>(
        response,
        InterceptorResultType.resolve,
      ),
    );
    _processNextInQueue?.call();
  }

  /// Completes the request by reject with the [error] as the result.
  ///
  /// Invoking the method will make the rest of interceptors in the queue
  /// skipped to handle the request,
  /// unless [callFollowingErrorInterceptor] is true
  /// which delivers [InterceptorResultType.rejectCallFollowing]
  /// to the [InterceptorState].
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    _throwIfCompleted();
    _completer.completeError(
      InterceptorState<DioException>(
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

/// The handler for interceptors to handle error occurred during the request.
class ErrorInterceptorHandler extends _BaseHandler {
  /// Deliver the [error] to the next interceptor.
  ///
  /// Typically, the method should be called once interceptors done
  /// manipulating the [error].
  void next(DioException error) {
    _throwIfCompleted();
    _completer.completeError(
      InterceptorState<DioException>(error),
      error.stackTrace,
    );
    _processNextInQueue?.call();
  }

  /// Completes the request by resolves the [response] as the result.
  void resolve(Response response) {
    _throwIfCompleted();
    _completer.complete(
      InterceptorState<Response>(
        response,
        InterceptorResultType.resolve,
      ),
    );
    _processNextInQueue?.call();
  }

  /// Completes the request by reject with the [error] as the result.
  ///
  /// Invoking the method will make the rest of interceptors in the queue
  /// skipped to handle the request,
  /// unless [callFollowingErrorInterceptor] is true
  /// which delivers [InterceptorResultType.rejectCallFollowing]
  /// to the [InterceptorState].
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    _throwIfCompleted();
    _completer.completeError(
      InterceptorState<DioException>(
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

/// [Interceptor] helps to deal with [RequestOptions], [Response],
/// and [DioException] during the lifecycle of a request
/// before it reaches users.
///
/// Interceptors are called once per request and response,
/// that means redirects aren't triggering interceptors.
///
/// See also:
///  - [InterceptorsWrapper], the helper class to create [Interceptor]s.
///  - [QueuedInterceptor], resolves interceptors as a task in the queue.
///  - [QueuedInterceptorsWrapper],
///    the helper class to create [QueuedInterceptor]s.
class Interceptor {
  /// The constructor only helps sub-classes to inherit from.
  /// Do not use it directly.
  const Interceptor();

  /// Called when the request is about to be sent.
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    handler.next(options);
  }

  /// Called when the response is about to be resolved.
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Called when an exception was occurred during the request.
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(err);
  }
}

/// The signature of [Interceptor.onRequest].
typedef InterceptorSendCallback = void Function(
  RequestOptions options,
  RequestInterceptorHandler handler,
);

/// The signature of [Interceptor.onResponse].
typedef InterceptorSuccessCallback = void Function(
  Response<dynamic> response,
  ResponseInterceptorHandler handler,
);

/// The signature of [Interceptor.onError].
typedef InterceptorErrorCallback = void Function(
  DioException error,
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
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (_onError != null) {
      _onError!(err, handler);
    } else {
      handler.next(err);
    }
  }
}

/// A helper class to create interceptors in ease.
///
/// See also:
///  - [QueuedInterceptorsWrapper], creates [QueuedInterceptor]s in ease.
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

/// A Queue-Model list for [Interceptor]s.
///
/// Interceptors will be executed with FIFO.
class Interceptors extends ListMixin<Interceptor> {
  Interceptors({
    List<Interceptor> initialInterceptors = const <Interceptor>[],
  }) {
    addAll(initialInterceptors);
  }

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

  /// The default [ImplyContentTypeInterceptor] will be removed only if
  /// [keepImplyContentTypeInterceptor] is false.
  @override
  void clear({bool keepImplyContentTypeInterceptor = true}) {
    if (keepImplyContentTypeInterceptor) {
      _list.removeWhere((e) => e is! ImplyContentTypeInterceptor);
    } else {
      super.clear();
    }
  }

  /// Remove the default imply content type interceptor.
  void removeImplyContentTypeInterceptor() {
    _list.removeWhere((e) => e is ImplyContentTypeInterceptor);
  }
}

class _InterceptorParams<T, V extends _BaseHandler> {
  const _InterceptorParams(this.data, this.handler);

  final T data;
  final V handler;
}

class _TaskQueue<T, V extends _BaseHandler> {
  final queue = Queue<_InterceptorParams<T, V>>();
  bool processing = false;
}

/// [Interceptor] in queue.
///
/// `onRequest`, `onResponse`, and `onError` are processed in separate queues
/// when running concurrent requests. These queues run in parallel,
/// new requests can be initiated before previous have been completed.
class QueuedInterceptor extends Interceptor {
  final _requestQueue = _TaskQueue<RequestOptions, RequestInterceptorHandler>();
  final _responseQueue = _TaskQueue<Response, ResponseInterceptorHandler>();
  final _errorQueue = _TaskQueue<DioException, ErrorInterceptorHandler>();

  void _handleRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _handleQueue(
      _requestQueue,
      options,
      handler,
      onRequest,
      (e, handler) {
        final error = DioMixin.assureDioException(e, options);
        handler.reject(error, true);
      },
    );
  }

  void _handleResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _handleQueue(
      _responseQueue,
      response,
      handler,
      onResponse,
      (e, handler) {
        final error = DioMixin.assureDioException(e, response.requestOptions);
        handler.reject(error, true);
      },
    );
  }

  void _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    _handleQueue(
      _errorQueue,
      error,
      handler,
      onError,
      (e, handler) {
        final err = DioMixin.assureDioException(e, error.requestOptions);
        handler.next(err);
      },
    );
  }

  void _handleQueue<T, V extends _BaseHandler>(
    _TaskQueue<T, V> taskQueue,
    T data,
    V handler,
    void Function(T, V) callback,
    void Function(Object, V) onError,
  ) {
    // Runs [task] as the active task and wires up how the queue advances to
    // the next task once this one is done.
    void runTask(_InterceptorParams<T, V> task) {
      // Hold the task in a clearable reference so that the `whenCancel`
      // closure registered below — which cannot be detached from the
      // [CancelToken]'s internal completer — stops pinning the request
      // payload ([RequestOptions]/[Response]/[DioException] and its handler)
      // once the queue has advanced. The closure observes `taskRef == null`
      // and then holds only a null reference, so for a [CancelToken] shared
      // across many requests (a supported usage pattern documented on
      // [CancelToken]) per-task allocations are released as each task
      // completes, instead of accumulating until the token is cancelled.
      //
      // A `WeakReference` is intentionally NOT used here: while a task is the
      // active one, this cell is its only strong reference (the queue has
      // already removed it and the pending callback captured `task.data`/
      // `task.handler`, not the wrapper). A weak reference could be collected
      // mid-flight, so a later cancellation would see a null target, skip
      // `advance()`, and never release the queue slot — reintroducing the stall
      // this guards against. The clearable cell keeps the task reachable for
      // exactly as long as it is active and releases it deterministically when
      // `advance()` runs.
      _InterceptorParams<T, V>? taskRef = task;

      // Advancing the queue must happen exactly once per task: either when the
      // handler is completed (next/resolve/reject) or when the request is
      // cancelled before the handler is ever called. `advanced` guards against
      // both paths firing for the same task.
      bool advanced = false;
      void advance() {
        if (advanced) {
          return;
        }
        advanced = true;
        taskRef = null;
        if (taskQueue.queue.isNotEmpty) {
          runTask(taskQueue.queue.removeFirst());
        } else {
          taskQueue.processing = false;
        }
      }

      task.handler._processNextInQueue = advance;

      // If the request is cancelled while the interceptor callback is still
      // pending — i.e. it never calls next/resolve/reject, e.g. an async
      // `onRequest` awaiting a token refresh that gets cancelled — the
      // handler's completer would never complete. Since the queue only
      // advances through the handler, the active slot would never be released
      // and every subsequent request routed through this interceptor would
      // stall forever. Releasing the slot on cancellation keeps the queue
      // moving; `advance` is idempotent, so a later normal completion (if the
      // callback eventually resumes) is a no-op. The hook is only registered
      // for the active task, so a queued task is never advanced out of turn.
      _cancelTokenOf(task.data)?.whenCancel.then((_) {
        final ref = taskRef;
        if (ref != null && !ref.handler.isCompleted) {
          advance();
        }
      });

      try {
        callback(task.data, task.handler);
      } catch (e) {
        // Handle synchronous exceptions thrown by interceptor callbacks.
        // Without this, the request would hang indefinitely because the
        // handler's completer would never be completed.
        onError(e, task.handler);
      }
    }

    taskQueue.queue.add(_InterceptorParams<T, V>(data, handler));
    if (!taskQueue.processing) {
      taskQueue.processing = true;
      runTask(taskQueue.queue.removeFirst());
    }
  }

  /// Extracts the [CancelToken] associated with a queued task's payload
  /// ([RequestOptions], [Response] or [DioException]), if any, so the queue
  /// can be released when the underlying request is cancelled.
  static CancelToken? _cancelTokenOf(Object? data) {
    if (data is RequestOptions) {
      return data.cancelToken;
    }
    if (data is Response) {
      return data.requestOptions.cancelToken;
    }
    if (data is DioException) {
      return data.requestOptions.cancelToken;
    }
    return null;
  }
}

/// A helper class to create [QueuedInterceptor] in ease.
///
/// See also:
///  - [InterceptorsWrapper], creates [Interceptor]s in ease.
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
