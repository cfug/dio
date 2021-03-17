import 'dart:async';
import 'dart:collection';

import 'options.dart';
import 'dio_error.dart';
import 'response.dart';

typedef InterceptorSendCallback = void Function(
  RequestOptions options,
  RequestInterceptorHandler handler,
);

typedef InterceptorSuccessCallback = void Function(
  Response e,
  ResponseInterceptorHandler handler,
);

typedef InterceptorErrorCallback = void Function(
  DioError e,
  ErrorInterceptorHandler handler,
);

typedef EnqueueCallback = FutureOr Function();

/// Add lock/unlock API for interceptors.
class Lock {
  Future? _lock;

  late Completer _completer;

  /// Whether this interceptor has been locked.
  bool get locked => _lock != null;

  /// Lock the interceptor.
  ///
  /// Once the request/response interceptor is locked, the incoming request/response
  /// will be added to a queue  before they enter the interceptor, they will not be
  /// continued until the interceptor is unlocked.
  void lock() {
    if (!locked) {
      _completer = Completer();
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
  void clear([String msg = 'cancelled']) {
    if (locked) {
      _completer.completeError(msg);
      _lock = null;
    }
  }

  /// If the interceptor is locked, the incoming request/response task
  /// will enter a queue.
  ///
  /// [callback] the function  will return a `Future`
  /// @nodoc
  Future? enqueue(EnqueueCallback callback) {
    if (locked) {
      // we use a future as a queue
      return _lock!.then((d) => callback());
    }
    return null;
  }
}

enum InterceptorResultType {
  next,
  resolve,
  resolveCallFollowing,
  reject,
  rejectCallFollowing,
}

class InterceptorState<T> {
  InterceptorState(this.data, [this.type = InterceptorResultType.next]);

  T data;
  InterceptorResultType type;
}

class _BaseHandler {
  final _completer = Completer<InterceptorState>();

  /// Assure the final future state is succeed!

  Future<InterceptorState> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;
}

class RequestInterceptorHandler extends _BaseHandler {
  void next(RequestOptions requestOptions) {
    _completer.complete(InterceptorState<RequestOptions>(requestOptions));
  }

  /// Assure the final future state is succeed!
  void resolve(Response response,
      [bool callFollowingResponseInterceptor = false]) {
    _completer.complete(
      InterceptorState<Response>(
        response,
        callFollowingResponseInterceptor
            ? InterceptorResultType.resolveCallFollowing
            : InterceptorResultType.resolve,
      ),
    );
  }

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
  }
}

class ResponseInterceptorHandler extends _BaseHandler {
  void next(Response response) {
    _completer.complete(
      InterceptorState<Response>(response),
    );
  }

  /// Assure the final future state is succeed!
  void resolve(Response response) {
    _completer.complete(
      InterceptorState<Response>(
        response,
        InterceptorResultType.resolve,
      ),
    );
  }

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
  }
}

class ErrorInterceptorHandler extends _BaseHandler {
  void next(DioError err) {
    _completer.completeError(
      InterceptorState<DioError>(err),
      err.stackTrace,
    );
  }

  void resolve(Response response) {
    _completer.complete(InterceptorState<Response>(
      response,
      InterceptorResultType.resolve,
    ));
  }

  void reject(DioError error) {
    _completer.completeError(
      InterceptorState<DioError>(
        error,
        InterceptorResultType.reject,
      ),
      error.stackTrace,
    );
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
  /// ```dart
  ///  Future onRequest(RequestOptions options) => dio.resolve('fake data');
  ///  ...
  ///  print(response.data) // 'fake data';
  /// ```
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) =>
      handler.next(options);

  /// The callback will be executed on success.
  ///
  /// If you want to reject the request with a error message,
  /// you can return a [DioError] object or return [dio.reject] .
  /// If you want to continue the request, return the [Response] object.
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) =>
      handler.next(response);

  /// The callback will be executed on error.
  ///
  /// If you want to resolve the request with some custom data，
  /// you can return a [Response] object or return [dio.resolve].
  /// If you want to continue the request, return the [DioError] object.
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) =>
      handler.next(err);
}

class InterceptorsWrapper extends Interceptor {
  final InterceptorSendCallback? _onRequest;

  final InterceptorSuccessCallback? _onResponse;

  final InterceptorErrorCallback? _onError;

  InterceptorsWrapper({
    InterceptorSendCallback? onRequest,
    InterceptorSuccessCallback? onResponse,
    InterceptorErrorCallback? onError,
  })  : _onRequest = onRequest,
        _onResponse = onResponse,
        _onError = onError;

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
    Response response,
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

class Interceptors extends ListMixin<Interceptor> {
  final _list = <Interceptor>[];
  final Lock _requestLock = Lock();
  final Lock _responseLock = Lock();
  final Lock _errorLock = Lock();

  Lock get requestLock => _requestLock;

  Lock get responseLock => _responseLock;

  Lock get errorLock => _errorLock;

  @override
  int length = 0;

  @override
  Interceptor operator [](int index) {
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
