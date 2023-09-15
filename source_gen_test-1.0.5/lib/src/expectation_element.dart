import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'annotations.dart';

List<ExpectationElement> genAnnotatedElements(
  LibraryReader libraryReader,
  Set<String> configDefaults,
) {
  final allElements = libraryReader.allElements
      .where((element) => element.name != null)
      .toList(growable: false)
    ..sort((a, b) => a.name!.compareTo(b.name!));

  return allElements.expand((element) {
    final initialValues = _expectationElements(element).toList();

    final explicitConfigSet = <String>{};

    final duplicateConfigs = <String>{};

    for (var configs in initialValues
        .map((e) => e.configurations)
        .whereType<Iterable<String>>()) {
      if (configs.isEmpty) {
        throw InvalidGenerationSourceError(
          '`configuration` cannot be empty.',
          todo: 'Leave it `null`.',
          element: element,
        );
      }
      for (var config in configs) {
        if (!explicitConfigSet.add(config)) {
          duplicateConfigs.add(config);
        }
      }
    }

    if (duplicateConfigs.isNotEmpty) {
      final list = duplicateConfigs.toList()..sort();
      throw InvalidGenerationSourceError(
        'There are multiple annotations for these configurations: '
        '${list.map((e) => '"$e"').join(', ')}.',
        todo: 'Ensure each configuration is only represented once per member.',
        element: element,
      );
    }

    return initialValues.map((te) {
      if (te.configurations == null) {
        final newConfigSet = configDefaults.difference(explicitConfigSet);
        // TODO: need testing and a "real" error here!
        assert(
          newConfigSet.isNotEmpty,
          '$element $configDefaults $explicitConfigSet',
        );
        te = te.replaceConfiguration(newConfigSet);
      }
      assert(te.configurations!.isNotEmpty);

      return ExpectationElement._(te, element.name!);
    });
  }).toList();
}

const _mappers = {
  TypeChecker.fromRuntime(ShouldGenerate): _shouldGenerate,
  TypeChecker.fromRuntime(ShouldThrow): _shouldThrow,
};

Iterable<TestExpectation> _expectationElements(Element element) sync* {
  for (var entry in _mappers.entries) {
    for (var annotation in entry.key.annotationsOf(element)) {
      yield entry.value(annotation);
    }
  }
}

@visibleForTesting
class ExpectationElement {
  final TestExpectation expectation;
  final String elementName;

  ExpectationElement._(this.expectation, this.elementName);
}

ShouldGenerate _shouldGenerate(DartObject obj) {
  final reader = ConstantReader(obj);
  return ShouldGenerate(
    reader.read('expectedOutput').stringValue,
    contains: reader.read('contains').boolValue,
    expectedLogItems: _expectedLogItems(reader),
    configurations: _configurations(reader),
  );
}

ShouldThrow _shouldThrow(DartObject obj) {
  final reader = ConstantReader(obj);
  return ShouldThrow(
    reader.read('errorMessage').stringValue,
    todo: reader.read('todo').literalValue as String?,
    element: reader.read('element').literalValue,
    expectedLogItems: _expectedLogItems(reader),
    configurations: _configurations(reader),
  );
}

List<String> _expectedLogItems(ConstantReader reader) => reader
    .read('expectedLogItems')
    .listValue
    .map((obj) => obj.toStringValue()!)
    .toList();

Set<String>? _configurations(ConstantReader reader) {
  final field = reader.read('configurations');
  if (field.isNull) {
    return null;
  }

  return field.listValue.map((obj) => obj.toStringValue()!).toSet();
}
