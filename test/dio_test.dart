import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class MyTransformer extends DefaultTransformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data is List<String>) {
      throw new DioError(message: "Can't send List to sever directly");
    } else {
      return super.transformRequest(options);
    }
  }

  /// The [Options] doesn't contain the cookie info. we add the cookie
  /// info to [Options.extra], and you can retrieve it in [ResponseInterceptor]
  /// and [Response] with `response.request.extra["cookies"]`.
  @override
  Future transformResponse(RequestOptions options,  ResponseBody response) async {
    options.extra["xx"] = "extra";
    return super.transformResponse(options, response);
  }
}

void main() {
  const BASE_URL = "http://www.dtworkroom.com/doris/1/2.0.0/";
  group('lan', () {
    test("lan", () {
      var list = [""];
      assert(list is List<String>);
      assert(!(list is List<int>));
    });
  });
  group('restful', () {
    Dio dio;
    setUp(() {
      dio = new Dio();
      dio.options.baseUrl = BASE_URL;
      dio.options.headers = {'User-Agent': 'dartisan', 'XX': '8'};
    });
    test('test', () async {
      Response response;
      response = await dio.get("/test", queryParameters: {"id": '12', "name": "wendu"});
      expect(response.data["errCode"], 0);
      response = await dio.post("/test");
      expect(response.data["errCode"], 0);
      response = await dio.put("/test");
      expect(response.data["errCode"], 0);
      response = await dio.delete("/test");
      expect(response.data["errCode"], 0);
      response = await dio.patch("/test", data: {"xx": "你好"});
      expect(response.data["errCode"], 0);
      expect(response.headers != null, true);

      try {
        // Response response = await dio.head("/test");
        Response response = await dio.head("http://www.dtworkroom.com:80");
        expect(response.data["errCode"], 0);
      } on DioError catch (e) {
        assert(e.response != null &&
            e.type == DioErrorType.RESPONSE &&
            e.response.statusCode == 403);
      }
    });
  });

  group('download', () {
    test("test", () async {
      var dio = new Dio();
      var url = "https://flutter.io/assets/flutter-lockup-4cb0ee072ab312e59784d9fbf4fb7ad42688a7fdaea1270ccf6bbf4f34b7e03f.svg";
      await dio.download(url, "./example/flutter.svg",
          options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),  // disable gzip
          // Listen the download progress.
          onProgress: (received, total) {
        if (total != -1) {
          print((received / total * 100).toStringAsFixed(0) + "%");
        }
      });
      var f = new File("./example/flutter.svg");
      var t = await f.open();
      t.close();
    });
  });

  group('formdata', () {
    test("test", () async {
      var dio = new Dio();
      dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
//      dio.onHttpClientCreate = (HttpClient client) {
//        client.findProxy = (uri) {
//          //proxy all request to localhost:8888
//          return "PROXY localhost:8888";
//        };
//      };
      FormData formData = new FormData.from({
        "name": "wendux",
        "age": 25,
      });
      formData.remove("name");
      formData["xx"] = 9;
      formData.add("file",
          new UploadFileInfo(new File("./example/upload.txt"), "upload.txt"));
      Response response = await dio.post("/test", data: formData);
      formData.clear();
      expect(formData.length, 0);
    });
  });

  group('Cancellation', () {
    test("test", () async {
      var dio = new Dio();
      CancelToken token = new CancelToken();
      new Timer(new Duration(milliseconds: 10), () {
        token.cancel("cancelled");
      });

      var url = "https://accounts.google.com";
      await dio.get(url, cancelToken: token).catchError((e) {
        expect(CancelToken.isCancel(e), true);
        if (CancelToken.isCancel(e)) {
          expect(e.type, DioErrorType.CANCEL);
          print('$url: $e');
        }
      });
    });

    test("test download", () async {
      var dio = new Dio();
      CancelToken token = new CancelToken();
      new Timer(new Duration(milliseconds: 1000), () {
        token.cancel("cancelled");
      });

      final url = 'http://download.dcloud.net.cn/HBuilder.9.0.2.macosx_64.dmg';
      final savePath = './example/HBuilder.9.0.2.macosx_64.dmg';
      await dio.download(url, savePath, cancelToken: token).catchError((e) {
        expect(CancelToken.isCancel(e), true);
        if (CancelToken.isCancel(e)) {
          expect(e.type, DioErrorType.CANCEL);
        }
      });
    });
  });

  group('transfomer', () {
    test("test", () async {
      var dio = new Dio();
      dio.options.baseUrl="http://www.dtworkroom.com/doris/1/2.0.0";
      dio.transformer = new MyTransformer();
//      Response response = await dio.get("https://www.baidu.com");
//      assert(response.request.extra["cookies"]!=null);
      try {
        var r = await dio.post("/test",
            data: ["1", "2"]);
      } catch (e) {
        expect(e.message, "Can't send List to sever directly");
      }
      dio.get("/test").then((r){
        expect(r.request.extra["xx"], "extra");
      });
      var data = {
        "a": "你好",
        "b": [5, "6"],
        "c": {
          "d": 8,
          "e": {
            "a": 5,
            "b": [66, 8]
          }
        }
      };
      var dest =
          "a=%E4%BD%A0%E5%A5%BD&b%5B%5D=5&b%5B%5D=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D%5B%5D=66&c%5Be%5D%5Bb%5D%5B%5D=8";
      expect(Transformer.urlEncodeMap(data), dest);
    });
  });

  group('Request Interceptor', () {
    Dio dio;
    setUp(() {
      dio = new Dio();
      dio.options.baseUrl = BASE_URL;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest:  (RequestOptions options) async {
          switch (options.path) {
            case "/fakepath1":
              return dio.resolve("fake data");
            case "/fakepath2":
              return dio.get("/test");
            case "/fakepath3":
              return dio.reject(
                  "test error"); //you can also return a HttpError directly.
            case "fakepath4":
              return new DioError(
                  message:
                  "test error"); // Here is equivalent to call dio.reject("test error")
            case "/test?tag=1":
              {
                Response response = await dio.get("/token");
                print(response);
                options.headers["token"] = response.data["data"]["token"];
                return options;
              }
            default:
              return options; //continue
          }
        }
      ));
    });

    test('TestRI', () async {
      Response
//      response = await dio.get("/fakepath1");
//      expect(response.data, "fake data");
//      response = await dio.get("/fakepath2");
//      expect(response.data["errCode"], 0);
//
//      try {
//        response = await dio.get("/fakepath3");
//      } on DioError catch (e) {
//        expect(e.message, "test error");
//        expect(e.response, null);
//      }
//      try {
//        response = await dio.get("/fakepath4");
//      } on DioError catch (e) {
//        expect(e.message, "test error");
//        expect(e.response, null);
//      }
//      response = await dio.get("/test");
//      expect(response.data["errCode"], 0);
//
          response = await dio.get("/test?tag=1");
      expect(response.data["errCode"], 0);

//      try {
//        await dio.get("https://wendux.github.io/xsddddd");
//      } on DioError catch (e) {
//        expect(e.response.statusCode, 404);
//      }
    });
  });

  group('Response Interceptor', () {
    Dio dio;
    const String URL_NOT_FIND = "https://wendux.github.io/xxxxx/";
    const String URL_NOT_FIND_1 = URL_NOT_FIND + "1";
    const String URL_NOT_FIND_2 = URL_NOT_FIND + "2";
    const String URL_NOT_FIND_3 = URL_NOT_FIND + "3";
    setUp(() {
      dio = new Dio();
      dio.options.baseUrl = BASE_URL;
      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (Response response) {
          return response.data["data"];
        },
        onError: (DioError e) {
          if (e.response != null) {
            switch (e.response.request.path) {
              case URL_NOT_FIND:
                return e;
              case URL_NOT_FIND_1:
                return dio.resolve("fake data"); // you can also return a HttpError directly.
              case URL_NOT_FIND_2:
                return new Response(data: "fake data");
              case URL_NOT_FIND_3:
                return 'custom error info [${e.response.statusCode}]';
            }
          }
          return e;
        }
      ));
    });

    test('Test', () async {
     //await dio.get("/test").then(print);
      Response response = await dio.get("/test");
      expect(response.data["path"], "/test");
      try {
        await dio.get(URL_NOT_FIND);
      } catch (e) {
        expect(e.response.statusCode, 404);
      }
      response = await dio.get(URL_NOT_FIND + "1");
      expect(response.data, "fake data");
      response = await dio.get(URL_NOT_FIND + "2");
      expect(response.data, "fake data");
      try {
        await dio.get(URL_NOT_FIND + "3");
      } catch (e) {
        expect(e.message, 'custom error info [404]');
      }
    });
  });

  group('Interceptor lock', () {
    test("test", () async {
      Dio dio = new Dio();
      // new dio instance to request token
      Dio tokenDio = new Dio();
      String csrfToken;
      dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
      tokenDio.options = dio.options;
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (RequestOptions options) {
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

      _onResult(d) {
        print("request ok!");
      }

      await Future.wait([
        dio.get("/test?tag=1").then(_onResult),
        dio.get("/test?tag=2").then(_onResult),
        dio.get("/test?tag=3").then(_onResult)
      ]);
    });
  });
}
