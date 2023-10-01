# dio_http2_adapter

[![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg)](https://pub.dev/packages/dio_http2_adapter)

An adapter that combines HTTP/2 and dio. Supports reusing connections, header compression, etc.

## Getting Started

### Install

Add the `dio_http2_adapter` package to your
[pubspec dependencies](https://pub.dev/packages/dio_http2_adapter/install).

### Usage

```dart
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() async {
  final dio = Dio()
    ..options.baseUrl = 'https://pub.dev'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: Duration(seconds: 10)),
    );

  Response<String> response;
  response = await dio.get('/?xx=6');
  for (final e in response.redirects) {
    print('redirect: ${e.statusCode} ${e.location}');
  }
  print(response.data);
}
```

### Ignoring a bad certificate

```dart
void main() async {
  final dio = Dio()
    ..options.baseUrl = 'https://pub.dev'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: Duration(seconds: 10),
        onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
      ),
    );
}
```

### Configuring the proxy

```dart
void main() async {
  final dio = Dio()
    ..options.baseUrl = 'https://pub.dev'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: Duration(seconds: 10),
        onClientCreate: (_, config) =>
            config.proxy = Uri.parse('http://login:password@192.168.0.1:8888'),
      ),
    );
}
```
