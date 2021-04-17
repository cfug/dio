import 'package:dio/dio.dart';

/// [ReplayInterceptor] is used to allow a request to be re-sent.
/// The client used here can be either the main one used to create the original
/// request or another one created on the side for different purpose. But at the
/// end. The request will be forwarded to the client that initiated the original
/// request where [RequestOptions] is taken from
class ReplayInterceptor extends Interceptor {
  Dio? _client;

  ReplayInterceptor({Dio? client}) {
    _client = client;
  }

  set client(Dio value) {
    _client = value;
  }

  ///[ResponseInterceptorHandler] is need to forward the final response
  ///to the initial dio client
  void replay(
      RequestOptions requestOptions, ResponseInterceptorHandler handler) {
    replayAndReturn(requestOptions).then((value) {
      onResponse(value, handler);
    });
  }

  /// [RequestOptions] comes from the original request. It is needed so
  /// parameters will be extracted from it to replay the request
  /// Left public because some might want to handle the response differently
  Future<Response> replayAndReturn(RequestOptions requestOptions) {
    if (_client != null) {
      var options = Options.fromRequestOptions(requestOptions);
      return _client!.request(requestOptions.path,
          data: requestOptions.data,
          cancelToken: requestOptions.cancelToken,
          onSendProgress: requestOptions.onSendProgress,
          onReceiveProgress: requestOptions.onReceiveProgress,
          queryParameters: requestOptions.queryParameters,
          options: options);
    } else {
      throw ArgumentError('Tried to replay on a null Dio client');
    }
  }
}
