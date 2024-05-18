/// A powerful HTTP client for Dart and Flutter, which supports global settings,
/// [Interceptors], [FormData], aborting and canceling a request,
/// files uploading and downloading, requests timeout, custom adapters, etc.
/// {@category Migration Guide}
/// {@category Plugins}
library dio;

export 'src/adapter.dart';
export 'src/cancel_token.dart';
export 'src/dio.dart';
export 'src/dio_exception.dart';
export 'src/dio_mixin.dart' hide InterceptorState, InterceptorResultType;
export 'src/form_data.dart';
export 'src/headers.dart';
export 'src/interceptors/log.dart';
export 'src/multipart_file.dart';
export 'src/options.dart';
export 'src/parameter.dart';
export 'src/redirect_record.dart';
export 'src/response.dart';
export 'src/transformer.dart';
export 'src/transformers/background_transformer.dart';
export 'src/transformers/sync_transformer.dart';
