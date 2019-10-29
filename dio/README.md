Language: [English](README.md) | [中文简体](README-ZH.md)

# dio

[![build status](https://img.shields.io/travis/flutterchina/dio/vm.svg?style=flat-square)](https://travis-ci.org/flutterchina/dio)
[![Pub](https://img.shields.io/pub/v/dio.svg?style=flat-square)](https://pub.dartlang.org/packages/dio)
[![support](https://img.shields.io/badge/platform-flutter%7Cflutter%20web%7Cdart%20vm-ff69b4.svg?style=flat-square)](https://github.com/flutterchina/dio)

A powerful Http client for Dart, which supports Interceptors, Global configuration, FormData, Request Cancellation, File downloading, Timeout etc. 

## Get started

### Add dependency

```yaml
dependencies:
  dio: 3.x #latest version
```
> In order to support Flutter Web, v3.x was heavily refactored, so it was not compatible with version 3.x See [here](https://github.com/flutterchina/dio/blob/master/dio/CHANGELOG.md) for a detailed list of updates.

### Super simple to use

```dart
import 'package:dio/dio.dart';
void getHttp() async {
  try {
    Response response = await Dio().get("http://www.google.com");
    print(response);
  } catch (e) {
    print(e);
  }
}
```

## awesome-dio

🎉 A curated list of awesome things related to dio.

### Plugins

| Plugins                                                      | Status                                                       | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [dio_cookie_manager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager) | [![Pub](https://img.shields.io/pub/v/dio_http2_adapter.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_http2_adapter) | A cookie manager for Dio                                     |
| [dio_http2_adapter](https://github.com/flutterchina/dio/tree/master/plugins/http2_adapter) | [![Pub](https://img.shields.io/pub/v/dio_cookie_manager.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_cookie_manager) | A Dio HttpClientAdapter which support Http/2.0               |
| [dio_flutter_transformer](https://github.com/flutterchina/dio_flutter_transformer) | [![Pub](https://img.shields.io/pub/v/dio_flutter_transformer.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_flutter_transformer) | A Dio transformer especially for flutter, by which the json decoding will be in background with `compute` function. |
| [dio_http_cache](https://github.com/hurshi/dio-http-cache)   | [![Pub](https://img.shields.io/pub/v/dio_http_cache.svg?style=flat-square)](https://pub.dartlang.org/packages/dio_http_cache) | A cache library for Dio, like [Rxcache](https://github.com/VictorAlbertos/RxCache) in Android. dio-http-cache uses [sqflite](https://github.com/tekartik/sqflite) as disk cache, and [LRU](https://github.com/google/quiver-dart) strategy as memory cache. |
| [retrofit](https://github.com/trevorwang/retrofit.dart/)     | [![Pub](https://img.shields.io/pub/v/retrofit.svg?style=flat-square)](https://pub.dartlang.org/packages/retrofit) | retrofit.dart is an dio client generator using source_gen and inspired by Chopper and Retrofit. |

### Related Projects

Welcome to submit Dio's third-party plugins and related libraries [here](https://github.com/flutterchina/dio/issues/347) .

## Table of contents

- [Examples](#examples)

- [Dio APIs](#dio-apis)

- [Request Options](#request-options)

- [Response Schema](#response-schema)

- [Interceptors](#interceptors)

- [Cookie Manager](#cookie-manager)

- [Handling Errors](#handling-errors)

- [Using application/x-www-form-urlencoded format](#using-applicationx-www-form-urlencoded-format)

- [Sending FormData](#sending-formdata)

- [Transformer](#Transformer)

- [Set proxy and HttpClient config](#set-proxy-and-httpclient-config)

- [Https certificate verification](#https-certificate-verification)

- [HttpClientAdapter](#httpclientadapter )

- [Cancellation](#cancellation)

- [Extends Dio class](#extends-dio-class)

- [Http2 support](#http2-support )

- [Features and bugs](#features-and-bugs)

  

## Examples

Performing a `GET` request:

```dart
Response response;
Dio dio = new Dio();
response = await dio.get("/test?id=12&name=wendu");
print(response.data.toString());
// Optionally the request above could also be done as
response = await dio.get("/test", queryParameters: {"id": 12, "name": "wendu"});
print(response.data.toString());
```

Performing a `POST` request:

```dart
response = await dio.post("/test", data: {"id": 12, "name": "wendu"});
```

Performing multiple concurrent requests:

```dart
response = await Future.wait([dio.post("/info"), dio.get("/token")]);
```

Downloading a file:

```dart
response = await dio.download("https://www.google.com/", "./xx.html");
```

Get response stream:

```dart
Response<ResponseBody> rs = await Dio().get<ResponseBody>(url,
 options: Options(responseType: ResponseType.stream), // set responseType to `stream`
);
print(rs.data.stream); //response stream
```

Get response with bytes:

```dart
Response<List<int>> rs = await Dio().get<List<int>>(url,
 options: Options(responseType: ResponseType.bytes), // // set responseType to `bytes`
);
print(rs.data); // List<int>
```

Sending FormData:

```dart
FormData formData = new FormData.fromMap({
    "name": "wendux",
    "age": 25,
  });
response = await dio.post("/info", data: formData);
```

Uploading multiple files to server by FormData:

```dart
FormData.fromMap({
    "name": "wendux",
    "age": 25,
    "file": await MultipartFile.fromFile("./text.txt",filename: "upload.txt"),
    "files": [
      await MultipartFile.fromFile("./text1.txt", filename: "text1.txt"),
      await MultipartFile.fromFile("./text2.txt", filename: "text2.txt"),
    ]
});
response = await dio.post("/info", data: formData);
```

Listening the uploading progress:

```dart
response = await dio.post(
  "http://www.dtworkroom.com/doris/1/2.0.0/test",
  data: {"aa": "bb" * 22},
  onSendProgress: (int sent, int total) {
    print("$sent $total");
  },
);
```
Post binary data by Stream:

```dart
// Binary data
List<int> postData = <int>[...];
await dio.post(
  url,
  data: Stream.fromIterable(postData.map((e) => [e])), //create a Stream<List<int>>
  options: Options(
    headers: {
      Headers.contentLengthHeader: postData.length, // set content-length
    },
  ),
);
```

…you can find all examples code [here](https://github.com/flutterchina/dio/tree/master/example).



## Dio APIs

### Creating an instance and set default configs.

You can create instance of Dio with an optional `BaseOptions` object:

```dart
Dio dio = new Dio(); // with default Options

// Set default configs
dio.options.baseUrl = "https://www.xx.com/api";
dio.options.connectTimeout = 5000; //5s
dio.options.receiveTimeout = 3000;

// or new Dio with a BaseOptions instance.
BaseOptions options = new BaseOptions(
    baseUrl: "https://www.xx.com/api",
    connectTimeout: 5000,
    receiveTimeout: 3000,
);
Dio dio = new Dio(options);
```

The core API in Dio instance is:

**Future<Response> request(String path, {data,Map queryParameters, Options options,CancelToken cancelToken, ProgressCallback onSendProgress,
    ProgressCallback onReceiveProgress)**

```dart
response=await request(
    "/test",
    data: {"id":12,"name":"xx"},
    options: Options(method:"GET"),
);
```

### Request method aliases

For convenience aliases have been provided for all supported request methods.

**Future<Response> get(...)**

**Future<Response> post(...)**

**Future<Response> put(...)**

**Future<Response> delete(...)**

**Future<Response> head(...)**

**Future<Response> put(...)**

**Future<Response> path(...)**

**Future<Response> download(...)**


## Request Options

The Options class describes the http request information and configuration. Each Dio instance has a base config for all requests maked by itself, and we can override the base config with [Options] when make a single request.  The  [BaseOptions] declaration as follows:

```dart
{
  /// Http method.
  String method;

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// Http request headers.
  Map<String, dynamic> headers;

   /// Timeout in milliseconds for opening  url.
  int connectTimeout;

   ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT].
  ///  Note: This is not the receiving time limitation.
  int receiveTimeout;

  /// Request data, can be any type.
  T data;

  /// If the `path` starts with "http(s)", the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path="";

  /// The request Content-Type. The default value is "application/json; charset=utf-8".
  /// If you want to encode request body with "application/x-www-form-urlencoded",
  /// you can set [Headers.formUrlEncodedContentType], and [Dio]
  /// will automatically encode the request body.
  String contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `JSON`, `STREAM`, `PLAIN`.
  ///
  /// The default value is `JSON`, dio will parse response string to json object automatically
  /// when the content-type of response is "application/json".
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `STREAM`.
  ///
  /// If you want to receive the response data with String, use `PLAIN`.
  ResponseType responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus validateStatus;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the   [Response] object.
  Map<String, dynamic> extra;
  
  /// Common query parameters
  Map<String, dynamic /*String|Iterable<String>*/ > queryParameters;  

}
```

There is a complete example [here](https://github.com/flutterchina/dio/blob/master/example/options.dart).

## Response Schema

The response for a request contains the following information.

```dart
{
  /// Response body. may have been transformed, please refer to [ResponseType].
  T data;
  /// Response headers.
  Headers headers;
  /// The corresponding request info.
  Options request;
  /// Http status code.
  int statusCode;
  /// Whether redirect 
  bool isRedirect;  
  /// redirect info    
  List<RedirectInfo> redirects ;
  /// Returns the final real request uri (maybe redirect). 
  Uri realUri;    
  /// Custom field that you can retrieve it later in `then`.
  Map<String, dynamic> extra;
}
```

When request is succeed, you will receive the response as follows:

```dart
Response response = await dio.get("https://www.google.com");
print(response.data);
print(response.headers);
print(response.request);
print(response.statusCode);
```

## Interceptors

For each dio instance, We can add one or more interceptors, by which we can intercept requests or responses before they are handled by `then` or `catchError`.

```dart
dio.interceptors.add(InterceptorsWrapper(
    onRequest:(RequestOptions options) async {
     // Do something before request is sent
     return options; //continue
     // If you want to resolve the request with some custom data，
     // you can return a `Response` object or return `dio.resolve(data)`.
     // If you want to reject the request with a error message,
     // you can return a `DioError` object or return `dio.reject(errMsg)`
    },
    onResponse:(Response response) async {
     // Do something with response data
     return response; // continue
    },
    onError: (DioError e) async {
     // Do something with response error
     return  e;//continue
    }
));

```

### Resolve and reject the request

In all interceptors, you can interfere with their execution flow. If you want to resolve the request/response with some custom data，you can return a `Response` object or return `dio.resolve(data)`.  If you want to reject the request/response with a error message, you can return a `DioError` object or return `dio.reject(errMsg)` .

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest:(RequestOptions options) {
   return dio.resolve("fake data")
  },
));
Response response = await dio.get("/test");
print(response.data);//"fake data"
```

### Lock/unlock the interceptors

You can lock/unlock the interceptors by calling their `lock()`/`unlock` method. Once the request/response interceptor is locked, the incoming request/response will be added to a queue before they enter the interceptor, they will not be continued until the interceptor is unlocked.

```dart
tokenDio = new Dio(); //Create a new instance to request the token.
tokenDio.options = dio;
dio.interceptors.add(InterceptorsWrapper(
    onRequest:(Options options) async {
        // If no token, request token firstly and lock this interceptor
        // to prevent other request enter this interceptor.
        dio.interceptors.requestLock.lock();
        // We use a new Dio(to avoid dead lock) instance to request token.
        Response response = await tokenDio.get("/token");
        //Set the token to headers
        options.headers["token"] = response.data["data"]["token"];
        dio.interceptors.requestLock.unlock();
        return options; //continue
    }
));
```

You can clean the waiting queue by calling `clear()`;

### aliases

When the **request** interceptor is locked, the incoming request will pause, this is equivalent to we locked the current dio instance, Therefore, Dio provied the two aliases for the `lock/unlock` of **request** interceptors.

**dio.lock() ==  dio.interceptors.requestLock.lock()**

**dio.unlock() ==  dio.interceptors.requestLock.unlock()**

**dio.clear() ==  dio.interceptors.requestLock.clear()**

### Example

Because of security reasons, we need all the requests to set up a csrfToken in the header, if csrfToken does not exist, we need to request a csrfToken first, and then perform the network request, because the request csrfToken progress is asynchronous, so we need to execute this async request in request interceptor. The code is as follows:

```dart
dio.interceptors.add(InterceptorsWrapper(
    onRequest: (Options options) async {
        print('send request：path:${options.path}，baseURL:${options.baseUrl}');
        if (csrfToken == null) {
            print("no token，request token firstly...");
            //lock the dio.
            dio.lock();
            return tokenDio.get("/token").then((d) {
                options.headers["csrfToken"] = csrfToken = d.data['data']['token'];
                print("request token succeed, value: " + d.data['data']['token']);
                print(
                    'continue to perform request：path:${options.path}，baseURL:${options.path}');
                return options;
            }).whenComplete(() => dio.unlock()); // unlock the dio
        } else {
            options.headers["csrfToken"] = csrfToken;
            return options;
        }
    }
));
```

For complete codes click [here](https://github.com/flutterchina/dio/blob/master/example/interceptor_lock.dart).

### Log

You can set  `LogInterceptor` to  print request/response log automaticlly, for example:

```dart
dio.interceptors.add(LogInterceptor(responseBody: false)); //开启请求日志
```

### Custom Interceptor

You can custom interceptor by extending the `Interceptor` class. There is an example that implementing a simple cache policy: [custom cache interceptor](https://github.com/flutterchina/dio/blob/master/example/custom_cache_interceptor.dart).

## Cookie Manager

[dio_cookie_manager](https://github.com/flutterchina/dio/tree/master/plugins/cookie_manager) package is a cookie manager for Dio.  

## Handling Errors

When a error occurs, Dio will wrap the `Error/Exception` to a `DioError`:

```dart
try {
    //404
    await dio.get("https://wendux.github.io/xsddddd");
} on DioError catch(e) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx and is also not 304.
    if(e.response) {
        print(e.response.data)
        print(e.response.headers)
        print(e.response.request)
    } else{
        // Something happened in setting up or sending the request that triggered an Error
        print(e.request)
        print(e.message)
    }
}
```

### DioError scheme

```dart
 {
  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response response;

  /// Error descriptions.
  String message;

  DioErrorType type;

  /// The original error/exception object; It's usually not null when `type`
  /// is DioErrorType.DEFAULT
  dynamic error;
}
```

### DioErrorType

```dart
enum DioErrorType {
  /// When opening  url timeout, it occurs.
  CONNECT_TIMEOUT,

  ///It occurs when receiving timeout.
  RECEIVE_TIMEOUT,

  /// When the server response, but with a incorrect status, such as 404, 503...
  RESPONSE,

  /// When the request is cancelled, dio will throw a error with this type.
  CANCEL,

  /// Default error type, Some other Error. In this case, you can
  /// read the DioError.error if it is not null.
  DEFAULT,
}
```



## Using application/x-www-form-urlencoded format

By default, Dio serializes request data(except String type) to `JSON`. To send data in the `application/x-www-form-urlencoded` format instead, you can :

```dart
//Instance level
dio.options.contentType= Headers.formUrlEncodedContentType;
//or works once
dio.post("/info", data:{"id":5}, 
         options: Options(contentType:Headers.formUrlEncodedContentType ));
```

## Sending FormData

You can also send FormData with Dio, which will send data in the `multipart/form-data`, and it supports uploading files.

```dart
FormData formData = FormData.from({
    "name": "wendux",
    "age": 25,
    "file": await MultipartFile.fromFile("./text.txt",filename: "upload.txt")
});
response = await dio.post("/info", data: formData);
```

There is a complete example [here](https://github.com/flutterchina/dio/blob/master/example/formdata.dart).

### Multiple files upload

There are two ways to add multiple files to ` FormData`， the only difference is that upload keys are different for array types。

```dart
  FormData.fromMap({
    "files": [
      MultipartFile.fromFileSync("./example/upload.txt",
          filename: "upload.txt"),
      MultipartFile.fromFileSync("./example/upload.txt",
          filename: "upload.txt"),
    ]
  });
```

The upload key eventually becomes "files[]"，This is because many back-end services add a middle bracket to key when they get an array of files. **If you don't want “[]”**，you should create FormData as follows（Don't use `FormData.fromMap`）:

```dart
  var formData = FormData();
  formData.files.addAll([
    MapEntry(
      "files",
       MultipartFile.fromFileSync("./example/upload.txt",
          filename: "upload.txt"),
    ),
    MapEntry(
      "files",
      MultipartFile.fromFileSync("./example/upload.txt",
          filename: "upload.txt"),
    ),
  ]);
```

## Transformer

`Transformer` allows changes to the request/response data before it is sent/received to/from the server. This is only applicable for request methods 'PUT', 'POST', and 'PATCH'. Dio has already implemented a `DefaultTransformer`, and as the default `Transformer`. If you want to customize the transformation of request/response data, you can provide a `Transformer` by your self, and replace the `DefaultTransformer` by setting the `dio.transformer`.

### In flutter

If you use dio in flutter development, you'd better to decode json   in background with [compute] function.

```dart

// Must be top-level function
_parseAndDecode(String response) {
  return jsonDecode(response);
}

parseJson(String text) {
  return compute(_parseAndDecode, text);
}

void main() {
  ...
  //Custom jsonDecodeCallback
  (dio.transformer as DefaultTransformer).jsonDecodeCallback = parseJson;
  runApp(MyApp());
}
```

### Other Example

There is an example for [customizing Transformer](https://github.com/flutterchina/dio/blob/master/example/transfomer.dart).

## HttpClientAdapter

HttpClientAdapter is a bridge between Dio and HttpClient.

Dio implements standard and friendly API  for developer.

HttpClient: It is the real object that makes Http requests.

We can use any HttpClient not just `dart:io:HttpClient` to make the Http request.  And  all we need is providing a `HttpClientAdapter`. The default HttpClientAdapter for Dio is `DefaultHttpClientAdapter`.

```dart
dio.httpClientAdapter = new DefaultHttpClientAdapter();
```

[Here](https://github.com/flutterchina/dio/blob/master/example/adapter.dart) is a simple example to custom adapter. 

### Using proxy

`DefaultHttpClientAdapter` provide a callback to set proxy to `dart:io:HttpClient`, for example:

```dart
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
...
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
    // config the http client
    client.findProxy = (uri) {
        //proxy all request to localhost:8888
        return "PROXY localhost:8888";
    };
    // you can also create a new HttpClient to dio
    // return new HttpClient();
};
```

There is a complete example [here](https://github.com/flutterchina/dio/blob/master/example/proxy.dart).

### Https certificate verification

There are two ways  to verify the https certificate. Suppose the certificate format is PEM, the code like:

```dart
String PEM="XXXXX"; // certificate content
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate  = (client) {
    client.badCertificateCallback=(X509Certificate cert, String host, int port){
        if(cert.pem==PEM){ // Verify the certificate
            return true;
        }
        return false;
    };
};
```

Another way is creating a `SecurityContext` when create the `HttpClient`:

```dart
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate  = (client) {
    SecurityContext sc = new SecurityContext();
    //file is the path of certificate
    sc.setTrustedCertificates(file);
    HttpClient httpClient = new HttpClient(context: sc);
    return httpClient;
};
```

In this way,  the format of certificate must be PEM or PKCS12.

## Http2 support

[dio_http2_adapter](https://github.com/flutterchina/dio/tree/master/plugins/http2_adapter) package is a Dio HttpClientAdapter which support Http/2.0 .

## Cancellation

You can cancel a request using a *cancel token*. One token can be shared with multiple requests. When a token's  `cancel` method invoked, all requests with this token will be cancelled.

```dart
CancelToken token = CancelToken();
dio.get(url1, cancelToken: token);
dio.get(url2, cancelToken: token);

// cancel the requests with "cancelled" message.
token.cancel("cancelled");
```

There is a complete example [here](https://github.com/flutterchina/dio/blob/master/example/cancel_request.dart).

## Extends Dio class

`Dio` is a abstract class with factory constructor，so we don't extend `Dio` class directy. For this purpose,  we can extend `DioForNative` or `DioForBrowser` instead, for example:

```dart
import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart'; //If in browser, import 'package:dio/browser_imp.dart'

class Http extends DioForNative {
  Http([BaseOptions options]):super(options){
    // do something
  }
}
```

We can also implement our Dio client:

```dart
class MyDio with DioMixin implements Dio{
  // ...
}
```

## Copyright & License

This open source project authorized by https://flutterchina.club , and the license is MIT.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/flutterchina/dio/issues

## Donate

Buy a cup of coffee for me (Scan by wechat)：

![](https://cdn.jsdelivr.net/gh/flutterchina/flutter-in-action@1.0.3/docs/imgs/pay.jpeg)
