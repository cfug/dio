[![Pub package](https://img.shields.io/pub/v/source_gen_test.svg)](https://pub.dev/packages/source_gen_test)
[![Build Status](https://github.com/kevmoo/source_gen_test/workflows/CI/badge.svg?branch=master)](https://github.com/kevmoo/source_gen_test/actions?query=workflow%3A%22CI%22+branch%3Amaster)
[![package publisher](https://img.shields.io/pub/publisher/source_gen_test.svg)](https://pub.dev/packages/source_gen_test/publisher)

Make it easy to test `Generators` derived from `package:source_gen` by
annotating test files.

```dart
@ShouldGenerate(
  r'''
const TestClass1NameLength = 10;

const TestClass1NameLowerCase = testclass1;
''',
  configurations: ['default', 'no-prefix-required'],
)
@ShouldThrow(
  'Uh...',
  configurations: ['vague'],
  element: false,
)
@TestAnnotation()
class TestClass1 {}
```

Other helpers are also provided.
