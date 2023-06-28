import 'dart:io';

import 'package:dio/dio.dart';
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
    MockSpec<Transformer>(),
  ],
)
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return httpClientMock;
  }
}
