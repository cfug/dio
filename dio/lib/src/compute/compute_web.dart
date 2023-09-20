import 'dart:async';

Future<R> compute<R>(
  FutureOr<R> Function() callback, {
  String? debugName,
}) async =>
    callback();
