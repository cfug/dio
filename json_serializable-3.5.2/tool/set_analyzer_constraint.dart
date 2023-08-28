// Copied from https://github.com/Workiva/over_react/blob/ab689643a0c06b921ce84872bd7cee37a08cf11f/tool/set_analyzer_constraint.dart
import 'dart:io';

final analyzerConstraintPattern =
    RegExp(r'^( +analyzer:\s*).+', multiLine: true);

void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError(
        'Expected a single arg for the new analyzer constraint. Args: $args');
  }
  final newAnalyzerConstraint = args.single;

  final pubspec = File('pubspec.yaml');
  final pubspecContents = pubspec.readAsStringSync();

  final matches = analyzerConstraintPattern.allMatches(pubspecContents);
  if (matches.length != 1) {
    throw Exception(
        'Expected 1 analyzer dependency match in ${pubspec.path}, but found ${matches.length}.');
  }

  pubspec.writeAsStringSync(pubspecContents.replaceFirstMapped(
      analyzerConstraintPattern,
      (match) => '${match.group(1)}$newAnalyzerConstraint'));
}
