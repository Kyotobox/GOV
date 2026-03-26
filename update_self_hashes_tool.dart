import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main() async {
  final toolRoot = Directory.current.path;
  final binDir = Directory(p.join(toolRoot, 'bin'));
  final libDir = Directory(p.join(toolRoot, 'lib'));

  final sourceFiles = <File>[];
  if (await binDir.exists()) {
    sourceFiles.addAll(binDir.listSync(recursive: true).whereType<File>());
  }
  if (await libDir.exists()) {
    sourceFiles.addAll(libDir.listSync(recursive: true).whereType<File>());
  }

  Map<String, String> manifest = {};
  for (final file in sourceFiles) {
    final relativePath = p.relative(file.path, from: toolRoot).replaceAll('\\', '/');
    final bytes = await file.readAsBytes();
    manifest[relativePath] = sha256.convert(bytes).toString();
  }

  final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
  await selfHashesFile.writeAsString(JsonEncoder.withIndent('  ').convert(manifest));
  print('vault/self.hashes updated with ${manifest.length} files.');
}
