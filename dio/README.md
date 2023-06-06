# dio

[![Pub](https://img.shields.io/pub/v/dio.svg)](https://pub.dev/packages/dio)
[![Dev](https://img.shields.io/pub/v/dio.svg?label=dev&include_prereleases)](https://pub.dev/packages/dio)

Language: English | [简体中文](README-ZH.md)

A powerful HTTP client for Dart/Flutter, which supports global configuration,
interceptors, FormData, request cancellation, file uploading/downloading,
timeout, and custom adapters etc. 

<details>
  <summary>Table of content</summary>

<!-- TOC -->
* [dio](#dio)
  * [Get started](#get-started)
    * [Add dependency](#add-dependency)
    * [Super simple to use](#super-simple-to-use)
  * [Awesome dio](#awesome-dio)
    * [Plugins](#plugins)
    * [Related Projects](#related-projects)
  * [Examples](#examples)
  * [Dio APIs](#dio-apis)
    * [Creating an instance and set default configs.](#creating-an-instance-and-set-default-configs)
    * [Request Options](#request-options)
    * [Response](#response)
    * [Interceptors](#interceptors)
      * [Resolve and reject the request](#resolve-and-reject-the-request)
      * [QueuedInterceptor](#queuedinterceptor)
        * [Example](#example)
      * [LogInterceptor](#loginterceptor)
      * [Custom Interceptor](#custom-interceptor)
  * [Handling Errors](#handling-errors)
    * [DioException](#dioexception)
    * [DioExceptionType](#dioexceptiontype)
  * [Using application/x-www-form-urlencoded format](#using-applicationx-www-form-urlencoded-format)
  * [Sending FormData](#sending-formdata)
    * [Multiple files upload](#multiple-files-upload)
    * [Reuse `FormData`s and `MultipartFile`s](#reuse-formdata-s-and-multipartfile-s)
  * [Transformer](#transformer)
    * [In Flutter](#in-flutter)
    * [Other example](#other-example)
  * [HttpClientAdapter](#httpclientadapter)
    * [Using proxy](#using-proxy)
    * [HTTPS certificate verification](#https-certificate-verification)
  * [HTTP/2 support](#http2-support)
  * [Cancellation](#cancellation)
  * [Extends Dio class](#extends-dio-class)
  * [Cross-Origin Resource Sharing on Web (CORS)](#cross-origin-resource-sharing-on-web--cors-)
<!-- TOC -->
</details>

## Get started

### Add dependency

You can use the command to add dio as a dependency with the latest stable version:

```console
$ dart pub add dio
```

Or you can manually add dio into the dependencies section in your pubspec.yaml:

```yaml
dependencies:
  dio: ^replace-with-latest-version
```

The latest version is: ![Pub](https://img.shields.io/pub/v/dio.svg)
The latest version including pre-releases is: ![Pub](https://img.shields.io/pub/v/dio?include_prereleases)

**Before you upgrade: Breaking changes might happen in major and minor versions of packages.<br/>
See the [Migration Guide][] for the complete breaking changes list.**

### Super simple to use

```dart
import 'package:dio/dio.dart';

final dio = Dio();

void getHttp() async {
  final response = await dio.get('https://dart.dev');
  print(response);
}
```

## Awesome dio

🎉 A curated list of awesome things related to dio.

### Plugins

<!-- Use https://pub.dev for the hosted URL. -->
| Repository                                                                                             | Status                                                                                                                       | Description                                                                                                            |
|--------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [dio_cookie_manager](https://github.com/cfug/dio/blob/main/plugins/cookie_manager)                     | [![Pub](https://img.shields.io/pub/v/dio_cookie_manager.svg)](https://pub.dev/packages/dio_cookie_manager)                   | A cookie manager for Dio                                                                                               |
| [dio_http2_adapter](https://github.com/cfug/dio/blob/main/plugins/http2_adapter)                       | [![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg)](https://pub.dev/packages/dio_http2_adapter)                     | A Dio HttpClientAdapter which support Http/2.0                                                                         |
| [native_dio_adapter](https://github.com/cfug/dio/blob/main/plugins/native_dio_adapter)                 | [![Pub](https://img.shields.io/pub/v/native_dio_adapter.svg)](https://pub.dev/packages/native_dio_adapter)                   | An adapter for Dio which makes use of cupertino_http and cronet_http to delegate HTTP requests to the native platform. |
| [dio_smart_retry](https://github.com/rodion-m/dio_smart_retry)                                         | [![Pub](https://img.shields.io/pub/v/dio_smart_retry.svg)](https://pub.dev/packages/dio_smart_retry)                         | Flexible retry library for Dio                                                                                         |
| [http_certificate_pinning](https://github.com/diefferson/http_certificate_pinning)                     | [![Pub](https://img.shields.io/pub/v/http_certificate_pinning.svg)](https://pub.dev/packages/http_certificate_pinning)       | Https Certificate pinning for Flutter                                                                                  |
| [dio_intercept_to_curl](https://github.com/blackflamedigital/dio_intercept_to_curl)                   | [![Pub](https://img.shields.io/pub/v/dio_intercept_to_curl.svg)](https://pub.dev/packages/dio_intercept_to_curl) | A Flutter curl-command generator for Dio.                                                                              |
| [dio_cache_interceptor](https://github.com/llfbandit/dio_cache_interceptor)                            | [![Pub](https://img.shields.io/pub/v/dio_cache_interceptor.svg)](https://pub.dev/packages/dio_cache_interceptor)             | Dio HTTP cache interceptor with multiple stores respecting HTTP directives (or not)                                    |
| [dio_http_cache](https://github.com/hurshi/dio-http-cache)                                             | [![Pub](https://img.shields.io/pub/v/dio_http_cache.svg)](https://pub.dev/packages/dio_http_cache)                           | A simple cache library for Dio like Rxcache in Android                                                                 |
| [pretty_dio_logger](https://github.com/Milad-Akarie/pretty_dio_logger)                                 | [![Pub](https://img.shields.io/pub/v/pretty_dio_logger.svg)](https://pub.dev/packages/pretty_dio_logger)                     | Pretty Dio logger is a Dio interceptor that logs network calls in a pretty, easy to read format.                       |
| [dio_image_provider](https://github.com/ueman/image_provider)                                          | [![Pub](https://img.shields.io/pub/v/dio_image_provider.svg)](https://pub.dev/packages/dio_image_provider)                   | An image provider which makes use of package:dio to instead of dart:io                                                 |
| [flutter_ume_kit_dio](https://github.com/cfug/flutter_ume_kits/tree/main/packages/flutter_ume_kit_dio) | [![Pub](https://img.shields.io/pub/v/flutter_ume_kit_dio.svg)](https://pub.dev/packages/flutter_ume_kit_dio)                 | A debug kit of dio on flutter_ume                                                                                      |

### Related Projects

Welcome to submit third-party plugins and related libraries
in [here](https://github.com/cfug/dio/issues/347).

## Examples

Performing a `GET` request:

```dart
import 'package:dio/dio.dart';

final dio = Dio();

void request() async {
  Response response;
  response = await dio.get('/test?id=12&name=dio');
  print(response.data.toString());
  // The below request is the same as above.
  response = await dio.get(
    '/test',
    queryParameters: {'id': 12, 'name': 'dio'},
  );
  print(response.data.toString());
}
```

Performing a `POST` request:

```dart
response = await dio.post('/test', data: {'id': 12, 'name': 'dio'});
```

Performing multiple concurrent requests:

```dart
response = await Future.wait([dio.post('/info'), dio.get('/token')]);
```

Downloading a file:

```dart
response = await dio.download(
  'https://pub.dev/',
  (await getTemporaryDirectory()).path + 'pub.html',
);
```

Get response stream:

```dart
final rs = await dio.get(
  url,
  options: Options(responseType: ResponseType.stream), // Set the response type to `stream`.
);
print(rs.data.stream); // Response stream.
```

Get response with bytes:

```dart
final rs = await Dio().get<List<int>>(
  url,
  options: Options(responseType: ResponseType.bytes), // Set the response type to `bytes`.
);
print(rs.data); // Type: List<int>.
```

Sending a `FormData`:

```dart
final formData = FormData.fromMap({
  'name': 'dio',
  'date': DateTime.now().toIso8601String(),
});
final response = await dio.post('/info', data: formData);
```

Uploading multiple files to server by FormData:

```dart
final formData = FormData.fromMap({
  'name': 'dio',
  'date': DateTime.now().toIso8601String(),
  'file': await MultipartFile.fromFile('./text.txt', filename: 'upload.txt'),
  'files': [
    await MultipartFile.fromFile('./text1.txt', filename: 'text1.txt'),
    await MultipartFile.fromFile('./text2.txt', filename: 'text2.txt'),
  ]
});
final response = await dio.post('/info', data: formData);
```

Listening the uploading progress:

```dart
final response = await dio.post(
  'https://www.dtworkroom.com/doris/1/2.0.0/test',
  data: {'aa': 'bb' * 22},
  onSendProgress: (int sent, int total) {
    print('$sent $total');
  },
);
```

Post binary data with Stream:

```dart
// Binary data
final postData = <int>[0, 1, 2];
await dio.post(
  url,
  data: Stream.fromIterable(postData.map((e) => [e])), // Creates a Stream<List<int>>.
  options: Options(
    headers: {
      Headers.contentLengthHeader: postData.length, // Set the content-length.
    },
  ),
);
```

Note: `content-length` must be set if you want to subscribe to the sending progress.

See all examples code [here](example).

## Dio APIs

### Creating an instance and set default configs.

> It is recommended to use a singleton of `Dio` in projects, which can manage configurations like headers, base urls,
> and timeouts consistently.
> Here is an [example](../example_flutter_app) that use a singleton in Flutter.

You can create instance of Dio with an optional `BaseOptions` object:

```dart
final dio = Dio(); // With default `Options`.

void configureDio() {
  // Set default configs
  dio.options.baseUrl = 'https://api.pub.dev';
  dio.options.connectTimeout = Duration(seconds: 5);
  dio.options.receiveTimeout = Duration(seconds: 3);

  // Or create `Dio` with a `BaseOptions` instance.
  final options = BaseOptions(
    baseUrl: 'https://api.pub.dev',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 3),
  );
  final anotherDio = Dio(options);
}
```

The core API in Dio instance is:

```dart
Future<Response<T>> request<T>(
  String path, {
  Object? data,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  Options? options,
  ProgressCallback? onSendProgress,
  ProgressCallback? onReceiveProgress,
});
```

```dart
final response = await dio.request(
  '/test',
  data: {'id': 12, 'name': 'dio'},
  options: Options(method: 'GET'),
);
```

### Request Options

The `Options` class describes the http request information and configuration.
Each Dio instance has a base config for all requests made by itself,
and we can override the base config with `Options` when make a single request.
The `Options` declaration as follows:

```dart
/// Http method.
String method;

/// Request base url, it can contain sub path, like: https://dart.dev/api/.
String? baseUrl;

/// Http request headers.
Map<String, dynamic>? headers;

/// Timeout for opening url.
Duration? connectTimeout;

/// Whenever more than [receiveTimeout] passes between two events from response stream,
/// [Dio] will throw the [DioException] with [DioExceptionType.RECEIVE_TIMEOUT].
/// Note: This is not the receiving time limitation.
Duration? receiveTimeout;

/// Request data, can be any type.
dynamic data;

/// If the `path` starts with 'http(s)', the `baseURL` will be ignored, otherwise,
/// it will be combined and then resolved with the baseUrl.
String path;

/// The request Content-Type.
///
/// The default `content-type` for requests will be implied by the
/// [ImplyContentTypeInterceptor] according to the type of the request payload.
/// The interceptor can be removed by
/// [Interceptors.removeImplyContentTypeInterceptor].
///
/// If you want to encode request body with 'application/x-www-form-urlencoded',
/// you can set [Headers.formUrlEncodedContentType], and [Dio]
/// will automatically encode the request body.
String? contentType;

/// [responseType] indicates the type of data that the server will respond with
/// options which defined in [ResponseType] are `json`, `stream`, `plain`.
///
/// The default value is `json`, dio will parse response string to json object automatically
/// when the content-type of response is 'application/json'.
///
/// If you want to receive response data with binary bytes, for example,
/// downloading a image, use `stream`.
///
/// If you want to receive the response data with String, use `plain`.
ResponseType? responseType;

/// `validateStatus` defines whether the request is successful for a given
/// HTTP response status code. If `validateStatus` returns `true` ,
/// the request will be perceived as successful; otherwise, considered as failed.
ValidateStatus? validateStatus;

/// Custom field that you can retrieve it later in
/// [Interceptor], [Transformer] and the [Response] object.
Map<String, dynamic>? extra;

/// Common query parameters.
Map<String, dynamic /*String|Iterable<String>*/ >? queryParameters;

/// [listFormat] indicates the format of collection data in request options。
/// The default value is `multiCompatible`
ListFormat? listFormat;
```

There is a complete example [here](../example/lib/options.dart).

### Response

The response for a request contains the following information.

```dart
/// Response body. may have been transformed, please refer to [ResponseType].
T? data;

/// The corresponding request info.
RequestOptions requestOptions;

/// HTTP status code.
int? statusCode;

/// Returns the reason phrase associated with the status code.
/// The reason phrase must be set before the body is written
/// to. Setting the reason phrase after writing to the body.
String? statusMessage;

/// Whether this response is a redirect.
/// ** Attention **: Whether this field is available depends on whether the
/// implementation of the adapter supports it or not.
bool isRedirect;

/// The series of redirects this connection has been through. The list will be
/// empty if no redirects were followed. [redirects] will be updated both
/// in the case of an automatic and a manual redirect.
///
/// ** Attention **: Whether this field is available depends on whether the
/// implementation of the adapter supports it or not.
List<RedirectRecord> redirects;

/// Custom fields that are constructed in the [RequestOptions].
Map<String, dynamic> extra;

/// Response headers.
Headers headers;
```

When request is succeed, you will receive the response as follows:

```dart
final response = await dio.get('https://pub.dev');
print(response.data);
print(response.headers);
print(response.requestOptions);
print(response.statusCode);
```

### Interceptors

For each dio instance, we can add one or more interceptors,
by which we can intercept requests, responses, and errors
before they are handled by `then` or `catchError`.

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      // Do something before request is sent.
      // If you want to resolve the request with custom data,
      // you can resolve a `Response` using `handler.resolve(response)`.
      // If you want to reject the request with a error message,
      // you can reject with a `DioException` using `handler.reject(dioError)`.
      return handler.next(options);
    },
    onResponse: (Response response, ResponseInterceptorHandler handler) {
      // Do something with response data.
      // If you want to reject the request with a error message,
      // you can reject a `DioException` object using `handler.reject(dioError)`.
      return handler.next(response);
    },
    onError: (DioException e, ErrorInterceptorHandler handler) {
      // Do something with response error.
      // If you want to resolve the request with some custom data,
      // you can resolve a `Response` object using `handler.resolve(response)`.
      return handler.next(e);
    },
  ),
);
```

Simple interceptor example:

```dart
import 'package:dio/dio.dart';
class CustomInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
```

#### Resolve and reject the request

In all interceptors, you can interfere with their execution flow.
If you want to resolve the request/response with some custom data,
you can call `handler.resolve(Response)`.
If you want to reject the request/response with a error message,
you can call `handler.reject(dioError)` .

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      return handler.resolve(
        Response(requestOptions: options, data: 'fake data'),
      );
    },
  ),
);
final response = await dio.get('/test');
print(response.data); // 'fake data'
```

#### QueuedInterceptor

`Interceptor` can be executed concurrently, that is,
all the requests enter the interceptor at once, rather than executing sequentially.
However, in some cases we expect that requests enter the interceptor sequentially like #590.
Therefore, we need to provide a mechanism for sequential access (step by step)
to interceptors and `QueuedInterceptor` can solve this problem.

##### Example

Because of security reasons, we need all the requests to set up
a `csrfToken` in the header, if `csrfToken` does not exist,
we need to request a csrfToken first, and then perform the network request,
because the request csrfToken progress is asynchronous,
so we need to execute this async request in request interceptor.

For the complete code see [here](../example/lib/queued_interceptor_crsftoken.dart).

#### LogInterceptor

You can apply the `LogInterceptor` to log requests and responses automatically in the DEBUG mode:

```dart
dio.interceptors.add(LogInterceptor(responseBody: false)); // Do not output responses body.
```

**Note:** `LogInterceptor` should be the last to add since the interceptors are FIFO.

**Note:** Logs will only be printed in the DEBUG mode (when the assertion is enabled).

#### Custom Interceptor

You can customize interceptor by extending the `Interceptor/QueuedInterceptor` class.
There is an example that implementing a simple cache policy:
[custom cache interceptor](../example/lib/custom_cache_interceptor.dart).

## Handling Errors

When an error occurs, Dio will wrap the `Error/Exception` to a `DioException`:

```dart
try {
  // 404
  await dio.get('https://api.pub.dev/not-exist');
} on DioException catch (e) {
  // The request was made and the server responded with a status code
  // that falls out of the range of 2xx and is also not 304.
  if (e.response != null) {
    print(e.response.data)
    print(e.response.headers)
    print(e.response.requestOptions)
  } else {
    // Something happened in setting up or sending the request that triggered an Error
    print(e.requestOptions)
    print(e.message)
  }
}
```

### DioException

```dart
/// The request info for the request that throws exception.
RequestOptions requestOptions;

/// Response info, it may be `null` if the request can't reach to the
/// HTTP server, for example, occurring a DNS error, network is not available.
Response? response;

/// The type of the current [DioException].
DioExceptionType type;

/// The original error/exception object;
/// It's usually not null when `type` is [DioExceptionType.unknown].
Object? error;

/// The stacktrace of the original error/exception object;
/// It's usually not null when `type` is [DioExceptionType.unknown].
StackTrace? stackTrace;

/// The error message that throws a [DioException].
String? message;
```

### DioExceptionType

See [the source code](lib/src/dio_exception.dart).

## Using application/x-www-form-urlencoded format

By default, Dio serializes request data (except `String` type) to `JSON`.
To send data in the `application/x-www-form-urlencoded` format instead:

```dart
// Instance level
dio.options.contentType = Headers.formUrlEncodedContentType;
// or only works once
dio.post(
  '/info',
  data: {'id': 5},
  options: Options(contentType: Headers.formUrlEncodedContentType),
);
```

## Sending FormData

You can also send `FormData` with Dio, which will send data in the `multipart/form-data`,
and it supports uploading files.

```dart
final formData = FormData.fromMap({
  'name': 'dio',
  'date': DateTime.now().toIso8601String(),
  'file': await MultipartFile.fromFile('./text.txt',filename: 'upload.txt'),
});
final response = await dio.post('/info', data: formData);
```

> `FormData` is supported with the POST method typically.

There is a complete example [here](../example/lib/formdata.dart).

### Multiple files upload

There are two ways to add multiple files to `FormData`,
the only difference is that upload keys are different for array types。

```dart
final formData = FormData.fromMap({
  'files': [
    MultipartFile.fromFileSync('path/to/upload1.txt', filename: 'upload1.txt'),
    MultipartFile.fromFileSync('path/to/upload2.txt', filename: 'upload2.txt'),
  ],
});
```

The upload key eventually becomes `files[]`.
This is because many back-end services add a middle bracket to key
when they get an array of files.
**If you don't want a list literal**,
you should create FormData as follows (Don't use `FormData.fromMap`):

```dart
final formData = FormData();
formData.files.addAll([
  MapEntry(
   'files',
    MultipartFile.fromFileSync('./example/upload.txt',filename: 'upload.txt'),
  ),
  MapEntry(
    'files',
    MultipartFile.fromFileSync('./example/upload.txt',filename: 'upload.txt'),
  ),
]);
```

### Reuse `FormData`s and `MultipartFile`s

You should make a new `FormData` or `MultipartFile` every time in repeated requests.
A typical wrong behavior is setting the `FormData` as a variable and using it in every request.
It can be easy for the *Cannot finalize* exceptions to occur.
To avoid that, write your requests like the below code:
```dart
Future<void> _repeatedlyRequest() async {
  Future<FormData> createFormData() async {
    return FormData.fromMap({
      'name': 'dio',
      'date': DateTime.now().toIso8601String(),
      'file': await MultipartFile.fromFile('./text.txt',filename: 'upload.txt'),
    });
  }
  
  await dio.post('some-url', data: await createFormData());
}
```

## Transformer

`Transformer` allows changes to the request/response data
before it is sent/received to/from the server.
This is only applicable for request methods 'PUT', 'POST', and 'PATCH'.
Dio has already implemented a `DefaultTransformer` as default.
If you want to customize the transformation of request/response data,
you can provide a `Transformer` by your self,
and replace the `DefaultTransformer` by setting the `dio.transformer`.

> `Transformer.transformRequest` only takes effect when request with `PUT`/`POST`/`PATCH`,
> they're methods that can contain the request body.
> `Transformer.transformResponse` however, can be applied to all types of responses.

### In Flutter

If you're using Dio in Flutter development,
it's better to decode JSON in isolates with the `compute` function.

```dart
/// Must be top-level function
Map<String, dynamic> _parseAndDecode(String response) {
  return jsonDecode(response) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  // Custom `jsonDecodeCallback`.
  dio.transformer = DefaultTransformer()..jsonDecodeCallback = parseJson;
  runApp(MyApp());
}
```

### Other example

There is an example for [customizing Transformer](../example/lib/transformer.dart).

## HttpClientAdapter

`HttpClientAdapter` is a bridge between `Dio` and `HttpClient`.

`Dio` implements standard and friendly APIs for developer.
`HttpClient` is the real object that makes Http requests.

We can use any `HttpClient` not just `dart:io:HttpClient` to make HTTP requests.
And all we need is providing a `HttpClientAdapter`.
The default `HttpClientAdapter` for Dio is `IOHttpClientAdapter` on native platforms,
and `BrowserClientAdapter` on the Web platform.
They can be initiated by calling the `HttpClientAdapter()`.

```dart
dio.httpClientAdapter = HttpClientAdapter();
```

If you want to use platform adapters explicitly:
- For the Web platform:
  ```dart
  import 'package:dio/browser.dart';
  // ...
  dio.httpClientAdapter = BrowserClientAdapter();
  ```
- For native platforms:
  ```dart
  import 'package:dio/io.dart';
  // ...
  dio.httpClientAdapter = IOClientAdapter();
  ```

[Here](../example/lib/adapter.dart) is a simple example to custom adapter. 

### Using proxy

`IOHttpClientAdapter` provide a callback to set proxy to `dart:io:HttpClient`,
for example:

```dart
import 'package:dio/io.dart';

void initAdapter() {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // Config the client.
      client.findProxy = (uri) {
        // Forward all request to proxy "localhost:8888".
        // Be aware, the proxy should went through you running device,
        // not the host platform.
        return 'PROXY localhost:8888';
      };
      // You can also create a new HttpClient for Dio instead of returning,
      // but a client must being returned here.
      return client;
    },
  );
}
```

There is a complete example [here](../example/lib/proxy.dart).

Web does not support to set proxy.

### HTTPS certificate verification

HTTPS certificate verification (or public key pinning) refers to the process of ensuring that
the certificates protecting the TLS connection to the server are the ones you expect them to be.
The intention is to reduce the chance of a man-in-the-middle attack.
The theory is covered by [OWASP](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning).

_Server Response Certificate_

Unlike other methods, this one works with the certificate of the server itself.

```dart
void initAdapter() {
  const String fingerprint = 'ee5ce1dfa7a53657c545c62b65802e4272878dabd65c0aadcf85783ebb0b4d5c';
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      // Don't trust any certificate just because their root cert is trusted.
      final HttpClient client = HttpClient(context: SecurityContext(withTrustedRoots: false));
      // You can test the intermediate / root cert here. We just ignore it.
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    },
    validateCertificate: (cert, host, port) {
      // Check that the cert fingerprint matches the one we expect.
      // We definitely require _some_ certificate.
      if (cert == null) {
        return false;
      }
      // Validate it any way you want. Here we only check that
      // the fingerprint matches the OpenSSL SHA256.
      return fingerprint == sha256.convert(cert.der).toString();
    },
  );
}
```

You can use openssl to read the SHA256 value of a certificate:

```sh
openssl s_client -servername pinning-test.badssl.com -connect pinning-test.badssl.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -noout -fingerprint -sha256

# SHA256 Fingerprint=EE:5C:E1:DF:A7:A5:36:57:C5:45:C6:2B:65:80:2E:42:72:87:8D:AB:D6:5C:0A:AD:CF:85:78:3E:BB:0B:4D:5C
# (remove the formatting, keep only lower case hex characters to match the `sha256` above)
```

_Certificate Authority Verification_

These methods work well when your server has a self-signed certificate,
but they don't work for certificates issued by a 3rd party like AWS or Let's Encrypt.

There are two ways to verify the root of the https certificate chain provided by the server.
Suppose the certificate format is PEM, the code like:

```dart
void initAdapter() {
  String PEM = 'XXXXX'; // root certificate content
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return cert.pem == PEM; // Verify the certificate.
      };
      return client;
    },
  );
}
```

Another way is creating a `SecurityContext` when create the `HttpClient`:

```dart
void initAdapter() {
  String PEM = 'XXXXX'; // root certificate content
  dio.httpClientAdapter = IOHttpClientAdapter(
    onHttpClientCreate: (_) {
      final SecurityContext sc = SecurityContext();
      sc.setTrustedCertificates(File(pathToTheCertificate));
      final HttpClient client = HttpClient(context: sc);
      return client;
    },
  );
}
```

In this way, the format of `setTrustedCertificates()` must be PEM or PKCS12.
PKCS12 requires password to use, which will expose the password in the code,
so it's not recommended to use in common cases.

## HTTP/2 support

[dio_http2_adapter](../plugins/http2_adapter) is a Dio `HttpClientAdapter`
which supports HTTP/2.

## Cancellation

You can cancel a request using a `CancelToken`.
One token can be shared with multiple requests.
When a token's `cancel()` is invoked, all requests with this token will be cancelled.

```dart
final cancelToken = CancelToken();
dio.get(url, cancelToken: cancelToken).catchError((DioException err) {
  if (CancelToken.isCancel(err)) {
    print('Request canceled: ${err.message}');
  } else {
    // handle error.
  }
});
// Cancel the requests with "cancelled" message.
token.cancel('cancelled');
```

There is a complete example [here](../example/lib/cancel_request.dart).

## Extends Dio class

`Dio` is an abstract class with factory constructor,
so we don't extend `Dio` class direct.
We can extend `DioForNative` or `DioForBrowser` instead, for example:

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
// If in browser, import 'package:dio/browser.dart'.

class Http extends DioForNative {
  Http([BaseOptions options]) : super(options) {
    // do something
  }
}
```

We can also implement a custom `Dio` client:

```dart
class MyDio with DioMixin implements Dio {
  // ...
}
```

## Cross-Origin Resource Sharing on Web (CORS)

If a request is not a [simple request][],
the Web browser will send a [CORS preflight request][]
that checks to see if the CORS protocol is understood
and a server is aware using specific methods and headers.

You can modify your requests to match the definition of simple request,
or add a CORS middleware for your service to handle CORS requests.

[Migration Guide]: ./migration_guide.md
[simple request]: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests
[CORS preflight request]: https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request
