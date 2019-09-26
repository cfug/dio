# 从2.1.x升级到 3.x

3.x为了同时支持Flutter、Flutter  web，对项目进行了较大的重构，因此无法直接兼容2.1.x， 如果你是2.1.x用户，可以按照本文档指引升级到3.x。

## 3.x 主要特性

- 支持Flutter  web
- 将[CookieManager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager)抽离为单独的包
- 提供了Http/2.0 adapter.

## API变化

### Options

1. 删除`Options.cookies`属性
   - Cookie相关操作应该聚焦在`CookieManager`中。
   - Cookie在web中不需要手动管理，而`options`中的配置项应该尽量通用。

2. 删除`Options.connectTimeout`，这是因为在Http/1.1 Keep-alive特性和Http/2中，多个请求可能复用一个Socket连接。而`connectTimeout`表示的是请求是建立Socket连接的超时时间，一旦Socket连接建立，那么随后的Http请求都可能会复用它，而`Options`中的属性代表每一次Http请求都可以单独配置的，因此`connectTimeout`应该被从`Options`中移除。现在我们可以在`BaseOptions`（Dio实例配置）中来设置`connectTimeout`，Dio将会在建立Socket连接时来通过它设置建立连接的超时时间。
3. 重定向相关的属性字段（如Option中的`followRedirects`、`maxRedirects`，`Response`的`redirects`等）在Flutter Web中是无意义的，这是因为浏览器中用于发送http请求的内置对象XMLHttpRequest不支持重定向相关的跟踪。实际上重定向相关属性是否有意义取决于`Dio`的`HttpClientAdapter`实现，Dio默认的`DefaultHttpClientAdapter`在Flutter和Dart VM下都支持重定向跟踪，开发者可以放心使用。但如果您要自定义`HttpClientAdapter`，那么请注意是否支持重定向。

### FormData

`FormData`进行了较大的变化，具体体现在：

- ~~FormData.from~~更名为`FormData.fromMap`，语义化更明确。另外对于嵌套Map支持多级编码（之前对于MapEntry的value会直接调用`toString()`作为字段值）。
- 对于读取`FormData`的方法：废弃了~~asBytes()~~、~~asBytesAsync()~~两个方法，取代他们的是两个新方法`readAsBytes()`和`finalize()`，前者会将`FormData`内容读取到一个Byte数组中，而后者会返回一个Stream（流），用于支持Stream读取。实际上`readAsBytes()`也是通过Stream来读取`FormData`的，然后将读取到的数据保存在一个Byte数组中，因此，有一点需要特别注意：**一个`FormData`对象只能被读取一次**（因为一个Steam只能被读取一次）。
- 删除~~UploadFileInfo~~类，引入了`MultipartFile`类；`MultipartFile`类不仅支持通过文件来构造上传头块，也支持通过Stream、Byte数组、字符串来构造。

### Response

- `Response.headers` 类型从 `HttpHeaders`更改为自定义的`Headers`类。这是因为`HttpHeaders`是"dart:io"库中定义的类，而Flutter Web中不能使用"dart:io"库，所以为了一致，添加了一个自定义的`Headers`类。

### 拦截器

- 拦截器回调返回值类型从`FutureOr<dynamic>` 变更为`Future`。具体原因见[这里](https://dart.dev/guides/language/effective-dart/design#avoid-using-futureort-as-a-return-type)。

- 将CookieManager抽离成了单独的包；这是因为在Flutter web中不需要手动管理Cookie（浏览器会自动管理），因此将其抽为单独的插件按需引入会更合理。

  