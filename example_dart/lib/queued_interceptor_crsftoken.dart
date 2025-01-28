import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

void main() async {
  final tokenManager = TokenManager();

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://httpbun.com',
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (requestOptions, handler) {
        print(
          '''
[onRequest] ${requestOptions.hashCode} / time: ${DateTime.now().toIso8601String()}
\tPath: ${requestOptions.path}
\tHeaders: ${requestOptions.headers}
          ''',
        );

        // In case, you have 'refresh_token' and needs to refresh your 'access_token',
        // request a new 'access_token' and update from here.

        if (tokenManager.accessToken != null) {
          requestOptions.headers['Authorization'] =
              'Bearer ${tokenManager.accessToken}';
        }

        return handler.next(requestOptions);
      },
      onResponse: (response, handler) {
        print('''
[onResponse] ${response.requestOptions.hashCode} / time: ${DateTime.now().toIso8601String()}
\tStatus: ${response.statusCode}
\tData: ${response.data}
        ''');

        return handler.resolve(response);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        print(
          '''
[onError] ${error.requestOptions.hashCode} / time: ${DateTime.now().toIso8601String()}
\tStatus: $statusCode
          ''',
        );

        // This example only handles the '401' status code,
        // The more complex scenario should handle more status codes e.g. '403', '404', etc.
        if (statusCode != 401) {
          return handler.resolve(error.response!);
        }

        // To prevent repeated requests to the 'Authentication Server'
        // to update our 'access_token' with parallel requests,
        // we need to compare with the previously requested 'access_token'.
        final requestedAccessToken =
            error.requestOptions.headers['Authorization'];
        if (requestedAccessToken == tokenManager.accessToken) {
          final tokenRefreshDio = Dio()
            ..options.baseUrl = 'https://httpbun.com';

          final response = await tokenRefreshDio.post(
            '/mix/s=201/b64=${base64.encode(
              jsonEncode(AuthenticationServer.generate()).codeUnits,
            )}',
          );
          tokenRefreshDio.close();

          // Treat codes other than 2XX as rejected.
          if (response.statusCode == null || response.statusCode! ~/ 100 != 2) {
            return handler.reject(error);
          }

          final body = jsonDecode(response.data) as Map<String, Object?>;
          if (!body.containsKey('access_token')) {
            return handler.reject(error);
          }

          final token = body['access_token'] as String;
          tokenManager.setAccessToken(token, error.requestOptions.hashCode);
        }

        /// The authorization has been resolved so and try again with the request.
        final retried = await dio.fetch(
          error.requestOptions
            ..path = '/mix/s=200'
            ..headers = {
              'Authorization': 'Bearer ${tokenManager.accessToken}',
            },
        );

        // Treat codes other than 2XX as rejected.
        if (retried.statusCode == null || retried.statusCode! ~/ 100 != 2) {
          return handler.reject(error);
        }

        return handler.resolve(error.response!);
      },
    ),
  );

  await Future.wait([
    dio.post('/mix/s=401'),
    dio.post('/mix/s=401'),
    dio.post('/mix/s=200'),
  ]);

  tokenManager.printHistory();

  dio.close();
}

typedef TokenHistory = ({
  String? previous,
  String? current,
  DateTime updatedAt,
  int updatedBy,
});

/// Pretend as 'Authentication Server' that generates access token and refresh token
class AuthenticationServer {
  static Map<String, String> generate() => <String, String>{
        'access_token': _generateUuid(),
        'refresh_token': _generateUuid(),
      };

  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class TokenManager {
  static String? _accessToken;

  static final List<TokenHistory> _history = <TokenHistory>[];

  String? get accessToken => _accessToken;

  void printHistory() {
    print('=== Token History ===');
    for (int i = 0; i < _history.length; i++) {
      final entry = _history[i];
      print('''
[$i]\tupdated token: ${entry.previous} → ${entry.current}
\tupdated at: ${entry.updatedAt.toIso8601String()}
\tupdated by: ${entry.updatedBy}
      ''');
    }
  }

  void setAccessToken(String? token, int instanceId) {
    final previous = _accessToken;
    _accessToken = token;
    _history.add(
      (
        previous: previous,
        current: _accessToken,
        updatedAt: DateTime.now(),
        updatedBy: instanceId,
      ),
    );
  }
}
