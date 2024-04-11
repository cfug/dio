# Dio shared test package

The package gathered shared tests between Dio's packages,
such as `dio` and `http2_adapter`.

The package was meant to not be published to pub.dev.
To use the package in tests, make the library depend like this:

```yaml
dev_dependencies:
  # Shared test package.
  dio_test:
    git:
      url: https://github.com/cfug/dio
      path: dio_test
```

Then, use `dependency_overrides` or `pubspec_overrides.yaml`
to override the package to a local path or somewhere else.

## Copyright & License

The project is authored by
[Chinese Flutter User Group (@cfug)](https://github.com/cfug)
since 2024.

The project consents [the MIT license](LICENSE).
