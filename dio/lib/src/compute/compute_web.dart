import 'dart:async';

import 'package:dio/src/compute/compute.dart';

Future<R> compute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) async =>
    callback(message);
