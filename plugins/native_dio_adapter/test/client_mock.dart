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
