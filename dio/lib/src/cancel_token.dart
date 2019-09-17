import 'dart:async';
import 'dio_error.dart';

/// You can cancel a request by using a cancel token.
/// One token can be shared with different requests.
/// when a token's [cancel] method invoked, all requests
/// with this token will be cancelled.
class CancelToken {
  CancelToken() {
    _completer = Completer();
  }

  /// Whether is throw by [cancel]
  static bool isCancel(DioError e) {
    return e.type == DioErrorType.CANCEL;
  }

  /// If request have been canceled, save the cancel Error.
  DioError _cancelError;

  /// If request have been canceled, save the cancel Error.
  DioError get cancelError => _cancelError;

  Completer _completer;

  /// whether cancelled
  bool get isCancelled => _cancelError != null;

  /// When cancelled, this future will be resolved.
  Future<void> get whenCancel => _completer.future;

  /// Cancel the request
  void cancel([dynamic reason]) {
    _cancelError = DioError(type: DioErrorType.CANCEL, error: reason);
    _completer.complete();
  }
}
