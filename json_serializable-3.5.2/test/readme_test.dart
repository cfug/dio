// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  String readmeContent;

  setUpAll(() {
    readmeContent = File('README.md').readAsStringSync();
  });

  test('example.dart', () {
    final exampleContent = _getExampleContent('example.dart');
    expect(readmeContent, contains(exampleContent));
  });

  test('example.g.dart', () {
    final exampleGeneratedContent = _getExampleContent('example.g.dart');
    expect(readmeContent, contains(exampleGeneratedContent));
  });

  test('doc/doc.md', () {
    final docContent = File(p.join('doc', 'doc.md')).readAsStringSync();
    expect(readmeContent, contains(docContent));
  });
}

String _getExampleContent(String fileName) {
  final lines = File(p.join('example', fileName)).readAsLinesSync();

  var lastHadContent = false;

  // All lines with content, except those starting with `/`.
  // Also exclude blank lines that follow other blank lines
  final cleanedSource = lines.where((l) {
    if (l.startsWith(r'/')) {
      return false;
    }

    if (l.trim().isNotEmpty) {
      lastHadContent = true;
      return true;
    }

    if (lastHadContent) {
      lastHadContent = false;
      return true;
    }

    return false;
  }).join('\n');

  return '''
```dart
$cleanedSource
```''';
}
