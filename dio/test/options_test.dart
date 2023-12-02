@TestOn('vm')
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio/src/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'mock/http_mock.mocks.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);

  test('headers are kept after redirects', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: serverUrl.toString(),
        headers: {'x-test-base': 'test-base'},
      ),
    );
    final response = await dio.get(
      '/redirect',
      options: Options(headers: {'x-test-header': 'test-value'}),
    );
    expect(response.isRedirect, isTrue);
    expect(
      response.data['headers']['x-test-base'].single,
      equals('test-base'),
    );
    expect(
      response.data['headers']['x-test-header'].single,
      equals('test-value'),
    );
    expect(
      response.requestOptions.headers['x-test-base'],
      equals('test-base'),
    );
    expect(
      response.requestOptions.headers['x-test-header'],
      equals('test-value'),
    );
  });

  test('options', () {
    final map = {'a': '5'};
    final mapOverride = {'b': '6'};
    final baseOptions = BaseOptions(
      connectTimeout: Duration(seconds: 2),
      receiveTimeout: Duration(seconds: 2),
      sendTimeout: Duration(seconds: 2),
      baseUrl: 'http://localhost',
      queryParameters: map,
      extra: map,
      headers: map,
      contentType: 'application/json',
      followRedirects: false,
      persistentConnection: false,
    );
    final opt1 = baseOptions.copyWith(
      method: 'post',
      receiveTimeout: Duration(seconds: 3),
      sendTimeout: Duration(seconds: 3),
      baseUrl: 'https://pub.dev',
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );
    expect(opt1.method, 'post');
    expect(opt1.receiveTimeout, Duration(seconds: 3));
    expect(opt1.connectTimeout, Duration(seconds: 2));
    expect(opt1.followRedirects, false);
    expect(opt1.persistentConnection, false);
    expect(opt1.baseUrl, 'https://pub.dev');
    expect(opt1.headers['b'], '6');
    expect(opt1.extra['b'], '6');
    expect(opt1.queryParameters['b'], null);
    expect(opt1.contentType, 'text/html');

    final opt2 = Options(
      method: 'get',
      receiveTimeout: Duration(seconds: 2),
      sendTimeout: Duration(seconds: 2),
      extra: map,
      headers: map,
      contentType: 'application/json',
      followRedirects: false,
      persistentConnection: false,
    );

    final opt3 = opt2.copyWith(
      method: 'post',
      receiveTimeout: Duration(seconds: 3),
      sendTimeout: Duration(seconds: 3),
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );

    expect(opt3.method, 'post');
    expect(opt3.receiveTimeout, Duration(seconds: 3));
    expect(opt3.followRedirects, false);
    expect(opt3.persistentConnection, false);
    expect(opt3.headers!['b'], '6');
    expect(opt3.extra!['b'], '6');
    expect(opt3.contentType, 'text/html');

    final opt4 = RequestOptions(
      path: '/xxx',
      sendTimeout: Duration(seconds: 2),
      followRedirects: false,
      persistentConnection: false,
    );
    final opt5 = opt4.copyWith(
      method: 'post',
      receiveTimeout: Duration(seconds: 3),
      sendTimeout: Duration(seconds: 3),
      extra: mapOverride,
      headers: mapOverride,
      data: 'xx=5',
      path: '/',
      contentType: 'text/html',
    );
    expect(opt5.method, 'post');
    expect(opt5.receiveTimeout, Duration(seconds: 3));
    expect(opt5.followRedirects, false);
    expect(opt5.persistentConnection, false);
    expect(opt5.contentType, 'text/html');
    expect(opt5.headers['b'], '6');
    expect(opt5.extra['b'], '6');
    expect(opt5.data, 'xx=5');
    expect(opt5.path, '/');

    // Keys of header are case-insensitive
    expect(opt5.headers['B'], '6');
    opt5.headers['B'] = 9;
    expect(opt5.headers['b'], 9);
  });
  test('options content-type', () {
    const contentType = 'text/html';
    const contentTypeJson = 'application/json';
    final headers = {'content-type': contentType};
    final jsonHeaders = {'content-type': contentTypeJson};

    try {
      BaseOptions(contentType: contentType, headers: headers);
      expect(false, 'baseOptions1');
    } catch (e) {
      //
    }

    final bo1 = BaseOptions(contentType: contentType);
    final bo2 = BaseOptions(headers: headers);
    final bo3 = BaseOptions();

    expect(bo1.headers['content-type'], contentType);
    expect(bo2.headers['content-type'], contentType);
    expect(bo3.headers['content-type'], null);

    try {
      bo1.copyWith(headers: headers);
      expect(false, 'baseOptions copyWith 1');
    } catch (e) {
      //
    }

    try {
      bo2.copyWith(contentType: contentType);
      expect(false, 'baseOptions copyWith 2');
    } catch (e) {
      //
    }

    bo3.copyWith();

    /// options
    try {
      Options(contentType: contentType, headers: headers);
      expect(false, 'Options1');
    } catch (e) {
      //
    }

    final o1 = Options(contentType: contentType);
    final o2 = Options(headers: headers);

    try {
      o1.copyWith(headers: headers);
      expect(false, 'Options copyWith 1');
    } catch (e) {
      //
    }

    try {
      o2.copyWith(contentType: contentType);
      expect(false, 'Options copyWith 2');
    } catch (e) {
      //
    }

    expect(
      Options(contentType: contentTypeJson).compose(bo1, '').contentType,
      contentTypeJson,
    );
    expect(
      Options(contentType: contentTypeJson).compose(bo2, '').contentType,
      contentTypeJson,
    );
    expect(
      Options(contentType: contentTypeJson).compose(bo3, '').contentType,
      contentTypeJson,
    );
    expect(
      Options(headers: jsonHeaders).compose(bo1, '').contentType,
      contentTypeJson,
    );
    expect(
      Options(headers: jsonHeaders).compose(bo2, '').contentType,
      contentTypeJson,
    );
    expect(
      Options(headers: jsonHeaders).compose(bo3, '').contentType,
      contentTypeJson,
    );

    /// RequestOptions
    try {
      RequestOptions(path: '', contentType: contentType, headers: headers);
      expect(false, 'Options1');
    } catch (e) {
      //
    }

    final ro1 = RequestOptions(path: '', contentType: contentType);
    final ro2 = RequestOptions(path: '', headers: headers);

    try {
      ro1.copyWith(headers: headers);
      expect(false, 'RequestOptions copyWith 1');
    } catch (e) {
      //
    }

    try {
      ro2.copyWith(contentType: contentType);
      expect(false, 'RequestOptions copyWith 2');
    } catch (e) {
      //
    }

    final ro3 = RequestOptions(path: '');
    ro3.copyWith();
  });

  test('default content-type', () async {
    final dio = Dio();
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final r1 = await dio.get('');
    expect(
      r1.requestOptions.headers[Headers.contentTypeHeader],
      null,
    );

    final r2 = await dio.get(
      '',
      options: Options(contentType: Headers.jsonContentType),
    );
    expect(
      r2.requestOptions.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );

    final r3 = await dio.get(
      '',
      options: Options(
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      ),
    );
    expect(
      r3.requestOptions.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );

    final r4 = await dio.post('', data: '');
    expect(
      r4.requestOptions.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );

    final r5 = await dio.get(
      '',
      options: Options(
        // Final result should respect this.
        contentType: Headers.textPlainContentType,
        // Rather than this.
        headers: {Headers.contentTypeHeader: Headers.formUrlEncodedContentType},
      ),
    );
    expect(
      r5.requestOptions.headers[Headers.contentTypeHeader],
      Headers.textPlainContentType,
    );

    final r6 = await dio.get(
      '',
      data: '',
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      ),
    );
    expect(
      r6.requestOptions.headers[Headers.contentTypeHeader],
      Headers.formUrlEncodedContentType,
    );

    // Update the base option.
    dio.options.contentType = Headers.textPlainContentType;
    final r7 = await dio.get('');
    expect(
      r7.requestOptions.headers[Headers.contentTypeHeader],
      Headers.textPlainContentType,
    );

    final r8 = await dio.get(
      '',
      options: Options(contentType: Headers.jsonContentType),
    );
    expect(
      r8.requestOptions.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );

    final r9 = await dio.get(
      '',
      options: Options(
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      ),
    );
    expect(
      r9.requestOptions.headers[Headers.contentTypeHeader],
      Headers.jsonContentType,
    );

    final r10 = await dio.post('', data: FormData());
    expect(
      r10.requestOptions.contentType,
      startsWith(Headers.multipartFormDataContentType),
    );

    // Regression: https://github.com/cfug/dio/issues/1834
    final r11 = await dio.get('');
    expect(r11.data, '');
    final r12 = await dio.get<Map>('');
    expect(r12.data, null);
    final r13 = await dio.get<Map<String, Object>>('');
    expect(r13.data, null);
  });

  test('default content-type 2', () async {
    final dio = Dio();
    dio.options.baseUrl = 'https://www.example.com';

    final r1 = Options(method: 'GET').compose(dio.options, '/test').copyWith(
      headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
    );
    expect(
      r1.headers[Headers.contentTypeHeader],
      Headers.textPlainContentType,
    );

    final r2 = Options(method: 'GET')
        .compose(dio.options, '/test')
        .copyWith(contentType: Headers.textPlainContentType);
    expect(
      r2.headers[Headers.contentTypeHeader],
      Headers.textPlainContentType,
    );

    try {
      Options(method: 'GET').compose(dio.options, '/test').copyWith(
        headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
        contentType: Headers.formUrlEncodedContentType,
      );
    } catch (_) {}

    final r3 = Options(method: 'GET').compose(dio.options, '/test');
    expect(r3.uri.toString(), 'https://www.example.com/test');
    expect(r3.headers[Headers.contentTypeHeader], null);
  });

  test('responseDecoder return null', () async {
    final dio = Dio();
    dio.options.responseDecoder = (_, __, ___) => null;
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final Response response = await dio.get('');

    expect(response.data, null);
  });

  test('responseDecoder can return Future<String?>', () async {
    final dio = Dio();
    dio.options.responseDecoder = (_, __, ___) => Future.value('example');
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final Response response = await dio.get('');

    expect(response.data, 'example');
  });

  test('responseDecoder can return String?', () async {
    final dio = Dio();
    dio.options.responseDecoder = (_, __, ___) => 'example';
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final Response response = await dio.get('');

    expect(response.data, 'example');
  });

  test('requestEncoder can return Future<List<int>>', () async {
    final dio = Dio();
    dio.options.requestEncoder = (data, _) => Future.value(utf8.encode(data));
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final Response response = await dio.get('');

    expect(response.statusCode, 200);
  });

  test('requestEncoder can return List<int>', () async {
    final dio = Dio();
    dio.options.requestEncoder = (data, _) => utf8.encode(data);
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    final Response response = await dio.get('');

    expect(response.statusCode, 200);
  });

  test('invalid response type throws exceptions', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: MockAdapter.mockBase,
        contentType: Headers.jsonContentType,
      ),
    )..httpClientAdapter = MockAdapter();

    // Throws nothing.
    await dio.get<dynamic>('/test-plain-text-content-type');
    await dio.get<String>('/test-plain-text-content-type');

    // Throws a type error during cast.
    expectLater(
      dio.get<Map<String, dynamic>>('/test-plain-text-content-type'),
      throwsA((e) => e is DioException && e.error is TypeError),
    );
  });

  test('option invalid base url', () {
    final opt1 = 'blob:http://localhost/xyz123';
    final opt2 = 'https://pub.dev';
    final opt3 = 'https://';
    final opt4 = 'https://loremipsum/';
    final opt5 = '';
    final opt6 = 'pub.dev';
    expect(Uri.parse(opt1).host.isNotEmpty, false);
    expect(Uri.parse(opt2).host.isNotEmpty, true);
    expect(Uri.parse(opt3).host.isNotEmpty, false);
    expect(Uri.parse(opt4).host.isNotEmpty, true);
    expect(Uri.parse(opt5).host.isNotEmpty, false);
    expect(Uri.parse(opt6).host.isNotEmpty, false);
  });

  test('Throws when using invalid methods', () async {
    final dio = Dio();
    void testInvalidArgumentException(String method) async {
      await expectLater(
        dio.fetch(RequestOptions(path: 'http://127.0.0.1', method: method)),
        throwsA((e) => e is DioException && e.error is ArgumentError),
      );
    }

    const String separators = '\t\n\r()<>@,;:\\/[]?={}';
    for (int i = 0; i < separators.length; i++) {
      final String separator = separators.substring(i, i + 1);
      testInvalidArgumentException(separator);
      testInvalidArgumentException('${separator}CONNECT');
      testInvalidArgumentException('CONN${separator}ECT');
      testInvalidArgumentException('CONN$separator${separator}ECT');
      testInvalidArgumentException('CONNECT$separator');
    }
  });

  test('Transform data correctly with requests', () async {
    final dio = Dio()
      ..httpClientAdapter = EchoAdapter()
      ..options.baseUrl = EchoAdapter.mockBase;
    const methods = [
      'CONNECT',
      'HEAD',
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'OPTIONS',
      'TRACE',
    ];
    for (final method in methods) {
      final response = await dio.request(
        '/test',
        data: 'test',
        options: Options(method: method),
      );
      expect(response.data, 'test');
    }
  });

  test('Headers can be case-sensitive', () async {
    final dio = Dio();
    final client = MockHttpClient();
    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () => client);

    final headerMap = caseInsensitiveKeyMap();
    late MockHttpHeaders mockRequestHeaders;
    when(client.openUrl(any, any)).thenAnswer((_) async {
      final request = MockHttpClientRequest();
      final response = MockHttpClientResponse();
      mockRequestHeaders = MockHttpHeaders();
      when(
        mockRequestHeaders.set(
          any,
          any,
          preserveHeaderCase: anyNamed('preserveHeaderCase'),
        ),
      ).thenAnswer((invocation) {
        final args = invocation.positionalArguments.cast<String>();
        final preserveHeaderCase =
            invocation.namedArguments[#preserveHeaderCase] as bool;
        headerMap[preserveHeaderCase ? args[0] : args[0].toLowerCase()] =
            args[1];
      });
      when(request.headers).thenAnswer((_) => mockRequestHeaders);
      when(request.close()).thenAnswer((_) => Future.value(response));
      when(request.addStream(any)).thenAnswer((_) async => null);
      when(response.headers).thenReturn(MockHttpHeaders());
      when(response.statusCode).thenReturn(200);
      when(response.reasonPhrase).thenReturn('OK');
      when(response.isRedirect).thenReturn(false);
      when(response.redirects).thenReturn([]);
      when(response.transform(any))
          .thenAnswer((_) => Stream<Uint8List>.empty());
      return Future.value(request);
    });

    await dio.get(
      '',
      options: Options(
        preserveHeaderCase: true,
        headers: {'Sensitive': 'test', 'insensitive': 'test'},
      ),
    );
    expect(headerMap['Sensitive'], 'test');
    expect(headerMap['insensitive'], 'test');
    headerMap.clear();

    await dio.get(
      '',
      options: Options(
        headers: {'Sensitive': 'test', 'insensitive': 'test'},
      ),
    );
    expect(headerMap['sensitive'], 'test');
    expect(headerMap['insensitive'], 'test');
  });
}
