## 3.5.2

- Widen `package:analyzer` range to allow v1.x.

## 3.5.1

- Improved error messages for unsupported types.
- `package:json_serializable/type_helper.dart`
  - Made the third parameter to `UnsupportedTypeError` positional (optional).
- Require `package:analyzer` `>=0.39.0 <0.42.0`.

## 3.5.0

- Added support for populating generic helper functions for fields with generic
  type parameters.
- Added support for `JsonSerializable.genericArgumentFactories`.
  This adds extra parameters to generated `fromJson` and/or `toJson` functions
  to support encoding and decoding generic types.

  For example, the generated code for
  
  ```dart
  @JsonSerializable(genericArgumentFactories: true)
  class Response<T> {
    int status;
    T value;
  }
  ```
  
  Looks like
  
  ```dart
  Response<T> _$ResponseFromJson<T>(
    Map<String, dynamic> json,
    T Function(Object json) fromJsonT,
  ) {
    return Response<T>()
      ..status = json['status'] as int
      ..value = fromJsonT(json['value']);
  }
  
  Map<String, dynamic> _$ResponseToJson<T>(
    Response<T> instance,
    Object Function(T value) toJsonT,
  ) =>
      <String, dynamic>{
        'status': instance.status,
        'value': toJsonT(instance.value),
      };
  ```

- `JsonKey.unknownEnumValue`: Added support for `Iterable`, `List`, and `Set`.
- Require `package:analyzer` `>=0.39.0 <0.41.0`.

## 3.4.1

- Support properties where the getter is defined in a class with a corresponding
  setter in a super type.

## 3.4.0

- `JsonKey.defaultValue`
  - Added support for `double.infinity`, `double.negativeInfinity`, and
  `double.nan`.
  - Added support for `Set` literals.
- Require at least Dart `2.7.0`.

## 3.3.0

- Add support for fields annotated subclasses of `JsonKey`.
- Export the following `TypeHelper` implementations and interfaces in
  `package:json_serializable/type_helper.dart`:
  - `DurationHelper`
  - `TypeHelperContextWithConfig`

## 3.2.5

- Fix lint affecting `pub.dev` score.

## 3.2.4

* Require `package:analyzer` `^0.39.0`.

## 3.2.3

* Bug fix for analyzer 0.38.5.

## 3.2.2

* Support `JsonConverter` annotations on property getters

## 3.2.1

* Support `package:analyzer` `>=0.33.3 <0.39.0`

## 3.2.0

- Require `package:json_annotation` `^3.0.0`.
- Added support for `JsonSerializable.ignoreUnannotated`.
- Added support for `JsonKey.unknownEnumValue`.
- Small change to how `enum` support code is generated.
- Require at least Dart `2.3.0`.

## 3.1.0

- Support `Map` keys of type `int`, `BigInt`, `DateTime`, and `Uri`.
- Trailing commas are now added to generated constructor arguments and the
  elements in `Map` literals.
- Support `package:analyzer` `>=0.33.3 <0.38.0`

## 3.0.0

This release is entirely **BREAKING** changes. It removes underused features
that added disproportionate complexity to this package. This cleanup should ease
future feature work.

- Removed support for `JsonSerializable.useWrappers`.
- Removed support for `JsonSerializable.generateToJsonFunction`.
- Removed support for `encodeEmptyCollection`.
- If a field has a conversion function defined – either 
  `JsonKey.toJson` or a custom `JsonConverter` annotation – don't intercept
  `null` values, even if `nullable` is explicitly set to `false`. This allows
  these functions to provide alternative values for `null` – such as an empty
  collection – which replaces the functionality provided by
  `encodeEmptyCollection`.
    - **NOTE: this is SILENTLY BREAKING.** There is no corresponding deprecation
      for this change. If you use converters, please make sure to test your
      code!
 
## 2.3.0

- Added `pascal` as an additional `fieldRename` option.

## 2.2.3

- Removed special handling of undefined types due to changes in
  `package:analyzer`. These types are now treated as `dynamic`.

## 2.2.2

- Require at least Dart `2.2.0`.
- Allow `build_config` `0.4.x`.

## 2.2.1

- Fixed an error when a property/field is defined in a `mixin`.

## 2.2.0

- If a field has a conversion function defined – either `JsonKey.toJson` or a
  custom `JsonConverter` annotation – handle the case where the function
  returns `null` and both `nullable` and `includeIfNull` are `false`.

## 2.1.2

* Support `package:json_annotation` `>=2.1.0 <2.3.0`.

## 2.1.1

* Support `package:analyzer` `>=0.33.3 <0.37.0`

## 2.1.0

* Require at least Dart `2.1.1`.

* Added support for `encodeEmptyCollection` on `JsonKey` and `JsonSerializable`.

* Added support for `BigInt`.

