# diox

Language: English | [简体中文](README-ZH.md)

This is the base repo of the **diox** project.
Please move specific paths for projects instructions.

To use below packages as a corresponding package to `dio`,
use `dependency_overrides` in your `pubspec.yaml`:

```yaml
dependency_overrides:
  dio:
    git:
      url: https://github.com/cfug/diox
      path: dio/
      ref: dio
```

### diox (dio)

- diox: [link](dio)
  [![Pub](https://img.shields.io/pub/v/diox.svg?label=dev&include_prereleases)](https://pub.dev/packages/diox)

### Plugins

- cookie_manager: [link](plugins/cookie_manager)
  [![Pub](https://img.shields.io/pub/v/diox_cookie_manager.svg?label=dev&include_prereleases)](https://pub.dev/packages/diox_cookie_manager)
- http2_adapter: [link](plugins/http2_adapter)
  [![Pub](https://img.shields.io/pub/v/diox_http2_adapter.svg?label=dev&include_prereleases)](https://pub.dev/packages/diox_http2_adapter)
- native_diox_adapter: [link](plugins/native_diox_adapter)
  [![Pub](https://img.shields.io/pub/v/native_diox_adapter.svg?label=dev&include_prereleases)](https://pub.dev/packages/native_diox_adapter)

### Examples

- example: [link](example)
- example_flutter_app: [link](example_flutter_app)

## Copyright & License

The project is originally authored by
[@wendux](https://github.com/wendux)
with the organization
[@flutterchina](https://github.com/flutterchina),
hard-forked at 2022 and maintained by
[@cfug](https://github.com/cfug).

The project consents [the MIT license](LICENSE).
