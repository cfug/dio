# dio_http2_adapter

[![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg)](https://pub.dev/packages/dio_http2_adapter)

An HTTP/2 adapter for [dio](https://github.com/cfug/dio).

## Getting Started

### Install

```yaml
dependencies:
  dio_http2_adapter: ^2.0.0 # latest version
```

### Usage

```dart
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() async {
  final dio = Dio()
    ..options.baseUrl = 'https://pub.dev'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: 10000,
        // Ignore bad certificate
        onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
      ),
    );
  final response = await dio.get('/?xx=something');
  print(response.data?.length);
  print(response.redirects.length);
  print(response.data);
}
```
