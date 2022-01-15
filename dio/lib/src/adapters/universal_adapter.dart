import 'package:dio/dio.dart';

import 'io_adapter.dart' if (dart.library.html) 'browser_adapter.dart'
    as adapter;

HttpClientAdapter createAdapter() => adapter.createAdapter();
