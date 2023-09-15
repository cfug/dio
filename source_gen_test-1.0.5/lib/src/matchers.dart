import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

/// Returns a [Matcher] that matches a thrown [InvalidGenerationSourceError]
/// with [InvalidGenerationSourceError.message] that matches [messageMatcher],
/// and [InvalidGenerationSourceError.todo] that matches [todoMatcher] and
/// [InvalidGenerationSourceError.element] that [isNotNull].
Matcher throwsInvalidGenerationSourceError(
  Object messageMatcher, {
  Object? todoMatcher,
  Object? elementMatcher,
}) {
  var matcher = const TypeMatcher<InvalidGenerationSourceError>()
      .having((e) => e.message, 'message', messageMatcher);

  if (elementMatcher != null) {
    matcher = matcher.having((e) => e.element, 'element', elementMatcher);
  }
  if (todoMatcher != null) {
    matcher = matcher.having((e) => e.todo, 'todo', todoMatcher);
  }

  return throwsA(matcher);
}
