// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'json_literal_generator.dart';
import 'json_serializable_generator.dart';
import 'settings.dart';

/// Returns a [Builder] for use within a `package:build_runner`
/// `BuildAction`.
///
/// [formatOutput] is called to format the generated code. If not provided,
/// the default Dart code formatter is used.
Builder jsonPartBuilder({
  String Function(String code) formatOutput,
  JsonSerializable config,
}) {
  final settings = Settings(config: config);

  return SharedPartBuilder(
    [
      JsonSerializableGenerator.fromSettings(settings),
      const JsonLiteralGenerator(),
    ],
    'json_serializable',
    formatOutput: formatOutput,
  );
}