* Added `BigIntTypeHelper` to `type_helper.dart` library.

* Provide a more helpful error if the builder is improperly configured.

## 2.0.3

* When invoking a `fromJson` constructor on a field type, generate a conversion
  expression derived from the the constructor parameter type.

* Be more strict about the supported `List`, `Set`, or `Map` types.
  This may causes errors to be raised in cases where invalid code was generated
  before. It also allows implementations of these types to add a `fromJson`
  constructor to support custom decoding.

* Small change to the whitespace around converted maps to improve a very slow
  path when formatting generated code.

## 2.0.2

* Log warnings when `JsonKey.defaultValue` is set with other fields.
  * With `toJson`: use `nullable: false` instead of `defaultValue`.
  * With both `disallowNullValue` and `required` set to `true`.

* Avoid no-op call to `map` when decoding a field of type `Set`. 

* Support `package:analyzer` `>=0.33.3 <0.36.0`

## 2.0.1

* Support `package:analyzer` v0.34.0.

## 2.0.0

* Support all `build.yaml` configuration options on classes by adding a number
  of fields to `JsonSerializable`: `anyMap`, `checked`, `explicitToJson`,
  `generateToJsonFunction`, and `useWrappers`.

* Support decode/encode of `dart:core` `Duration`

* Code generated for fields and classes annotated with `JsonConverter` instances
  now properly handles nullable fields.

* Build configuration

  * You can now configure all settings exposed by the `JsonSerializable`
    annotation within `build.yaml`.

  * **BREAKING** Unsupported options defined in `build.yaml` will cause
    exceptions instead of being logged and ignored.

* `json_serializable.dart`

  * **BREAKING** `JsonSerializableGenerator` now exposes a `config` property
    of type `JsonSerializable` instead of individual properties for `checked`,
    `anyMay`, etc. This will affect anyone creating or using this class via
    code.

* `type_helper.dart`

  * **BREAKING** `SerializeContext` and `DeserializeContext` have been replaced
    with new `TypeHelperContext` class.

  * `TypeHelper` now has a type argument allowing implementors to specify a
    specific implementation of `TypeHelperContext` for calls to `serialize` and
    `deserialize`. Many of the included `TypeHelper` implementations have been
    updated to indicate they expect more information from the source generator.

## 1.5.1

* Support the latest `package:analyzer`.

## 1.5.0

* Added support for `JsonConvert` annotation on fields.

## 1.4.0

* `type_helper.dart`

  * `TypeHelper` `serialize` and `deserialize` have return type `Object` instead
    of `String`. This allows coordination between instances to support more
    advanced features – like using the new `LambdaResult` class to avoid
    creating unnecessary lambdas. When creating `TypeHelper` implementations,
    handle non-`String` results by calling `toString()` on unrecognized values.

* Declare support for `package:build` version `1.x.x`.

## 1.3.0

* Add support for types annotated with classes that extend `JsonConverter` from
  `package:json_annotation`.

* Export the following `TypeHelper` implementations in
  `package:json_serializable/type_helper.dart`:
  `ConvertHelper`, `EnumHelper`, `IterableHelper`, `JsonConverterHelper`,
  `MapHelper`, `ValueHelper`

* Added support for `Set` type as a target.

## 1.2.1

* Added back `const` for maps generated with `checked: true` configuration.

## 1.2.0

* Now throws `InvalidGenerationSourceError` instead of `UnsupportedError` for
  some classes of constructor errors.

* Supports class-static functions for `toJson` and `fromJson` on `JsonKey`.

* Provide a warning about ignored setter-only properties instead of crashing.

* Added back `const` for lists generated with `disallowUnrecognizedKeys`,
  `required`, and `disallowNullValue`.

* Fixed a bug when `disallowUnrecognizedKeys` is enabled.

* Fixed a number of issues when dealing with inherited properties.

## 1.1.0

* Added support for automatically converting field names to JSON map keys as
  `kebab-case` or `snake_case` with a new option on the `JsonSerializable`
  annotation.

## 1.0.1

* Explicit `new` and `const` are no longer generated.

## 1.0.0

* **BREAKING** By default, code generated to support `toJson` now creates
  a top-level function instead of a mixin. The default for the
  `generate_to_json_function` is now `true`. To opt-out of this change,
  set `generate_to_json_function` to `false`.

* Now supports changing the serialized values of enums using `JsonValue`.

  ```dart
  enum AutoApply {
    none,
    dependents,
    @JsonValue('all_packages')
    allPackages,
    @JsonValue('root_package')
    rootPackage
  }
  ```

* `JsonSerializableGenerator.generateForAnnotatedElement` now returns
  `Iterable<String>` instead of `String`.

* `SerializeContext` and `DeserializeContext` now have an `addMember` function
  which allows `TypeHelper` instances to add additional members when handling
  a field. This is useful for generating shared helpers, for instance.

