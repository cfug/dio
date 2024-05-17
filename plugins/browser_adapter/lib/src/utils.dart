import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

// TODO(Alex): Provide a configurable property on the Dio class once https://github.com/cfug/dio/discussions/1982 has made some progress.
void debugLog(String message, StackTrace stackTrace) {
  if (!kReleaseMode) {
    dev.log(
      message,
      level: 900,
      name: '🔔 Dio',
      stackTrace: stackTrace,
    );
  }
}
