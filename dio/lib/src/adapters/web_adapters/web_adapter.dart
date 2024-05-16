import 'package:dio/dio.dart';

import 'wasm_adapter.dart' if (dart.library.html) 'browser_adapter.dart';

HttpClientAdapter createAdapter() => createWebAdapter();