* **BREAKING** The `header` option is no longer supported and must be removed
  from `build.yaml`.

* If a manual build script is used the `json_serializable` builder must be
  switched to `hideOutput: true`, and the `combiningBuilder` from `source_gen`
  must be included following this builder. When using a generated build script
  with `pub run build_runner` or `webdev` this is handled automatically.

## 0.5.8+1

* Support the Dart 2.0 stable release.

## 0.5.8

* Small fixes to support Dart 2 runtime semantics.

* Support serializing types provided by platform-specific libraries (such as
  Flutter) if they use custom convert functions.

## 0.5.7

* Added support for `JsonKey.required`.
  * When `true`, generated code throws a `MissingRequiredKeysException` if
    the key does not exist in the JSON map used to populate the annotated field.
  * Will be captured and wrapped in a `CheckedFromJsonException` if
    `checked` is enabled in `json_serializable`.

* Added `JsonKey.disallowNullValue`.
  * When `true`, generated code throws a `DisallowedNullValueException` if
  the corresponding keys exist in in the JSON map, but it's value is null.
  * Will be captured and wrapped in a `CheckedFromJsonException` if
    `checked` is enabled in `json_serializable`.

* Added support for `Uri` conversion.

* Added missing `checked` parameter to the
  `JsonSerializableGenerator.withDefaultHelpers` constructor.

* Added `explicit_to_json` configuration option.
  * See `JsonSerializableGenerator.explicitToJson` for details.

* Added `generate_to_json_function` configuration option.
  * See `JsonSerializableGenerator.generateToJsonFunction` for details.

## 0.5.6

* Added support for `JsonSerializable.disallowUnrecognizedKeys`.
  * Throws an `UnrecognizedKeysException` if it finds unrecognized keys in the
    JSON map used to populate the annotated field.
  * Will be captured and wrapped in a `CheckedFromJsonException` if
    `checked` is enabled in `json_serializable`.
* All `fromJson` constructors now use block syntax instead of fat arrows.

## 0.5.5

* Added support for `JsonKey.defaultValue`.

* `enum` deserialization now uses helpers provided by `json_annotation`.

* Small change to how nullable `Map` values are deserialized.

* Small whitespace changes to `JsonLiteral` generation to align with `dartfmt`.

* Improve detection of `toJson` and `fromJson` in nested types.

## 0.5.4+1

* Fixed a bug introduced in `0.5.4` in some cases where enum values are nested
  in collections.

## 0.5.4

* Add `checked` configuration option. If `true`, generated `fromJson` functions
  include extra checks to validate proper deserialization of types.

* Added `any_map` to configuration. Allows `fromJson` code to
  support dynamic `Map` instances that are not explicitly
  `Map<String, dynaimc>`.

* Added support for classes with type arguments.

* Use `Map.map` for more map conversions. Simplifies generated code and fixes
  a subtle issue when the `Map` key type is `dynamic` or `Object`.

## 0.5.3

* Require the latest version of `package:analyzer` - `v0.32.0`.

* If `JsonKey.fromJson` function parameter is `Iterable` or `Map` with type
   arguments of `dynamic` or `Object`, omit the arguments when generating a
   cast.
   `_myHelper(json['key'] as Map)` instead of
   `_myHelper(json['key'] as Map<dynamic, dynamic>)`.

* `JsonKey.fromJson`/`.toJson` now support functions with optional arguments.

## 0.5.2

* If `JsonKey.fromJson`/`toJson` are set, apply them before any custom
  or default `TypeHelper` instances. This allows custom `DateTime` parsing,
  by preempting the existing `DateTime` `TypeHelper`.

## 0.5.1

* Support new `fromJson` and `toJson` fields on `JsonKey`.

* Use `log` exposed by `package:build`. This requires end-users to have at least
  `package:build_runner` `^0.8.2`.

* Updated minimum `package:source_gen` dependency to `0.8.1` which includes
  improved error messages.

## 0.5.0

* **BREAKING** Removed deprecated support for `require_library_directive` /
  `requireLibraryDirective` in `build_runner` configuration.

* **BREAKING** Removed the deprecated `generators.dart` library.

* **BREAKING** Removed `jsonPartBuilder` function from public API.

* Support the latest `package:source_gen`.

* Private and ignored fields are now excluded when generating serialization and
  deserialization code by using `@JsonKey(ignore: true)`.

* Throw an exception if a private field or an ignored field is referenced by a
  required constructor argument.

* More comprehensive escaping of string literals.

### `package:json_serializable/type_helper.dart`

* **Breaking** The `nullable` parameter on `TypeHelper.serialize` and
  `.deserialize` has been removed. It is now exposed in `SerializeContext` and
   `DeserializeContext` abstract classes as a read-only property.

