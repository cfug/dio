

文档语言: [English](https://github.com/flutterchina/dio) | [English](README.md)

> 中文文档更新会较慢，请优先查看英文文档 [English](README.md)。

# dio

dio是一个强大的Dart Http请求库，支持Restful API、FormData、拦截器、请求取消、Cookie管理、文件上传/下载、超时、自定义适配器等...


## 添加依赖

```yaml
dependencies:
  dio: ^4.0.6
```

> 如果你是dio 3.x 用户，想了解4.0的变更，请参考 [4.x更新列表](./migration_to_4.x.md)!

## 一个极简的示例

```dart
import 'package:dio/dio.dart';
void getHttp() async {
  try {
    var response = await Dio().get('http://www.google.com');
    print(response);
  } catch (e) {
    print(e);
  }
}
```


## awesome-dio

🎉 A curated list of awesome things related to dio.

| Plugins                                                      | Status                                                       | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [dio_cookie_manager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager) | [![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_http2_adapter) | A cookie manager for Dio                                     |
| [dio_http2_adapter](https://github.com/flutterchina/dio/tree/master/plugins/http2_adapter) | [![Pub](https://img.shields.io/pub/v/dio_cookie_manager.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_cookie_manager) | A Dio HttpClientAdapter which support Http/2.0               |
| [dio_smart_retry](https://github.com/rodion-m/dio_smart_retry) | [![Pub](https://img.shields.io/pub/v/dio_smart_retry.svg?style=flat-square)](https://pub.dev/packages/dio_smart_retry) | Flexible retry library for Dio               |
| [http_certificate_pinning](https://github.com/diefferson/http_certificate_pinning) | [![Pub](https://img.shields.io/pub/v/http_certificate_pinning.svg?style=flat-square)](https://pub.dev/packages/http_certificate_pinning) | Https Certificate pinning for Flutter             |
| [curl_logger_dio_interceptor](https://github.com/OwnWeb/curl_logger_dio_interceptor) | [![Pub](https://img.shields.io/pub/v/curl_logger_dio_interceptor.svg?style=flat-square)](https://pub.dev/packages/curl_logger_dio_interceptor) | A Flutter curl-command generator for Dio.             |
| [dio_cache_interceptor](https://github.com/llfbandit/dio_cache_interceptor) | [![Pub](https://img.shields.io/pub/v/dio_cache_interceptor.svg?style=flat-square)](https://pub.dev/packages/dio_cache_interceptor) | Dio HTTP cache interceptor with multiple stores respecting HTTP directives (or not)             |
| [dio_http_cache](https://github.com/hurshi/dio-http-cache) | [![Pub](https://img.shields.io/pub/v/dio_http_cache.svg?style=flat-square)](https://pub.dev/packages/dio_http_cache) | A simple cache library for Dio like Rxcache in Android             |
| [pretty_dio_logger](https://github.com/Milad-Akarie/pretty_dio_logger) | [![Pub](https://img.shields.io/pub/v/pretty_dio_logger.svg?style=flat-square)](https://pub.dev/packages/pretty_dio_logger) | Pretty Dio logger is a Dio interceptor that logs network calls in a pretty, easy to read format.            |


如果您也想提供第三方组件，请移步 [here](https://github.com/flutterchina/dio/issues/347) .


## 内容列表

- [dio](#dio)
  - [添加依赖](#添加依赖)
  - [一个极简的示例](#一个极简的示例)
  - [内容列表](#内容列表)
  - [示例](#示例)
    - [示例目录](#示例目录)
  - [Dio APIs](#dio-apis)
    - [创建一个Dio实例，并配置它](#创建一个dio实例并配置它)
    - [请求方法别名](#请求方法别名)
  - [请求配置](#请求配置)
  - [响应数据](#响应数据)
  - [拦截器](#拦截器)
    - [完成和终止请求/响应](#完成和终止请求响应)
    - [QueuedInterceptor](#queuedinterceptor)
      - [例子](#例子)
    - [日志](#日志)
    - [Cookie管理](#cookie管理)
    - [自定义拦截器](#自定义拦截器)
  - [错误处理](#错误处理)
    - [DioError 字段](#dioerror-字段)
    - [DioErrorType](#dioerrortype)
  - [使用application/x-www-form-urlencoded编码](#使用applicationx-www-form-urlencoded编码)
  - [FormData](#formdata)
    - [多文件上传](#多文件上传)
  - [转换器](#转换器)
    - [Flutter中设置](#flutter中设置)
    - [其它示例](#其它示例)
    - [执行流](#执行流)
  - [HttpClientAdapter](#httpclientadapter)
    - [设置Http代理](#设置http代理)
    - [Https证书校验](#https证书校验)
  - [Http2支持](#http2支持)
  - [请求取消](#请求取消)
  - [继承 Dio class](#继承-dio-class)
  - [Copyright & License](#copyright--license)
  - [Features and bugs](#features-and-bugs)
  - [支持](#支持)


## 示例

发起一个 `GET` 请求 :

```dart
Response response;
var dio = Dio();
response = await dio.get('/test?id=12&name=wendu');
print(response.data.toString());
// Optionally the request above could also be done as
response = await dio.get('/test', queryParameters: {'id': 12, 'name': 'wendu'});
print(response.data.toString());
```

发起一个 `POST` 请求:

```dart
response = await dio.post('/test', data: {'id': 12, 'name': 'wendu'});
```

发起多个并发请求:

```dart
response = await Future.wait([dio.post('/info'), dio.get('/token')]);
```

下载文件:

```dart
response = await dio.download('https://www.google.com/', './xx.html');
```

以流的方式接收响应数据：

```dart
Response<ResponseBody> rs;
rs = await Dio().get<ResponseBody>(url,
  options: Options(responseType: ResponseType.stream),  //设置接收类型为stream
);
print(rs.data.stream); //响应流
```

以二进制数组的方式接收响应数据：

```dart
Response<List<int>> rs 
rs = await Dio().get<List<int>>(url,
 options: Options(responseType: ResponseType.bytes), //设置接收类型为二进制数组
);
print(rs.data); // 二进制数组
```

发送 FormData:

```dart
var formData = FormData.fromMap({
  'name': 'wendux',
  'age': 25,
});
var response = await dio.post('/info', data: formData);
```

通过FormData上传多个文件:

```dart
var formData = FormData.fromMap({
  'name': 'wendux',
  'age': 25,
  'file': await MultipartFile.fromFile('./text.txt', filename: 'upload.txt'),
  'files': [
    await MultipartFile.fromFile('./text1.txt', filename: 'text1.txt'),
    await MultipartFile.fromFile('./text2.txt', filename: 'text2.txt'),
  ]
});
var response = await dio.post('/info', data: formData);
```

监听发送(上传)数据进度:

```dart
response = await dio.post(
  'http://www.dtworkroom.com/doris/1/2.0.0/test',
  data: {'aa': 'bb' * 22},
  onSendProgress: (int sent, int total) {
    print('$sent $total');
  },
);
```

以流的形式提交二进制数据：

```dart

List<int> postData = <int>[...];
await dio.post(
  url,
  data: Stream.fromIterable(postData.map((e) => [e])), //创建一个Stream<List<int>>
  options: Options(
    headers: {
      Headers.contentLengthHeader: postData.length, // 设置content-length
    },
  ),
);

// 二进制数据
List<int> postData = <int>[...];

await dio.post(
  url,
  data: Stream.fromIterable(postData.map((e) => [e])), //创建一个Stream<List<int>>
  options: Options(
    headers: {
      Headers.contentLengthHeader: postData.length, // 设置content-length
    },
  ),
);
```

注意：如果要监听提交进度，则必须设置content-length，否则是可选的。

### 示例目录

你可以在这里查看dio的[全部示例](https://github.com/flutterchina/dio/tree/master/example).

## Dio APIs

### 创建一个Dio实例，并配置它

> 建议在项目中使用Dio单例，这样便可对同一个dio实例发起的所有请求进行一些统一的配置，比如设置公共header、请求基地址、超时时间等；这里有一个在[Flutter工程中使用Dio单例](https://github.com/flutterchina/dio/tree/master/example/flutter_example)（定义为top level变量）的示例供开发者参考。

你可以使用默认配置或传递一个可选 `BaseOptions`参数来创建一个Dio实例 :

```dart
var dio = Dio(); // with default Options

// Set default configs
dio.options.baseUrl = 'https://www.xx.com/api';
dio.options.connectTimeout = 5000; //5s
dio.options.receiveTimeout = 3000;

// or new Dio with a BaseOptions instance.
var options = BaseOptions(
  baseUrl: 'https://www.xx.com/api',
  connectTimeout: 5000,
  receiveTimeout: 3000,
);
Dio dio = Dio(options);
```



Dio实例的核心API是 :

**Future<Response> request(String path, {data,Map queryParameters, Options options,CancelToken cancelToken, ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress)**

```dart
response = await dio.request(
  '/test',
  data: {'id':12,'name':'xx'},
  options: Options(method:'GET'),
);
```

### 请求方法别名

为了方便使用，Dio提供了一些其它的Restful API, 这些API都是`request`的别名。

```dart
Future<Response> get(...)

Future<Response> post(...)

Future<Response> put(...)

Future<Response> delete(...)

Future<Response> head(...)

Future<Response> put(...)

Future<Response> path(...)

Future<Response> download(...)

Future<Response> fetch(RequestOptions)
```


## 请求配置

`BaseOptions`描述的是Dio实例发起网络请求的的公共配置，而`Options`类描述了每一个Http请求的配置信息，每一次请求都可以单独配置，单次请求的`Options`中的配置信息可以覆盖`BaseOptions`中的配置，下面是`BaseOptions`的配置项：

```dart
{
  /// Http method.
  String method;

  /// 请求基地址,可以包含子路径，如: "https://www.google.com/api/".
  String baseUrl;

  /// Http请求头.
  Map<String, dynamic> headers;

  /// 连接服务器超时时间，单位是毫秒.
  int connectTimeout;
  /// 2.x中为接收数据的最长时限.
  int receiveTimeout;

  /// 请求路径，如果 `path` 以 "http(s)"开始, 则 `baseURL` 会被忽略； 否则,
  /// 将会和baseUrl拼接出完整的的url.
  String path = "";

  /// 请求的Content-Type，默认值是"application/json; charset=utf-8".
  /// 如果您想以"application/x-www-form-urlencoded"格式编码请求数据,
  /// 可以设置此选项为 `Headers.formUrlEncodedContentType`,  这样[Dio]
  /// 就会自动编码请求体.
  String contentType;

  /// [responseType] 表示期望以那种格式(方式)接受响应数据。
  /// 目前 [ResponseType] 接受三种类型 `JSON`, `STREAM`, `PLAIN`.
  ///
  /// 默认值是 `JSON`, 当响应头中content-type为"application/json"时，dio 会自动将响应内容转化为json对象。
  /// 如果想以二进制方式接受响应数据，如下载一个二进制文件，那么可以使用 `STREAM`.
  ///
  /// 如果想以文本(字符串)格式接收响应数据，请使用 `PLAIN`.
  ResponseType responseType;

  /// `validateStatus` 决定http响应状态码是否被dio视为请求成功， 返回`validateStatus`
  ///  返回`true` , 请求结果就会按成功处理，否则会按失败处理.
  ValidateStatus validateStatus;

  /// 用户自定义字段，可以在 [Interceptor]、[Transformer] 和 [Response] 中取到.
  Map<String, dynamic> extra;

  /// Common query parameters
  Map<String, dynamic /*String|Iterable<String>*/ > queryParameters;
  
  /// 请求数据中数组的编码的方式，具体可以参考CollectionFormat的定义
  late CollectionFormat collectionFormat;
}
```

这里有一个完成的[示例](https://github.com/flutterchina/dio/blob/master/example/options.dart).

## 响应数据

当请求成功时会返回一个Response对象，它包含如下字段：

```dart
{
  /// 响应数据，可能已经被转换了类型, 详情请参考Options中的[ResponseType].
  T data;
  /// 响应头
  Headers headers;
  /// 本次请求信息
  Options request;
  /// Http status code.
  int? statusCode;
  String? statusMessage;
  /// 是否重定向(Flutter Web不可用)
  bool? isRedirect;
  /// 重定向信息(Flutter Web不可用)
  List<RedirectInfo> redirects ;
  /// 真正请求的url(重定向最终的uri)
  Uri realUri;
  /// 响应对象的自定义字段（可以在拦截器中设置它），调用方可以在`then`中获取.
  Map<String, dynamic> extra;
}
```

示例如下:

```dart
Response response = await dio.get('https://www.google.com');
print(response.data);
print(response.headers);
print(response.requestOptions);
print(response.statusCode);
```

## 拦截器

每个 Dio 实例都可以添加任意多个拦截器，他们组成一个队列，拦截器队列的执行顺序是FIFO。通过拦截器你可以在请求之前、响应之后和发生异常时(但还没有被 `then` 或 `catchError`处理)做一些统一的预处理操作。

```dart
dio.interceptors.add(InterceptorsWrapper(
    onRequest:(options, handler){
     // Do something before request is sent
     return handler.next(options); //continue
     // 如果你想完成请求并返回一些自定义数据，你可以resolve一个Response对象 `handler.resolve(response)`。
     // 这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.
     //
     // 如果你想终止请求并触发一个错误,你可以返回一个`DioError`对象,如`handler.reject(error)`，
     // 这样请求将被中止并触发异常，上层catchError会被调用。
    },
    onResponse:(response,handler) {
     // Do something with response data
     return handler.next(response); // continue
     // 如果你想终止请求并触发一个错误,你可以 reject 一个`DioError`对象,如`handler.reject(error)`，
     // 这样请求将被中止并触发异常，上层catchError会被调用。
    },
    onError: (DioError e, handler) {
     // Do something with response error
     return  handler.next(e);//continue
     // 如果你想完成请求并返回一些自定义数据，可以resolve 一个`Response`,如`handler.resolve(response)`。
     // 这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.
    }
));
```

一个简单的自定义拦截器示例:

```dart
import 'package:dio/dio.dart';
class CustomInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    return super.onRequest(options, handler);
  }
  @override
  Future onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions?.path}');
    return super.onResponse(response, handler);
  }
  @override
  Future onError(DioError err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions?.path}');
    return super.onError(err, handler);
  }
}
```

### 完成和终止请求/响应

在所有拦截器中，你都可以改变请求执行流， 如果你想完成请求/响应并返回自定义数据，你可以resolve一个 `Response` 对象或返回 `handler.resolve(data)`的结果。 如果你想终止(触发一个错误，上层`catchError`会被调用)一个请求/响应，那么可以reject一个`DioError` 对象或返回 `handler.reject(errMsg)` 的结果.

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest:(options, handler) {
   return handler.resolve(Response(requestOptions:options,data:'fake data'));
  },
));
Response response = await dio.get('/test');
print(response.data);//'fake data'
```

### QueuedInterceptor

如果同时发起多个网络请求，则它们是可以同时进入`Interceptor` 的（并行的），而 `QueuedInterceptor` 提供了一种串行机制：它可以保证请求进入拦截器时是串行的（前面的执行完后后面的才会进入拦截器）。

#### 例子

假设这么一个场景：出于安全原因，我们需要给所有的请求头中添加一个csrfToken，如果csrfToken不存在，我们先去请求csrfToken，获取到csrfToken后再重试。假设刚开始的时候 csrfToken 为 null ，如果允许请求并发，则这些并发请求并行进入拦截器时 csrfToken 都为null，所以它们都需要去请求 csrfToken，这会导致 csrfToken 被请求多次，为了避免不必要的重复请求，可以使用 QueuedInterceptor，这样只需要第一个请求请求一次即可，示例代码如下：

```dart
dio.interceptors.add(QueuedInterceptorsWrapper(
  onRequest: (options, handler) async {
    print('send request：path:${options.path}，baseURL:${options.baseUrl}');
    if (csrfToken == null) {
      print('no token，request token firstly...');
      tokenDio.get('/token').then((d) {
        options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
        print('request token succeed, value: ' + d.data['data']['token']);
        print( 'continue to perform request：path:${options.path}，baseURL:${options.path}');
        handler.next(options);
      }).catchError((error, stackTrace) {
        handler.reject(error, true);
      });
    } else {
      options.headers['csrfToken'] = csrfToken;
      handler.next(options);
    }
  }
));
```

完整的示例代码请点击 [这里](https://github.com/flutterchina/dio/blob/develop/example/queued_interceptor_crsftoken.dart).

### 日志

我们可以添加  `LogInterceptor` 拦截器来自动打印请求、响应日志, 如:

```dart
dio.interceptors.add(LogInterceptor(responseBody: false)); //开启请求日志
```

> 由于拦截器队列的执行顺序是FIFO，如果把log拦截器添加到了最前面，则后面拦截器对`options`的更改就不会被打印（但依然会生效）， 所以建议把log拦截添加到队尾。

### Cookie管理

[dio_cookie_manager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager) 包是Dio的一个插件，它提供了一个Cookie管理器。详细示例可以移步[dio_cookie_manager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager) 。

### 自定义拦截器

开发者可以通过继承`Interceptor/QueuedInterceptor` 类来实现自定义拦截器，这是一个简单的[缓存示例拦截器](https://github.com/flutterchina/dio/blob/master/example/custom_cache_interceptor.dart)。

## 错误处理

当请求过程中发生错误时, Dio 会包装 `Error/Exception` 为一个 `DioError`:

```dart
try {
  //404
  await dio.get('https://wendux.github.io/xsddddd');
} on DioError catch (e) {
  // The request was made and the server responded with a status code
  // that falls out of the range of 2xx and is also not 304.
  if (e.response) {
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

### DioError 字段

```dart
 {
  /// Request info.
  RequestOptions request;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response response;

  /// 错误类型，见下文
  DioErrorType type;

  ///原始的error或exception对象，通常type为DEFAULT时存在。
  dynamic error;
}
```

### DioErrorType

```dart
enum DioErrorType {
  /// It occurs when url is opened timeout.
  connectTimeout,

  /// It occurs when url is sent timeout.
  sendTimeout,

  ///It occurs when receiving timeout.
  receiveTimeout,

  /// When the server response, but with a incorrect status, such as 404, 503...
  response,

  /// When the request is cancelled, dio will throw a error with this type.
  cancel,

  /// Default error type, Some other Error. In this case, you can
  /// use the DioError.error if it is not null.
  other,
}
```



## 使用application/x-www-form-urlencoded编码

默认情况下, Dio 会将请求数据(除过String类型)序列化为 `JSON`. 如果想要以 `application/x-www-form-urlencoded`格式编码, 你可以显式设置`contentType` :

```dart
//Instance level
dio.options.contentType= Headers.formUrlEncodedContentType;
//or works once
dio.post(
  '/info',
  data: {'id': 5},
  options: Options(contentType: Headers.formUrlEncodedContentType),
);
```

这里有一个[示例](https://github.com/flutterchina/dio/blob/6de8289ea71b0b7803654caaa2e9d3d47a588ab7/example/options.dart#L41).

## FormData

Dio支持发送 FormData, 请求数据将会以 `multipart/form-data`方式编码, FormData中可以一个或多个包含文件 .

```dart
var formData = FormData.fromMap({
  'name': 'wendux',
  'age': 25,
  'file': await MultipartFile.fromFile('./text.txt',filename: 'upload.txt')
});
response = await dio.post('/info', data: formData);
```

> 注意: 只有 post 方法支持发送 FormData.

这里有一个完整的[示例](https://github.com/flutterchina/dio/blob/master/example/formdata.dart).

### 多文件上传

多文件上传时，通过给key加中括号“[]”方式作为文件数组的标记，大多数后台也会通过key[]这种方式来读取。不过RFC中并没有规定多文件上传就必须得加“[]”，所以有时不带“[]”也是可以的，关键在于后台和客户端得一致。v3.0.0 以后通过`Formdata.fromMap()`创建的`Formdata`,如果有文件数组，是默认会给key加上“[]”的，比如：

```dart
FormData.fromMap({
  'files': [
    MultipartFile.fromFileSync('./example/upload.txt', filename: 'upload.txt'),
    MultipartFile.fromFileSync('./example/upload.txt', filename: 'upload.txt'),
  ]
});
```

最终编码时会key会为 "files[]"，**如果不想添加“[]”**，可以通过`Formdata`的API来构建：

```dart
var formData = FormData();
formData.files.addAll([
  MapEntry('files',
    MultipartFile.fromFileSync('./example/upload.txt',filename: 'upload.txt'),
  ),
  MapEntry('files',
    MultipartFile.fromFileSync('./example/upload.txt',filename: 'upload.txt'),
  ),
]);
```

这样构建的`FormData`的key是不会有“[]”。

## 转换器

转换器`Transformer` 用于对请求数据和响应数据进行编解码处理。Dio实现了一个默认转换器`DefaultTransformer`作为默认的 `Transformer`. 如果你想对请求/响应数据进行自定义编解码处理，可以提供自定义转换器，通过 `dio.transformer`设置。

> 请求转换器  `Transformer.transformRequest(...)`   只会被用于 'PUT'、 'POST'、 'PATCH'方法，因为只有这些方法才可以携带请求体(request body)。但是响应转换器 `Transformer.transformResponse()` 会被用于所有请求方法的返回数据。

### Flutter中设置

如果你在开发Flutter应用，强烈建议json的解码通过compute方法在后台进行，这样可以避免在解析复杂json时导致的UI卡顿。

> 注意，根据笔者实际测试，发现通过`compute`在后台解码json耗时比直接解码慢很多，建议开发者仔细评估。

```dart
// 必须是顶层函数
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  ...
  // 自定义 jsonDecodeCallback
  (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  runApp(MyApp());
}
```

### 其它示例

这里有一个 [自定义Transformer的示例](https://github.com/flutterchina/dio/blob/master/example/transfomer.dart).

### 执行流

虽然在拦截器中也可以对数据进行预处理，但是转换器主要职责是对请求/响应数据进行编解码，之所以将转化器单独分离，一是为了和拦截器解耦，二是为了不修改原始请求数据(如果你在拦截器中修改请求数据(options.data)，会覆盖原始请求数据，而在某些时候您可能需要原始请求数据). Dio的请求流是：

*请求拦截器* >> *请求转换器* >> *发起请求*  >> *响应转换器*  >> *响应拦截器*  >> *最终结果*。

这是一个自定义转换器的[示例](https://github.com/flutterchina/dio/blob/master/example/transfomer.dart).

## HttpClientAdapter

HttpClientAdapter是 Dio 和 HttpClient之间的桥梁。2.0抽象出adapter主要是方便切换、定制底层网络库。Dio实现了一套标准的、强大API，而HttpClient则是真正发起Http请求的对象。我们通过HttpClientAdapter将Dio和HttpClient解耦，这样一来便可以自由定制Http请求的底层实现，比如，在Flutter中我们可以通过自定义HttpClientAdapter将Http请求转发到Native中，然后再由Native统一发起请求。再比如，假如有一天OKHttp提供了dart版，你想使用OKHttp发起http请求，那么你便可以通过适配器来无缝切换到OKHttp，而不用改之前的代码。

Dio 使用`DefaultHttpClientAdapter`作为其默认HttpClientAdapter，`DefaultHttpClientAdapter`使用`dart:io:HttpClient` 来发起网络请求。



### 设置Http代理

`DefaultHttpClientAdapter` 提供了一个`onHttpClientCreate` 回调来设置底层 `HttpClient`的代理，我们想使用代理，可以参考下面代码：

```dart
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
...
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  // config the http client
  client.findProxy = (uri) {
    //proxy all request to localhost:8888
    return 'PROXY localhost:8888';
  };
  // you can also create a HttpClient to dio
  // return HttpClient();
};
```

完整的示例请查看[这里](https://github.com/flutterchina/dio/blob/master/example/proxy.dart).

### Https证书校验

有两种方法可以校验https证书，假设我们的后台服务使用的是自签名证书，证书格式是PEM格式，我们将证书的内容保存在本地字符串中，那么我们的校验逻辑如下：

```dart
String PEM='XXXXX'; // certificate content
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate  = (client) {
  client.badCertificateCallback=(X509Certificate cert, String host, int port){
    if(cert.pem==PEM){ // Verify the certificate
      return true;
    }
    return false;
  };
};
```

`X509Certificate`是证书的标准格式，包含了证书除私钥外所有信息，读者可以自行查阅文档。另外，上面的示例没有校验host，是因为只要服务器返回的证书内容和本地的保存一致就已经能证明是我们的服务器了（而不是中间人），host验证通常是为了防止证书和域名不匹配。

对于自签名的证书，我们也可以将其添加到本地证书信任链中，这样证书验证时就会自动通过，而不会再走到`badCertificateCallback`回调中：

```dart
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate  = (client) {
  SecurityContext sc = SecurityContext();
  //file is the path of certificate
  sc.setTrustedCertificates(file);
  HttpClient httpClient = HttpClient(context: sc);
  return httpClient;
};
```

注意，通过`setTrustedCertificates()`设置的证书格式必须为PEM或PKCS12，如果证书格式为PKCS12，则需将证书密码传入，这样则会在代码中暴露证书密码，所以客户端证书校验不建议使用PKCS12格式的证书。

## Http2支持

[dio_http2_adapter](https://github.com/flutterchina/dio/tree/master/plugins/http2_adapter) 包提供了一个支持Http/2.0的Adapter，详情可以移步 [dio_http2_adapter](https://github.com/flutterchina/dio/tree/master/plugins/http2_adapter) 。

## 请求取消

你可以通过 *cancel token* 来取消发起的请求：

```dart
CancelToken token = CancelToken();
dio.get(url, cancelToken: token)
    .catchError((DioError err){
      if (CancelToken.isCancel(err)) {
        print('Request canceled! '+ err.message)
      }else{
        // handle error.
      }
    });
// cancel the requests with "cancelled" message.
token.cancel("cancelled");
```

> 注意: 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。

完整的示例请参考[取消示例](https://github.com/flutterchina/dio/blob/master/example/cancel_request.dart).

## 继承 Dio class

`Dio` 是一个拥有factory 构造函数的接口类，因此不能直接继承 `Dio` ，但是可以通过  `DioForNative` 或`DioForBrowser` 来间接实现: 

```dart
import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart'; //在浏览器中, import 'package:dio/browser_imp.dart'

class Http extends DioForNative {
  Http([BaseOptions options]):super(options){
    // 构造函数做一些事
  }
}
```

我们也可以直接实现 `Dio`接口类 :

```dart
class MyDio with DioMixin implements Dio{
  // ...
}
```




## Copyright & License

此开源项目为Flutter中文网(https://flutterchina.club) 授权 ，license 是 MIT.   如果您喜欢，欢迎star.

**Flutter中文网开源项目计划**

开发一系列Flutter SDK之外常用(实用)的Package、插件，丰富Flutter第三方库，为Flutter生态贡献来自中国开发者的力量。所有项目将发布在 [Github Flutter中文网 Organization](https://github.com/flutterchina/) ，所有源码贡献者将加入到我们的Organization，成为成员. 目前社区已有几个开源项目开始公测，欢迎您加入开发或测试，详情请查看: [Flutter中文网开源项目](https://flutterchina.club/opensource.html)。 如果您想加入到“开源项目计划”， 请发邮件到824783146@qq.com， 并附上自我介绍(个人基本信息+擅长/关注技术)。

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/flutterchina/dio

## 支持

觉得对有帮助，请作者喝杯咖啡 (微信)：

![](https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0.3/docs/imgs/pay.jpeg)
