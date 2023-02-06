# diox

Language: English | [简体中文](README-ZH.md)

This is the base repo of the **diox** project.
Please move specific paths for projects instructions.

To use below packages as a corresponding package to `dio`,
see the details below.

<details>
<summary>Expand to see fork details...</summary>

`diox` is developed based on the code base of `dio`
([@ac78e61](https://github.com/flutterchina/dio/commit/ac78e6151e1736f945cb9b215bbcfac230e19cf1)),
it can be used as a fork of `dio` theoretically with the `dio` branch.
However, our goal is not to role as a fork,
and `diox` also includes breaking changes during the development.
You'll need a few steps to migrate to whether the new fork and the new `diox`.

If you use it as a fork:
1. Use `dependency_overrides` in your `pubspec.yaml`:
   ```yaml
   dependency_overrides:
     dio: # Change to other names if you're using plugins.
       git:
         url: https://github.com/cfug/diox
         path: dio/ # Change to other paths if you're using plugins.
         ref: dio
   ```
2. Migrate the breaking changes according to [the migration guide](dio/migration_guide.md).
3. Now you can continue to `import 'package:dio/dio.dart';`.

Still, we prefer to use `diox` directly since the fork will
**only maintain for the first 6 months** according to our announcement,
then it will be deprecated.

The dio branch will be synced (cherry-pick commits) before every release of packages.

</details>

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
