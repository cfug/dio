# CHANGELOG

## Unreleased

*None.*

## 2.1.1

- Move all source Dart files to `*_impl.dart` to avoid naming collision.
  This is a workaround of https://github.com/dart-lang/sdk/issues/56498.

## 2.1.0

- Support `FileAccessMode` in `Dio.download` and `Dio.downloadUri` to change download file opening mode.

## 2.0.0

- Supports the WASM environment. Users should upgrade the adapter with
  `dart pub upgrade` or `flutter pub upgrade` to use the WASM-supported version.

## 1.0.1

- Improves warning logs on the Web platform.

## 1.0.0

- Split the Web ability from the `package:dio`.
