# diox

Language: [English](README.md) | 简体中文

此处是 **diox** 项目的基础仓库。请前往项目各自的路径查看指引。

想要将下列 package 的作为 `dio` 对应 package 的一个分叉进行使用，
请在 `pubspec.yaml` 中配置 `dependency_overrides`，例如：

```yaml
dependency_overrides:
  dio:
    git:
      url: https://github.com/cfug/diox
      path: dio/
      ref: dio
```

### diox (dio)

- diox: [链接](dio)
  [![Pub](https://img.shields.io/pub/v/diox.svg?label=dev&include_prereleases)](https://pub.flutter-io.cn/packages/diox)

### 插件

- cookie_manager: [链接](plugins/cookie_manager)
  [![Pub](https://img.shields.io/pub/v/diox_cookie_manager.svg?label=dev&include_prereleases)](https://pub.flutter-io.cn/packages/diox_cookie_manager)
- http2_adapter: [链接](plugins/http2_adapter)
  [![Pub](https://img.shields.io/pub/v/diox_http2_adapter.svg?label=dev&include_prereleases)](https://pub.flutter-io.cn/packages/diox_http2_adapter)
- native_diox_adapter: [链接](plugins/native_diox_adapter)
  [![Pub](https://img.shields.io/pub/v/native_diox_adapter.svg?label=dev&include_prereleases)](https://pub.dev/packages/native_diox_adapter)

### 示例

- example: [链接](example)
- example_flutter_app: [链接](example_flutter_app)

## 版权 & 协议

该项目由 [@flutterchina](https://github.com/flutterchina)
开源组织的 [@wendux](https://github.com/wendux) 创作，
并在 2022 年由 [@cfug](https://github.com/cfug)
组织进行硬分叉并维护。

该项目遵循 [MIT 开源协议](LICENSE)。
