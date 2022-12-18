# diox_http2_adapter

[![Pub](https://img.shields.io/pub/v/diox_http2_adapter.svg)](https://pub.dev/packages/diox_http2_adapter)

An HTTP/2 adapter for [diox](https://github.com/cfug/diox).

## Getting Started

### Install

```yaml
dependencies:
  diox_http2_adapter: ^2.0.0 # latest version
```

### Usage

```dart
import 'package:diox/dio.dart';
import 'package:diox_http2_adapter/dio_http2_adapter.dart';

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
