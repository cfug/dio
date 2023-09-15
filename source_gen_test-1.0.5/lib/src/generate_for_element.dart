// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart' as dart_style;
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/output_helpers.dart'
    show normalizeGeneratorOutput;

import 'init_library_reader.dart' show testPackageName;

final _formatter = dart_style.DartFormatter();

final _testAnnotationWarnings = <String>{};

Future<String> generateForElement<T>(
  GeneratorForAnnotation<T> generator,
  LibraryReader libraryReader,
  String name,
) async {
  final elements =
      libraryReader.allElements.where((e) => e.name == name).toList();

  if (elements.isEmpty) {
    throw ArgumentError.value(
      name,
      'name',
      'Could not find an element with name `$name`.',
    );
  }

  Element element;

  if (elements.length == 1) {
    element = elements[0];
  } else {
    final rootProperties =
        elements.whereType<PropertyInducingElement>().toList();
    if (rootProperties.length == 1) {
      element = rootProperties[0];
    } else {
      throw UnimplementedError();
    }
  }

  var annotation = generator.typeChecker.firstAnnotationOf(element);

  if (annotation == null) {
    final annotationFromTestLib = element.metadata
        .map((ea) => ea.computeConstantValue()!)
        .where((obj) {
          if (obj.type is InterfaceType) {
            final uri = (obj.type as InterfaceType).element.source.uri;
            return uri.isScheme('package') &&
                uri.pathSegments.first == testPackageName;
          }

          return false;
        })
        .where((obj) => obj.type!.element!.name == T.toString())
        .toList();

    String msg;
    if (annotationFromTestLib.length == 1) {
      annotation = annotationFromTestLib[0];

      msg = '''
  NOTE: Could not find an annotation that matched
      ${generator.typeChecker}.
    Using a annotation with the same name from the synthetic library instead
      ${(annotation.type as InterfaceType).element.source.uri}#${annotation.type!.element!.name}''';
    } else {
      msg = '''
  NOTE: Could not find an annotation that matched
      ${generator.typeChecker}.
    The `ConstReader annotation` argument to your generator will have a `null` element.''';
    }

    if (_testAnnotationWarnings.add(msg)) {
      print(msg);
    }
  }

  final generatedStream = normalizeGeneratorOutput(
    generator.generateForAnnotatedElement(
      element,
      ConstantReader(annotation),
      _MockBuildStep(),
    ),
  );

  final generated = await generatedStream.join('\n\n');

  return _formatter.format(generated);
}

// ignore: subtype_of_sealed_class
class _MockBuildStep extends BuildStep {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
