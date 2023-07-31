// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_serializable/src/utils.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

Builder docBuilder([_]) => _DocBuilder();

const _jsonKey = 'JsonKey';
const _jsonSerializable = 'JsonSerializable';

class _DocBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final lockFileAssetId = AssetId(buildStep.inputId.package, 'pubspec.lock');
    final lockFileContent = await buildStep.readAsString(lockFileAssetId);
    final lockFileYaml =
        loadYaml(lockFileContent, sourceUrl: lockFileAssetId.uri);
    final pkgMap = lockFileYaml['packages'] as YamlMap;
    final jsonAnnotationMap = pkgMap['json_annotation'] as YamlMap;
    final jsonAnnotationVersionString = jsonAnnotationMap['version'] as String;

    final jsonAnnotationVersion =
        Version.parse(jsonAnnotationVersionString.trim());

    final targetVersion = jsonAnnotationVersion.isPreRelease
        ? 'latest'
        : jsonAnnotationVersion.toString();

    final lib = LibraryReader(await buildStep.resolver.libraryFor(
        AssetId.resolve('package:json_annotation/json_annotation.dart')));

    final descriptionMap = <String, _FieldInfo>{};

    for (var className in _annotationClasses) {
      for (var fe in lib
          .findType(className)
          .fields
          .where((fe) => !fe.isStatic && !fe.hasDeprecated)) {
        descriptionMap[fe.name] =
            _FieldInfo.update(fe, descriptionMap[fe.name]);
      }
    }

    final buffer = StringBuffer();

    final sortedValues = descriptionMap.values.toList()..sort();

    final rows = <List<String>>[
      ['`build.yaml` key', _jsonSerializable, _jsonKey],
      ['-', '-', '-'],
      for (var info in sortedValues)
        [
          info.buildKey,
          info.classAnnotationName,
          info.fieldAnnotationName,
        ],
    ];

    final longest = List<int>.generate(rows.first.length, (_) => 0);
    for (var row in rows) {
      for (var column = 0; column < longest.length; column++) {
        if (row[column].length > longest[column]) {
          longest[column] = row[column].length;
        }
      }
    }

    for (var row in rows) {
      for (var column = 0; column < longest.length; column++) {
        var content = row[column];
        if (content == '-') {
          content *= longest[column];
        } else {
          content = content.padRight(longest[column]);
        }
        buffer.write('| $content ');
      }
      buffer.writeln('|');
    }

    buffer.writeln();

    for (var info in sortedValues) {
      if (info._classField != null) {
        buffer.writeln(_link(targetVersion, _jsonSerializable, info.name));
      }
      if (info._keyField != null) {
        buffer.writeln(_link(targetVersion, _jsonKey, info.name));
      }
    }

    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'doc/doc.md'), buffer.toString());
  }

  @override
  final buildExtensions = const {
    r'lib/json_serializable.dart': ['doc/doc.md']
  };
}

const _annotationClasses = [_jsonSerializable, _jsonKey];

String _anchorUriForName(String owner, String name) => '[$owner.$name]';

String _link(String version, String owner, String name) =>
    '${_anchorUriForName(owner, name)}: '
    'https://pub.dev/documentation/json_annotation/$version/'
    'json_annotation/$owner/$name.html';

class _FieldInfo implements Comparable<_FieldInfo> {
  final FieldElement _keyField, _classField;

  String get name => _keyField?.name ?? _classField.name;

  String get classAnnotationName {
    if (_classField == null) {
      return '';
    }
    return _anchorUriForName(_jsonSerializable, name);
  }

  String get fieldAnnotationName {
    if (_keyField == null) {
      return '';
    }
    return _anchorUriForName(_jsonKey, name);
  }

  String get buildKey {
    if (_classField == null) {
      return '';
    }

    return snakeCase(_classField.name);
  }

  _FieldInfo(this._keyField, this._classField);

  static _FieldInfo update(FieldElement field, _FieldInfo existing) {
    final parent = field.enclosingElement.name;

    FieldElement keyField, classField;
    switch (parent) {
      case _jsonSerializable:
        classField = field;
        keyField = existing?._keyField;
        break;
      case _jsonKey:
        keyField = field;
        classField = existing?._classField;
        break;
      default:
        throw FallThroughError();
    }

    return _FieldInfo(keyField, classField);
  }

  @override
  int compareTo(_FieldInfo other) {
    var value = _sortValue.compareTo(other._sortValue);

    if (value == 0) {
      value = name.compareTo(other.name);
    }
    return value;
  }

  int get _sortValue {
    if (_classField == null) {
      return 0;
    }

    if (_keyField == null) {
      return -2;
    }

    return -1;
  }

  @override
  String toString() => '_FieldThing($_keyField)';
}