* **Potentially Breaking** The `metadata` property on `SerializeContext` and
  `DeserializeContext` is now readonly. This would potentially break code that
  extends these classes – which is not expected.

## 0.4.0

* **Potentially Breaking** Inherited fields are now processed and used
  when generating serialization and deserialization code. There is a possibility
  that the generated code may change in undesired ways for classes annotated for
  `v0.3`.

* Avoid unnecessary braces in string escapes.

* Use single quotes when generating code.

## 0.3.2

* The `require_library_directive` option now defaults to `false`.
  The option will be removed entirely in `0.4.0`.

## 0.3.1+2

* Support the latest version of the `analyzer` package.

## 0.3.1+1

* Expanded `package:build` support to allow version `0.12.0`.

## 0.3.1

* Add a `build.yaml` so the builder can be consumed by users of `build_runner`
  version 0.7.0.

* Now requires a Dart `2.0.0-dev` release.

## 0.3.0

* **NEW** top-level library `json_serializable.dart`.

  * Replaces now deprecated `generators.dart` to access
  `JsonSerializableGenerator` and `JsonLiteralGenerator`.

  * Adds the `jsonPartBuilder` function to make it easy to create a
    `PartBuilder`, without creating an explicit dependency on `source_gen`.

* **BREAKING** `UnsupportedTypeError` added a new required constructor argument:
  `reason`.

* **BREAKING** The deprecated `annotations.dart` library has been removed.
  Use `package:json_annotation` instead.

* **BREAKING** The arguments to `TypeHelper` `serialize` and `deserialize` have
  changed.
  * `SerializeContext` and `DeserializeContext` (new classes) are now passed
    instead of the `TypeHelperGenerator` typedef (which has been deleted).

* `JsonSerializableGenerator` now supports an optional `useWrappers` argument
  when generates and uses wrapper classes to (hopefully) improve the speed and
  memory usage of serialization – at the cost of more code.

  **NOTE**: `useWrappers` is not guaranteed to improve the performance of
  serialization. Benchmarking is recommended.

* Make `null` field handling smarter. If a field is classified as not
  `nullable`, then use this knowledge when generating serialization code –  even
  if `includeIfNull` is `false`.

## 0.2.5

* Throw an exception if a duplicate JSON key is detected.

* Support the `nullable` field on the `JsonSerializable` class annotation.

## 0.2.4+1

* Throw a more helpful error when a constructor is missing.

## 0.2.4

* Moved the annotations in `annotations.dart` to `package:json_annotations`.
  * Allows package authors to release code that has the corresponding
    annotations without requiring package users to inherit all of the transitive
    dependencies.

* Deprecated `annotations.dart`.

## 0.2.3

* Write out `toJson` methods more efficiently when the first fields written are
  not intercepted by the null-checking method.

## 0.2.2+1

* Simplify the serialization of `Map` instances when no conversion is required
  for `values`.

* Handle `int` literals in JSON being assigned to `double` fields.

## 0.2.2

* Enable support for `enum` values.
* Added `asConst` to `JsonLiteral`.
* Improved the handling of Dart-specific characters in JSON strings.

## 0.2.1

* Upgrade to `package:source_gen` v0.7.0

## 0.2.0+1

* When serializing classes that implement their own `fromJson` constructor,
  honor their constructor parameter type.

## 0.2.0

* **BREAKING** Types are now segmented into their own libraries.

  * `package:json_serializable/generators.dart` contains `Generator`
    implementations.

  * `package:json_serializable/annotations.dart` contains annotations.
    This library should be imported with your target classes.

  * `package:json_serializable/type_helpers.dart` contains `TypeHelper` classes
    and related helpers which allow custom generation for specific types.

* **BREAKING** Generation fails for types that are not a JSON primitive or that
  do not explicitly supports JSON serialization.

* **BREAKING** `TypeHelper`:

  * Removed `can` methods. Return `null` from `(de)serialize` if the provided
    type is not supported.

  * Added `(de)serializeNested` arguments to `(de)serialize` methods allowing
    generic types. This is how support for `Iterable`, `List`, and `Map`
    is implemented.

* **BREAKING** `JsonKey.jsonName` was renamed to `name` and is now a named
  parameter.

* Added support for optional, non-nullable fields.

* Added support for excluding `null` values when generating JSON.

* Eliminated all implicit casts in generated code. These would end up being
  runtime checks in most cases.

* Provide a helpful error when generation fails due to undefined types.

## 0.1.0+1

* Fix homepage in `pubspec.yaml`.

## 0.1.0

* Split off from [source_gen](https://pub.dev/packages/source_gen).

* Add `/* unsafe */` comments to generated output likely to be unsafe.

* Support (de)serializing values in `Map`.

* Fix ordering of fields when they are initialized via constructor.

* Don't use static members when calculating fields to (de)serialize.
