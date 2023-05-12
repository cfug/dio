import 'dart:async';

import 'dio_exception.dart';
import 'options.dart';

/// An instance which controls cancellation of [Dio]'s requests,
/// build from [Completer].
///
/// You can cancel requests by using a [CancelToken].
/// One token can be shared with different requests.
/// When [cancel] is invoked, all requests using this token will be cancelled.
class CancelToken {
  CancelToken();

  final Completer<DioException> _completer = Completer<DioException>();

  /// Whether the [error] is thrown by [cancel].
  static bool isCancel(DioException error) =>
      error.type == DioExceptionType.cancel;

  /// If request have been canceled, save the cancel error.
  DioException? get cancelError => _cancelError;
  DioException? _cancelError;

  RequestOptions? requestOptions;

  /// Whether the token is cancelled.
  bool get isCancelled => _cancelError != null;

  /// When cancelled, this future will be resolved.
  Future<DioException> get whenCancel => _completer.future;

  /// Cancel the request with the given [reason].
  void cancel([Object? reason]) {
    _cancelError = DioException.requestCancelled(
      requestOptions: requestOptions ?? RequestOptions(),
      reason: reason,
      stackTrace: StackTrace.current,
    );
    if (!_completer.isCompleted) {
      _completer.complete(_cancelError);
    }
  }
}
