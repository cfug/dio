// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

// Until we have verification in pkg:build and friends
// https://github.com/dart-lang/build/issues/590
Builder validate(String builderName, Builder builder) {
  var buildYaml = loadYaml(
    File('build.yaml').readAsStringSync(),
    sourceUrl: Uri.parse('build.yaml'),
  ) as YamlMap;

  for (var key in ['builders', builderName, 'build_extensions']) {
    buildYaml = buildYaml[key] as YamlMap;
  }

  final extensions = Set<String>.from(buildYaml['.dart'] as YamlList);

  final codedExtensions = builder.buildExtensions['.dart'].toSet();

  final tooMany = extensions.difference(codedExtensions);
  if (tooMany.isNotEmpty) {
    log.warning(
      '$builderName: Too many extensions in build.yaml:\n'
      '${tooMany.join('\n')}',
    );
  }

  final missing = codedExtensions.difference(extensions);
  if (missing.isNotEmpty) {
    log.warning(
      '$builderName: Missing extensions in build.yaml:\n'
      '${missing.join('\n')}',
    );
  }

  return builder;
}

class Replacement {
  final Pattern existing;
  final String replacement;

  const Replacement(this.existing, this.replacement);

  const Replacement.addJsonSerializableKey(String key, bool value)
      : existing = '@JsonSerializable(',
        replacement = '@JsonSerializable(\n  $key: $value,';

  static String generate(
    String inputContent,
    Iterable<Replacement> replacements,
  ) {
    var outputContent = inputContent;

    for (final r in replacements) {
      if (!outputContent.contains(r.existing)) {
        print('Input string did not contain `${r.existing}` as expected.');
      } else {
        outputContent = outputContent.replaceAll(r.existing, r.replacement);
      }
    }

    return outputContent.replaceAll(',)', ',\n)');
  }
}
