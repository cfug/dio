import 'package:dio_browser_adapter/dio_browser_adapter.dart';

import '../adapter.dart';

HttpClientAdapter createAdapter() => BrowserHttpClientAdapter();

class BrowserHttpClientAdapter with BrowserHttpClientAdapterMixin {
  BrowserHttpClientAdapter({this.withCredentials = false});

  @override
  bool withCredentials;
}
