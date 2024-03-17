import 'dart:io';

import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:melos/melos.dart'
    show MelosLogger, MelosWorkspace, MelosWorkspaceConfig;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Writes a `.melos_packages` file to the root of the workspace with the
/// packages that are compatible with the current Dart SDK version.
/// This is useful for CI scripts that need to know which packages to run
/// melos for using the `MELOS_PACKAGES` environment variable.
void main() async {
  final root =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;
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
  final String validPackages = packages
      .where((e) => e.pubSpec.environment!.sdkConstraint!.allows(current))
      .map((e) => e.name)
      .join(',');

  File('$root/.melos_packages')
      .writeAsStringSync('MELOS_PACKAGES=$validPackages');
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
