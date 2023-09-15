// ignore_for_file: comment_references
// Note: Should be importing the below libs instead, but we are avoiding imports
// in this file to speed up analyzer parsing!
// import 'package:source_gen/source_gen.dart';
// import 'test_annotated_classes.dart';

/// Non-public, implementation base class of  [ShouldGenerate] and
/// [ShouldThrow].
abstract class TestExpectation {
  final Iterable<String>? configurations;
  final List<String> expectedLogItems;

  const TestExpectation._(this.configurations, List<String>? expectedLogItems)
      : expectedLogItems = expectedLogItems ?? const [];

  TestExpectation replaceConfiguration(Iterable<String> newConfiguration);
}

/// Specifies the expected output for code generation on the annotated member.
///
/// Must be used with [testAnnotatedElements].
class ShouldGenerate extends TestExpectation {
  final String expectedOutput;
  final bool contains;

  const ShouldGenerate(
    this.expectedOutput, {
    this.contains = false,
    Iterable<String>? configurations,
    List<String>? expectedLogItems,
  }) : super._(configurations, expectedLogItems);

  @override
  TestExpectation replaceConfiguration(Iterable<String> newConfiguration) =>
      ShouldGenerate(
        expectedOutput,
        contains: contains,
        configurations: newConfiguration,
        expectedLogItems: expectedLogItems,
      );
}

/// Specifies that an [InvalidGenerationSourceError] is expected to be thrown
/// when running generation for the annotated member.
///
/// Must be used with [testAnnotatedElements].
class ShouldThrow extends TestExpectation {
  final String errorMessage;
  final String? todo;

  /// If `null`, expects [InvalidGenerationSourceError.element] to match the
  /// element annotated with [ShouldThrow].
  ///
  /// If a [String], expects [InvalidGenerationSourceError.element] to match an
  /// element with the corresponding name.
  ///
  /// If `true`, [InvalidGenerationSourceError.element] is expected to be
  /// non-null.
  ///
  /// If `false`, [InvalidGenerationSourceError.element] is not checked.
  final dynamic element;

  const ShouldThrow(
    this.errorMessage, {
    this.todo,
    Object? element = true,
    Iterable<String>? configurations,
    List<String>? expectedLogItems,
  })  : element = element ?? true,
        super._(configurations, expectedLogItems);

  @override
  TestExpectation replaceConfiguration(Iterable<String> newConfiguration) =>
      ShouldThrow(
        errorMessage,
        configurations: newConfiguration,
        element: element,
        expectedLogItems: expectedLogItems,
        todo: todo,
      );
}
