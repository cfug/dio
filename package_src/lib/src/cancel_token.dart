import 'dart:async';
import 'dio_error.dart';

/// You can cancel a request by using a cancel token.
/// One token can be shared with different requests.
/// when a token's [cancel] method invoked, all requests
/// with this token will be cancelled.
class CancelToken {
  CancelToken() {
    _completer = new Completer();
  }

  /// Whether is throw by [cancel]
  static bool isCancel(DioError e) {
    return e.type == DioErrorType.CANCEL;
  }

  Completer _completer;

  /// If request have been canceled, save the cancel Error.
  DioError get cancelError => _cancelError;

  /// whether cancelled
  bool get isCancelled => _cancelError != null;

  /// When cancelled, this future will be resolved.
  Future<void> get whenCancel => _completer.future;

  /// Cancel the request
  void cancel([String msg]) {
    _cancelError = new DioError(message: msg, type: DioErrorType.CANCEL);
    if (completers.isNotEmpty) {
      completers.forEach((e) => e.completeError(cancelError));

      /// Don't remove [completers] here, [Dio] will remove the completer automatically.
    }
    _completer.complete();
  }

  _trigger(Completer completer) {
    if (completer != null) {
      completer.completeError(cancelError);
      completers.remove(completer);
    }
  }

  /// Add a [completer] to the token.
  /// [completer] is used to cancel the request before it's not completed.
  ///
  /// Note: you shouldn't invoke this method by yourself. It's just used inner [Dio].
  /// @nodoc
  void addCompleter(Completer completer) {
    if (cancelError != null) {
      _trigger(completer);
    } else {
      if (!completers.contains(completer)) {
        completers.add(completer);
      }
    }
  }

  /// Remove a [completer] from the token.
  ///
  /// Note: you shouldn't invoke this method by yourself. It's just used inner [Dio].
  /// @nodoc
  void removeCompleter(Completer completer) {
    completers.remove(completer);
  }

  var completers = new List<Completer>();
  DioError _cancelError;
}
