import 'dart:io';

import 'package:mockito/annotations.dart';

import 'http_mock.mocks.dart';

final httpClientMock = MockHttpClient();

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<HttpClient>(),
    MockSpec<HttpClientRequest>(),
    MockSpec<HttpClientResponse>(),
    MockSpec<HttpHeaders>(),
  ],
)
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return httpClientMock;
  }
}
