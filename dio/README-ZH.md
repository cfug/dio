# dio

[![Pub](https://img.shields.io/pub/v/dio.svg)](https://pub.flutter-io.cn/packages/dio)
[![Dev](https://img.shields.io/pub/v/dio.svg?label=dev&include_prereleases)](https://pub.flutter-io.cn/packages/dio)

文档语言： 简体中文 | [English](README.md)

dio 是一个强大的 Dart HTTP 请求库，支持全局配置、Restful API、FormData、拦截器、
请求取消、Cookie 管理、文件上传/下载、超时以及自定义适配器等。

<details>
  <summary>内容列表</summary>

<!-- TOC -->
* [dio](#dio)
  * [开始使用](#开始使用)
    * [添加依赖](#添加依赖)
  * [一个极简的示例](#一个极简的示例)
  * [Awesome dio](#awesome-dio)
    * [相关插件](#相关插件)
    * [相关的项目](#相关的项目)
  * [示例](#示例)
  * [Dio APIs](#dio-apis)
    * [创建一个Dio实例，并配置它](#创建一个dio实例并配置它)
    * [请求配置](#请求配置)
    * [响应数据](#响应数据)
    * [拦截器](#拦截器)
      * [完成和终止请求/响应](#完成和终止请求响应)
      * [QueuedInterceptor](#queuedinterceptor)
        * [例子](#例子)
      * [日志拦截器](#日志拦截器)
    * [自定义拦截器](#自定义拦截器)
  * [错误处理](#错误处理)
    * [DioError](#dioerror)
    * [DioErrorType](#dioerrortype)
  * [使用 application/x-www-form-urlencoded 编码](#使用-applicationx-www-form-urlencoded-编码)
  * [发送 FormData](#发送-formdata)
    * [多文件上传](#多文件上传)
    * [复用 `FormData` 和 `MultipartFile`](#复用-formdata-和-multipartfile)
  * [转换器](#转换器)
    * [在 Flutter 中进行设置](#在-flutter-中进行设置)
    * [其它示例](#其它示例)
  * [HttpClientAdapter](#httpclientadapter)
    * [设置代理](#设置代理)
    * [HTTPS 证书校验](#https-证书校验)
  * [HTTP/2 支持](#http2-支持)
  * [请求取消](#请求取消)
  * [继承 Dio class](#继承-dio-class)
<!-- TOC -->
</details>

## 开始使用

> 查看 [迁移指南](migration_guide.md) 以了解各个版本之间的重大变更。

### 添加依赖

你可以使用以下命令将 dio 的最新稳定版依赖添加至你的项目：

```console
$ dart pub add dio
```

你也可以手动将 dio 添加至 pubspec.yaml：

```yaml
dependencies:
  dio: ^替换为最新版本
```

最新稳定版本为：![Pub](https://img.shields.io/pub/v/dio.svg)
最新包含开发版的版本为：![Pub](https://img.shields.io/pub/v/dio?include_prereleases)

## 一个极简的示例

```dart
import 'package:dio/dio.dart';

final dio = Dio();

void getHttp() async {
  final response = await dio.get('https://dart.dev');
  print(response);
}
```

## Awesome dio

🎉 以下是一个与 Dio 相关的精选清单。

### 相关插件

<!-- 使用 https://pub.flutter-io.cn 作为管理网址 -->
| 仓库                                                                                                     | 最新版本                                                                                                                                   | 描述                                                 |
|--------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| [dio_cookie_manager](https://github.com/cfug/dio/blob/main/plugins/cookie_manager)                     | [![Pub](https://img.shields.io/pub/v/dio_cookie_manager.svg)](https://pub.flutter-io.cn/packages/dio_cookie_manager)                   | Cookie 管理                                          |
| [dio_http2_adapter](https://github.com/cfug/dio/blob/main/plugins/http2_adapter)                       | [![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg)](https://pub.flutter-io.cn/packages/dio_http2_adapter)                     | 支持 HTTP/2 的自定义适配器                                  |
| [native_dio_adapter](https://github.com/cfug/dio/blob/main/plugins/native_dio_adapter)                 | [![Pub](https://img.shields.io/pub/v/native_dio_adapter.svg)](https://pub.flutter-io.cn/packages/native_dio_adapter)                   | 使用 cupertino_http 和 cronet_http 以适配器代理实现的原生网络请求功能。 |
| [dio_smart_retry](https://github.com/rodion-m/dio_smart_retry)                                         | [![Pub](https://img.shields.io/pub/v/dio_smart_retry.svg)](https://pub.flutter-io.cn/packages/dio_smart_retry)                         | 支持灵活地请求重试                                          |
| [http_certificate_pinning](https://github.com/diefferson/http_certificate_pinning)                     | [![Pub](https://img.shields.io/pub/v/http_certificate_pinning.svg)](https://pub.flutter-io.cn/packages/http_certificate_pinning)       | 用于 Flutter 的 HTTPS 证书锁定                            |
| [curl_logger_dio_interceptor](https://github.com/OwnWeb/curl_logger_dio_interceptor)                   | [![Pub](https://img.shields.io/pub/v/curl_logger_dio_interceptor.svg)](https://pub.flutter-io.cn/packages/curl_logger_dio_interceptor) | 用于 Flutter 的 CURL 命令生成器                            |
| [dio_cache_interceptor](https://github.com/llfbandit/dio_cache_interceptor)                            | [![Pub](https://img.shields.io/pub/v/dio_cache_interceptor.svg)](https://pub.flutter-io.cn/packages/dio_cache_interceptor)             | 具有多个符合 HTTP 指令的 HTTP 缓存拦截器，                        |
| [dio_http_cache](https://github.com/hurshi/dio-http-cache)                                             | [![Pub](https://img.shields.io/pub/v/dio_http_cache.svg)](https://pub.flutter-io.cn/packages/dio_http_cache)                           | 类似 Android 中的 RxCache 的缓存管理                        |
| [pretty_dio_logger](https://github.com/Milad-Akarie/pretty_dio_logger)                                 | [![Pub](https://img.shields.io/pub/v/pretty_dio_logger.svg)](https://pub.flutter-io.cn/packages/pretty_dio_logger)                     | 基于拦截器的简明易读的请求日志打印                                  |
| [dio_image_provider](https://github.com/ueman/image_provider)                                          | [![Pub](https://img.shields.io/pub/v/dio_image_provider.svg)](https://pub.flutter-io.cn/packages/dio_image_provider)                   | 基于 Dio 的图片加载                                       |
| [flutter_ume_kit_dio](https://github.com/cfug/flutter_ume_kits/tree/main/packages/flutter_ume_kit_dio) | [![Pub](https://img.shields.io/pub/v/flutter_ume_kit_dio.svg)](https://pub.flutter-io.cn/packages/flutter_ume_kit_dio)                 | flutter_ume 上的 dio 调试插件                            |

### 相关的项目

如果您也想提供第三方组件，请移步
[这里](https://github.com/cfug/dio/issues/347)。

## 示例

发起一个 `GET` 请求 :

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

发起一个 `POST` 请求:

```dart
response = await dio.post('/test', data: {'id': 12, 'name': 'dio'});
```

发起多个并发请求:

```dart
response = await Future.wait([dio.post('/info'), dio.get('/token')]);
```

下载文件:

```dart
response = await dio.download(
  'https://www.google.com/',
  (await getTemporaryDirectory()).path + 'google.html',
);
```

以流的方式接收响应数据：

```dart
final rs = await dio.get(
  url,
  options: Options(responseType: ResponseType.stream), // 设置接收类型为 `stream`
);
print(rs.data.stream); // 响应流
```

以二进制数组的方式接收响应数据：

```dart
final rs = await Dio().get<List<int>>(
  url,
  options: Options(responseType: ResponseType.bytes), // 设置接收类型为 `bytes`
);
print(rs.data); // 类型: List<int>
```

发送 `FormData`:

```dart
final formData = FormData.fromMap({
  'name': 'dio',
  'date': DateTime.now().toIso8601String(),
});
final response = await dio.post('/info', data: formData);
```

通过 `FormData` 上传多个文件:

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

监听发送（上传）数据进度:

```dart
final response = await dio.post(
  'https://www.dtworkroom.com/doris/1/2.0.0/test',
  data: {'aa': 'bb' * 22},
  onSendProgress: (int sent, int total) {
    print('$sent $total');
  },
);
```

以流的形式提交二进制数据：

```dart
// Binary data
final postData = <int>[0, 1, 2];
await dio.post(
  url,
  data: Stream.fromIterable(postData.map((e) => [e])), // 构建 Stream<List<int>>
  options: Options(
    headers: {
      Headers.contentLengthHeader: postData.length, // 设置 content-length.
    },
  ),
);
```

注意：如果要监听提交进度，则必须设置content-length，否则是可选的。

你可以在这里查看 [全部示例](example)。

## Dio APIs

### 创建一个Dio实例，并配置它

> 建议在项目中使用Dio单例，这样便可对同一个dio实例发起的所有请求进行一些统一的配置，
> 比如设置公共header、请求基地址、超时时间等。
> 这里有一个在[Flutter工程中使用Dio单例](../example_flutter_app)
> （定义为top level变量）的示例供开发者参考。

你可以使用默认配置或传递一个可选 `BaseOptions`参数来创建一个Dio实例 :

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

Dio 的核心 API 是：

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

### 请求配置

`BaseOptions` 描述的是 Dio 实例发起网络请求的的公共配置，
而 `Options` 描述了每一个Http请求的配置信息，每一次请求都可以单独配置，
单次请求的 `Options` 中的配置信息可以覆盖 `BaseOptions` 中的配置。
下面是 `Options` 的配置项：

```dart
/// 请求方式。
String method;

/// 请求基本地址，可以包含路径例如 https://dart.dev/api/。
String? baseUrl;

/// HTTP 请求头。
Map<String, dynamic>? headers;

/// 连接服务器超时时间.
Duration? connectTimeout;

/// 两次数据流数据接收的最长间隔时间，注意不是请求的最长接收时间。
Duration? receiveTimeout;

/// 请求内容体，可以是任意类型。
dynamic data;

/// 请求路径，如果以 http(s)开始, 则 [baseURL] 会被忽略，
/// 否则将会和 [baseUrl] 拼接出完整的地址。
String path = '';

/// 请求的 Content-Type。
///
/// 默认值会由 [ImplyContentTypeInterceptor] 根据请求载荷类型进行推导。
/// 可以调用 [Interceptors.removeImplyContentTypeInterceptor] 进行移除。
///
/// 如果你想以 `application/x-www-form-urlencoded` 格式编码请求数据,
/// 可以设置此选项为 `Headers.formUrlEncodedContentType`,
/// [Dio] 会自动编码请求体。
String? contentType;

/// 期望以哪种格式（方式）接受响应数据，包括 `json`、`stream` 和 `plain`。
///
/// 默认值是 `json`, 当响应头中 content-type 为 `application/json` 时，
/// dio 会自动将响应内容转化为 json 对象。
/// 如果想以二进制方式接受响应数据，如下载一个二进制文件，那么可以使用 `stream`。
///
/// 如果想以文本（字符串）格式接收响应数据，请使用 `plain`。
ResponseType? responseType;

/// `validateStatus` 决定 HTTP 响应状态码是否被视为请求成功，
/// 返回 `true` 请求结果就会按成功处理，否则会按失败处理.
ValidateStatus? validateStatus;

/// 用户自定义字段，可以在 [Interceptor]、[Transformer] 和 [Response] 中依次传递。
Map<String, dynamic>? extra;

/// 请求地址的参数。
Map<String, dynamic /*String|Iterable<String>*/ >? queryParameters;

/// 请求数据中数组的编码的方式，默认值为 `multiCompatible`。
ListFormat? listFormat;
```

此处为 [完整的代码示例](../example/lib/options.dart)。

### 响应数据

当请求成功时会返回一个Response对象，它包含如下字段：

```dart
/// 响应数据。可能已经被转换了类型, 详情请参考 [ResponseType]。
T? data;

/// 响应对应的请求配置。
RequestOptions requestOptions;

/// 响应的 HTTP 状态码。
int? statusCode;

/// 响应对应状态码的详情信息。
String? statusMessage;

/// 响应是否被重定向
bool isRedirect;

/// 请求连接经过的重定向列表。如果请求未经过重定向，则列表为空。
List<RedirectRecord> redirects;

/// 在 [RequestOptions] 中构造的自定义字段。
Map<String, dynamic> extra;

/// 响应对应的头数据。
Headers headers;
```

请求成功后，你可以访问到下列字段：

```dart
final response = await dio.get('https://pub.dev');
print(response.data);
print(response.headers);
print(response.requestOptions);
print(response.statusCode);
```

### 拦截器

每个 Dio 实例都可以添加任意多个拦截器，他们会组成一个队列，拦截器队列的执行顺序是先进先出。
通过使用拦截器，你可以在请求之前、响应之后和发生异常时（未被 `then` 或 `catchError` 处理）
做一些统一的预处理操作。

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      // 如果你想完成请求并返回一些自定义数据，你可以使用 `handler.resolve(response)`。
      // 如果你想终止请求并触发一个错误，你可以使用 `handler.reject(error)`。
      return handler.next(options);
    },
    onResponse: (Response response, ResponseInterceptorHandler handler) {
      // 如果你想终止请求并触发一个错误，你可以使用 `handler.reject(error)`。
      return handler.next(response);
    },
    onError: (DioError e, ErrorInterceptorHandler handler) {
      // 如果你想完成请求并返回一些自定义数据，你可以使用 `handler.resolve(response)`。
      return handler.next(e);
    },
  ),
);
```

一个简单的自定义拦截器示例:

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
  Future onError(DioError err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
```

#### 完成和终止请求/响应

在所有拦截器中，你都可以改变请求执行流，
如果你想完成请求/响应并返回自定义数据，你可以 resolve 一个 `Response` 对象
或返回 `handler.resolve(data)` 的结果。
如果你想终止（触发一个错误，上层 `catchError` 会被调用）一个请求/响应，
那么可以 reject 一个`DioError` 对象或返回 `handler.reject(errMsg)` 的结果。

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

如果同时发起多个网络请求，则它们是可以同时进入`Interceptor` 的（并行的），
而 `QueuedInterceptor` 提供了一种串行机制：
它可以保证请求进入拦截器时是串行的（前面的执行完后后面的才会进入拦截器）。

##### 例子

假设这么一个场景：出于安全原因，我们需要给所有的请求头中添加一个 `csrfToken`，
如果 `csrfToken` 不存在，我们先去请求 `csrfToken`，获取到 `csrfToken` 后再重试。
假设刚开始的时候 `csrfToken` 为 null，如果允许请求并发，则这些并发请求并行进入拦截器时
`csrfToken` 都为 null，所以它们都需要去请求 `csrfToken`，这会导致 `csrfToken` 被请求多次。
为了避免不必要的重复请求，可以使用 `QueuedInterceptor`， 这样只需要第一个请求处理一次即可。

完整的示例代码请点击 [这里](../example/lib/queued_interceptor_crsftoken.dart).

#### 日志拦截器

我们可以添加 `LogInterceptor` 拦截器来自动打印请求、响应日志：

```dart
dio.interceptors.add(LogInterceptor(responseBody: false)); // 不输出响应内容体
```

注意：由于拦截器队列是先进先出，`LogInterceptor` 应当在最后添加至 `Dio` 实例。

### 自定义拦截器

开发者可以通过继承 `Interceptor/QueuedInterceptor` 类来实现自定义拦截器。
这是一个简单的 [缓存拦截器](../example/lib/custom_cache_interceptor.dart)。

## 错误处理

当请求过程中发生错误时, Dio 会将 `Error/Exception` 包装成一个 `DioError`:

```dart
try {
  // 404
  await dio.get('https://api.pub.dev/not-exist');
} on DioError catch (e) {
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

### DioError

```dart
/// 错误的请求对应的配置。
RequestOptions requestOptions;

/// 错误的请求对应的响应内容。如果请求未完成，响应内容可能为空。
Response? response;

/// 错误的类型。
DioErrorType type;

/// 实际错误的内容。
Object? error;

/// 实际错误的堆栈。
StackTrace? stackTrace;

/// 错误信息。
String? message;
```

### DioErrorType

见 [源码](lib/src/dio_error.dart)。

## 使用 application/x-www-form-urlencoded 编码

默认情况下, Dio 会将请求数据（除了 `String` 类型）序列化为 JSON。
如果想要以 `application/x-www-form-urlencoded` 格式编码, 你可以设置 `contentType` :

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

## 发送 FormData

Dio 支持发送 `FormData`, 请求数据将会以 `multipart/form-data` 方式编码, 
`FormData` 中可以包含一个或多个文件。

```dart
final formData = FormData.fromMap({
  'name': 'dio',
  'date': DateTime.now().toIso8601String(),
  'file': await MultipartFile.fromFile('./text.txt',filename: 'upload.txt')
});
final response = await dio.post('/info', data: formData);
```

> 通常情况下只有 POST 方法支持发送 FormData。

这里有一个完整的 [示例](../example/lib/formdata.dart)。

### 多文件上传

多文件上传时，通过给 key 加中括号 `[]` 方式作为文件数组的标记，大多数后台也会通过 `key[]` 来读取多个文件。 
然而 RFC 标准中并没有规定多文件上传必须要使用 `[]`，关键在于后台与客户端之间保持一致。

```dart
final formData = FormData.fromMap({
  'files': [
    MultipartFile.fromFileSync('path/to/upload1.txt', filename: 'upload1.txt'),
    MultipartFile.fromFileSync('path/to/upload2.txt', filename: 'upload2.txt'),
  ],
});
```

最终编码时会 key 会为 `files[]`，
**如果不想添加 `[]`**，可以通过 `Formdata` 的 `files` 来构建：

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

### 复用 `FormData` 和 `MultipartFile`

如果你在重复调用的请求中使用 `FormData` 或者 `MultipartFile`，确保你每次使用的都是新实例。
常见的错误做法是将 `FormData` 赋值给一个共享变量，在每次请求中都使用这个变量。
这样的操作会加大 **无法序列化** 的错误出现的可能性。
你可以像以下的代码一样编写你的请求以避免出现这样的错误：
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

## 转换器

转换器 `Transformer` 用于对请求数据和响应数据进行编解码处理。
Dio 实现了一个默认转换器 `DefaultTransformer`。
如果你想对请求和响应数据进行自定义编解码处理，可以提供自定义转换器并通过 `dio.transformer` 设置。

> `Transformer.transformRequest` 只在 `PUT`/`POST`/`PATCH` 方法中生效，
> 只有这些方法可以使用请求内容体 (request body)。
> 但是 `Transformer.transformResponse` 可以用于所有请求方法的返回数据。

### 在 Flutter 中进行设置

如果你在开发 Flutter 应用，强烈建议通过 `compute` 在单独的 isolate 中进行 JSON 解码，
从而避免在解析复杂 JSON 时导致的 UI 卡顿。

```dart
/// 
Map<String, dynamic> _parseAndDecode(String response) {
  return jsonDecode(response) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  // 自定义 `jsonDecodeCallback`
  dio.transformer = DefaultTransformer()..jsonDecodeCallback = parseJson;
  runApp(MyApp());
}
```

### 其它示例

这里有一个 [自定义 Transformer 的示例](../example/lib/transformer.dart)。

## HttpClientAdapter

`HttpClientAdapter` 是 `Dio` 和 `HttpClient` 之间的桥梁。

`Dio` 实现了一套标准且强大的 API，而 `HttpClient` 则是真正发起 HTTP 请求的对象。

我们通过 `HttpClientAdapter` 将 `Dio` 和 `HttpClient` 解耦，
这样一来便可以自由定制 HTTP 请求的底层实现。
Dio 使用 `IOHttpClientAdapter` 作为原生平台默认的桥梁，
`BrowserClientAdapter` 作为 Web 平台的桥梁。
你可以通过 `HttpClientAdapter()` 来根据平台创建它们。

```dart
dio.httpClientAdapter = HttpClientAdapter();
```

如果你需要单独使用对应平台的适配器：
- 对于 Web 平台
  ```dart
  import 'package:dio/browser.dart';
  // ...
  dio.httpClientAdapter = BrowserClientAdapter();
  ```
- 对于原生平台：
  ```dart
  import 'package:dio/io.dart';
  // ...
  dio.httpClientAdapter = IOClientAdapter();
  ```

[示例](../example/lib/adapter.dart) 中包含了一个简单的自定义桥接。

### 设置代理

`IOHttpClientAdapter` 提供了一个 `onHttpClientCreate` 回调来设置底层 `HttpClient` 的代理：

```dart
import 'package:dio/io.dart';

void initAdapter() {
  dio.httpClientAdapter = IOHttpClientAdapter()..onHttpClientCreate = (client) {
    // Config the client.
    client.findProxy = (uri) {
      // Forward all request to proxy "localhost:8888".
      return 'PROXY localhost:8888';
    };
    // You can also create a new HttpClient for Dio instead of returning,
    // but a client must being returned here.
    return client;
  };
}
```

完整的示例请查看 [这里](../example/lib/proxy.dart)。

### HTTPS 证书校验

HTTPS 证书验证（或公钥固定）是指确保端侧与服务器的 TLS 连接的证书是期望的证书，从而减少中间人攻击的机会。
[OWASP](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning) 中解释了该理论。

**服务器响应证书**

与其他方法不同，此方法使用服务器本身的证书。

```dart
void initAdapter() {
  const String fingerprint = 'ee5ce1dfa7a53657c545c62b65802e4272878dabd65c0aadcf85783ebb0b4d5c';
  dio.httpClientAdapter = IOHttpClientAdapter()..onHttpClientCreate = (_) {
    // Don't trust any certificate just because their root cert is trusted.
    final HttpClient client = HttpClient(context: SecurityContext(withTrustedRoots: false));
    // You can test the intermediate / root cert here. We just ignore it.
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }..validateCertificate = (cert, host, port) {
    // Check that the cert fingerprint matches the one we expect.
    // We definitely require _some_ certificate.
    if (cert == null) {
      return false;
    }
    // Validate it any way you want. Here we only check that
    // the fingerprint matches the OpenSSL SHA256.
    return fingerprint == sha256.convert(cert.der).toString();
  };
}
```

你可以使用 OpenSSL 读取密钥的 SHA-256：

```sh
openssl s_client -servername pinning-test.badssl.com -connect pinning-test.badssl.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -noout -fingerprint -sha256

# SHA256 Fingerprint=EE:5C:E1:DF:A7:A5:36:57:C5:45:C6:2B:65:80:2E:42:72:87:8D:AB:D6:5C:0A:AD:CF:85:78:3E:BB:0B:4D:5C
# (remove the formatting, keep only lower case hex characters to match the `sha256` above)
```

**证书颁发机构验证**

当您的服务器具有自签名证书时，可以用下面的方法，但它们不适用于 AWS 或 Let's Encrypt 等第三方颁发的证书。

有两种方法可以校验证书，假设我们的后台服务使用的是自签名证书，证书格式是 PEM 格式，我们将证书的内容保存在本地字符串中，
那么我们的校验逻辑如下：

```dart
void initAdapter() {
  String PEM = 'XXXXX'; // root certificate content
  dio.httpClientAdapter = IOHttpClientAdapter()..onHttpClientCreate = (client) {
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return cert.pem == PEM; // Verify the certificate.
    };
    return client;
  };
}
```

对于自签名的证书，我们也可以将其添加到本地证书信任链中，
这样证书验证时就会自动通过，而不会再走到 `badCertificateCallback` 回调中：

```dart
void initAdapter() {
  String PEM = 'XXXXX'; // root certificate content
  dio.httpClientAdapter = IOHttpClientAdapter()..onHttpClientCreate = (_) {
    final SecurityContext sc = SecurityContext();
    sc.setTrustedCertificates(File(pathToTheCertificate));
    final HttpClient client = HttpClient(context: sc);
    return client;
  };
}
```

注意，通过 `setTrustedCertificates()` 设置的证书格式必须为 PEM 或 PKCS12，
如果证书格式为 PKCS12，则需将证书密码传入，
这样则会在代码中暴露证书密码，所以客户端证书校验不建议使用 PKCS12 格式的证书。

## HTTP/2 支持

[dio_http2_adapter](../plugins/http2_adapter) 提供了一个支持 HTTP/2 的桥接 。

## 请求取消

你可以通过 `CancelToken` 来取消发起的请求。
一个 `CancelToken` 可以给多个请求共用，
在共用时调用 `cancel()` 会取消对应的所有请求：

```dart
final cancelToken = CancelToken();
dio.get(url, cancelToken: cancelToken).catchError((DioError err) {
  if (CancelToken.isCancel(err)) {
    print('Request canceled: ${err.message};);
  } else{
    // handle error.
  }
});
// Cancel the requests with "cancelled" message.
token.cancel('cancelled');
```

完整的示例请参考 [取消示例](../example/lib/cancel_request.dart).

## 继承 Dio class

`Dio` 是一个拥有工厂构造函数的接口类，因此不能直接继承 `Dio`，
但是可以继承 `DioForNative` 或 `DioForBrowser`： 

```dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
// 在浏览器中，导入 'package:dio/browser.dart'。

class Http extends DioForNative {
  Http([BaseOptions options]) : super(options) {
    // 构造函数执行
  }
}
```

我们也可以直接实现 `Dio` 接口类 :

```dart
class MyDio with DioMixin implements Dio {
  // ...
}
```
