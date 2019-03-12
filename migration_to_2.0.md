# Dio V2.1.x 变更列表

### Restful API

2.1中对所有Restful API的变化有：

1. 支持`Uri`，在1.x中，Url只能是字符串，2.1中所有API都提供了对应支持Uri的版本，如get方法有`dio.get(...)`和`dio.gerUri(...)`。

2. 所有方法都支持`queryParameters`，2.1标准化了参数语义，并允许所有请求都可以传query，而data只针对可以提交请求体的方法如post作为请求体提交。另外相对于`Uri.queryParameters`，我们对Restful API中的`queryParameters`的功能做了加强，主要有两个差异：

   - 参数值类型不同；前者只能接受`Map<String, String|Iterable<String>>`类型的参数，而后者可以接受`Map<String, dynamic>`类型，比如:

     ```dart
     dio.getUri(Uri(url, queryParameters: {"age":15})) //会抛出异常，Uri.queryParameter的value不能是int类型
     dio.get(url, queryParameters: {"age":15}); //这是OK的！
     ```

   - 编码方式有所差异; `Uri.queryParameters`编码方式遵循Dart SDK中的规则，而Restful API中的`queryParameters`编码方式和jQuery一致，如：

     ```dart
       dio.options.baseUrl="http://domain.com/";

       //下面请求的最终uri为：http://domain.com/api?selectedId=1&selectedId=2
       Response response = await dio.getUri(
         Uri(path: "api",queryParameters:  {"selectedId": ["1", "2"],});
       );
       //下面请求的最终uri为：https://flutterchina.club?selectedId%5B%5D=1&selectedId%5B%5D=2
       dio.get("api",queryParameters: {"selectedId": ["1", "2"], });
     ```



3. 支持以Stream方式提交数据了；2.1中可以通过Stream的方式来提交二进制数据了，详细的示例可以参考[这里](https://github.com/flutterchina/dio/blob/master/example/post_stream_and_bytes.dart)。

4. 支持以二进制数组形式接收数据了；1.x中如果要以二进制形式接收响应数据则需要设置`options.responseType`为`ResponseType.stream` 来接收响应流，然后再通过读取响应流来获取完整的二进制内容，而2.x中只需要设置为`ResponseType.bytes`，则可直接获得响应流的而精致数组。

5. API统一添加了`onSendProgress` 和 `onReceiveProgress` 两个回调，用于监听发送数据和接收数据的具体精度，在1.x中只有在下载文件和上传formdata时才能监听进度，而2.x中所有接口都可以了。

### 拦截器

1. 支持设置多个拦截器；

   这样我们就可以将一些功能单独抽离，比如打印请求/响应日志和cookie管理都可以单独封装在一个拦截器中，这样在解耦的同时可以提高代码的可复用度。

   2.1中拦截器是一个队列，拦截器将会按照FIFO顺序执行，如果队列中的某个拦截器返回了Response或Error，则请求结束，队列后面的拦截器将不会再被执行。

2. 预置了打印请求/响应日志的LogInterceptor和管理cookie的CookieManager拦截器，开发者可以按需使用，如：

   ```dart
     dio.interceptors
       ..add(LogInterceptor(responseBody: false))
       ..add(CookieManager(CookieJar()));
   ```



### FormData

1.x中，在提交FormData时会先将FormData转成一个二进制数组，然后再提交，这在FormData中的数据量比较大时（如包含多个大文件）在上传的过程中会比较占用内存。2.1中我们队FormData进行了增强，给FormData添加一个stream属性，它可以将FormData转为一个stream，在提交时无需一次性加载到内存。

同时FormData也添加了`asBytes()` 、`asBytesAsync()`、`length`等方法、属性。

### Response

Response中添加了一些关于重定向信息的字段，有`isRedirect`、`redirects`、`realUri`。

### TransFormer

2.x中对于DefaultTransformer添加了一个`jsonDecodeCallback`，通过它可以定制json解码器，这在flutter中非常有用，我们可以通过`compute`方法来在后台进行json解码，从而避免在UI线程对复杂json解码时引起的界面卡顿，详情请见[这里](https://github.com/flutterchina/dio#in-flutter) 。

### HttpClientAdapter

HttpClientAdapter是 Dio 和 HttpClient之间的桥梁。2.0抽象出了adapter层，可以带来两个主要收益：

1. 实现Dio于HttpClient的解耦，这样可以方便的切换、定制底层网络库。
2. 可以Mock数据；

Dio实现了一套标准的、强大API，而HttpClient则是真正发起Http请求的对象，两者并不是固定的一对一关系，我们完全可以在使用Dio时通过其他网络库(而不仅仅是dart `HttpClient` )来发起网络请求。我们通过HttpClientAdapter将Dio和HttpClient解耦，这样一来便可以自由定制Http请求的底层实现，比如，在Flutter中我们可以通过自定义HttpClientAdapter将Http请求转发到Native中，然后再由Native统一发起请求。再比如，假如有一天OKHttp提供了dart版，你想使用OKHttp发起http请求，那么你便可以通过适配器来无缝切换到OKHttp，而不用改之前的代码。

Dio 使用`DefaultHttpClientAdapter`作为其默认HttpClientAdapter，`DefaultHttpClientAdapter`使用`dart:io:HttpClient` 来发起网络请求。

[这里](https://github.com/flutterchina/dio/blob/master/example/adapter.dart) 有一个简单的自定义Adapter的示例，读者可以参考。另外本项目的自动化测试用例全都是通过一个自定义的[MockAdapter](https://github.com/flutterchina/dio/blob/master/package_src/test/mock_adapter.dart)来模拟服务器返回数据的。

### Options

`Options`对象包含了对网络请求的配置，在1.x中无论是实例配置还是单次请求的配置都使用的是`Options` 对象，这样会带来一些二义性，甚至有时会让开发者感到疑惑，比如`Options.baseUrl`属性代表请求基地址，理论上它只应该在实例配置中设置，而不应该出现在每次请求的配置中；再比如`Options.path`属性，它代表请求的相对路径，不应该在实例请求配置中。2.1中将请求配置分拆成三个类：

| 类名           | 作用                                            |
| -------------- | ----------------------------------------------- |
| BaseOptions    | Dio实例基配置，默认对该dio实例的所有请求生效    |
| Options        | 单次请求配置，可以覆盖BaseOptions中的同名属性   |
| RequestOptions | 请求的最终配置，是对Option和BaseOptions合并后的 |

另外，添加了一些新的配置项：

1. `cookies`：可以添加一些公共cookie
2. `receiveDataWhenStatusError`：当响应状态码不是成功状态(如404)时，是否接收响应内容，如果是`false`,则`response.data`将会为null
3. `maxRedirects`: 重定向最大次数。

