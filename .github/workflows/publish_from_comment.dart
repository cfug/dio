import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

const _packagesMapping = <String, String>{
  'dio': 'dio',
  'cookie_manager': 'plugins/cookie_manager',
  'http2_adapter': 'plugins/http2_adapter',
  'native_dio_adapter': 'plugins/native_dio_adapter',
};
late final _packages = _packagesMapping.keys.join('|');
final _validRegExp = RegExp('^([$_packages]+):\\s*v(\\d+.\\d+.\\d+\\+?\\d*)\$');

/// Headers constants
const _unreleasedHeader = '## Unreleased';

List<String> main(List<String> body) {
  final List<String?> groups =
      _validRegExp.allMatches(body.join(' ')).first.groups([1, 2]);
  final String name = groups.first!;
  final String version = groups.last!;
  final String path = _packagesMapping[name]!;
  final fChangelog = File('$path/CHANGELOG.md');
  final sChangelog = fChangelog.readAsStringSync();
  if (sChangelog.contains(_unreleasedHeader)) {
    fChangelog.writeAsString(
      sChangelog.replaceAll(
        _unreleasedHeader,
        '$_unreleasedHeader\n\n*None.*\n\n## $version',
      ),
    );
  }
  final fPubspec = File('$path/pubspec.yaml');
  final yamlEditor = YamlEditor(fPubspec.readAsStringSync())
    ..update(['version'], version);
  fPubspec.writeAsString(yamlEditor.toString());
  return [name, version];
}
