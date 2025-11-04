import 'package:async/async.dart' show CancelableOperation;
import 'package:http/http.dart';

class CloseClientMock implements Client {
  bool closeWasCalled = false;

  @override
  void close() {
    closeWasCalled = true;
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class ClientMock implements Client {
  StreamedResponse? response;

  BaseRequest? request;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    this.request = request;
    return response!;
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class AbortClientMock implements Client {
  bool isRequestCanceled = false;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final cancellable = CancelableOperation.fromFuture(
      Future<void>.delayed(const Duration(seconds: 5)),
    );

    if (request is Abortable) {
      request.abortTrigger?.whenComplete(
        () {
          cancellable.cancel();
          isRequestCanceled = true;
        },
      );
    }

    await cancellable.valueOrCancellation();

    if (cancellable.isCanceled) {
      throw AbortedError();
    }

    return StreamedResponse(Stream.fromIterable([]), 200);
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}

class AbortedError extends Error {}

class DelayedClientMock implements Client {
  DelayedClientMock({
    required this.duration,
  });

  final Duration duration;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    await Future<void>.delayed(duration);

    return StreamedResponse(
      Stream.fromIterable([]),
      200,
    );
  }

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
