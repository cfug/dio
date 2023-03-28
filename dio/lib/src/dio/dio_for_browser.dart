import '../adapters/browser_adapter.dart';
import '../dio.dart';
import '../dio_mixin.dart';
import '../options.dart';

/// Create the [Dio] instance for Web platforms.
Dio createDio([BaseOptions? options]) => DioForBrowser(options);

/// Implements features for [Dio] on Web platforms.
class DioForBrowser with DioMixin implements Dio {
  /// Create Dio instance with default [Options].
  /// It's mostly just one Dio instance in your application.
  DioForBrowser([BaseOptions? options]) {
    this.options = options ?? BaseOptions();
    httpClientAdapter = BrowserHttpClientAdapter();
  }
}
