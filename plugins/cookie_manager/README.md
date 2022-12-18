# diox_cookie_manager

[![Pub](https://img.shields.io/pub/v/diox_cookie_manager.svg)](https://pub.dev/packages/diox_cookie_manager)

A cookie manager for [diox](https://github.com/cfug/diox). 

## Getting Started

### Install

```yaml
dependencies:
  diox_cookie_manager: ^2.0.0 # latest version
```

### Usage

```dart
import 'package:cookie_jar/cookie_jar.dart';
import 'package:diox/dio.dart';
import 'package:diox_cookie_manager/dio_cookie_manager.dart';

void main() async {
  final dio =  Dio();
  final cookieJar = CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));
  // First request, and save cookies (CookieManager do it).
  await dio.get("https://dart.dev");
  // Print cookies
  print(await cookieJar.loadForRequest(Uri.parse("https://dart.dev")));
  // Second request with the cookies
  await dio.get('https://dart.dev');
}
```

## Cookie Manager

`CookieManager` Interceptor can help us manage the request/response cookies automatically.
`CookieManager` depends on the `cookie_jar` package:

> The diox_cookie_manager manage API is based on the withdrawn
> [cookie_jar](https://github.com/flutterchina/cookie_jar).

You can create a `CookieJar` or `PersistCookieJar` to manage cookies automatically,
and dio use the `CookieJar` by default, which saves the cookies **in RAM**.
If you want to persists cookies, you can use the `PersistCookieJar` class, for example:

```dart
dio.interceptors.add(CookieManager(PersistCookieJar()))
```

`PersistCookieJar` persists the cookies in files,
so if the application exit, the cookies always exist unless call `delete` explicitly.

> Note: In flutter, the path passed to `PersistCookieJar` must be valid (exists in phones and with write access).
> Use [path_provider](https://pub.dev/packages/path_provider) package to get the right path.

In flutter: 

```dart
Future<void> prepareJar() async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final String appDocPath = appDocDir.path;
  final jar = PersistCookieJar(
    ignoreExpires: true,
    storage: FileStorage(appDocPath +"/.cookies/" ),
  );
  dio.interceptors.add(CookieManager(jar));
}
```
