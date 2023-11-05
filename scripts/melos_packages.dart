import 'dart:io';

import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:melos/melos.dart'
    show MelosLogger, MelosWorkspace, MelosWorkspaceConfig;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final root = Platform.environment['MELOS_ROOT_PATH'] as String;
  final config = MelosWorkspaceConfig.fromYaml(
    loadYamlNode(
      File('$root/melos.yaml').readAsStringSync(),
    ).toPlainObject() as Map,
    path: root,
  );
  final workspace = await MelosWorkspace.fromConfig(
    config,
    logger: MelosLogger(Logger.standard()),
  );
  final packages = workspace.filteredPackages.values;
  final current = Version.parse(
    RegExp(r'\d*\.\d*\.\d*').firstMatch(Platform.version)!.group(0)!,
  );
  if (arguments.first == 'true') {
    final satisfiedPackages = packages
        .map(
          (package) {
            if (package.pubSpec.environment!.sdkConstraint!.allows(current)) {
              return package.name;
            }
            return null;
          },
        )
        .whereType<String>()
        .join(',');
    print(satisfiedPackages);
  } else {
    final ignoresPackages = packages
        .map(
          (package) {
            if (package.pubSpec.environment!.sdkConstraint!.allows(current)) {
              return null;
            }
            return package.name;
          },
        )
        .whereType<String>()
        .map((e) => '--ignore="$e"')
        .join(' ');
    print(ignoresPackages);
  }
}

extension YamlUtils on YamlNode {
  /// Converts a YAML node to a regular mutable Dart object.
  Object? toPlainObject() {
    final node = this;
    if (node is YamlScalar) {
      return node.value;
    }
    if (node is YamlMap) {
      return {
        for (final entry in node.nodes.entries)
          (entry.key as YamlNode).toPlainObject(): entry.value.toPlainObject(),
      };
    }
    if (node is YamlList) {
      return node.nodes.map((node) => node.toPlainObject()).toList();
    }
    throw FormatException(
      'Unsupported YAML node type encountered: ${node.runtimeType}',
      this,
    );
  }
}
