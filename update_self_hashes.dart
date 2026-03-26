import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main() async {
  final toolRoot = Directory.current.path;
  final manifest = <String, String>{};
  void processDir(Directory dir) {
    if (!dir.existsSync()) return;
    for (var entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final rel = p.relative(entity.path, from: toolRoot).replaceAll('\\', '/');
        final bytes = entity.readAsBytesSync();
        manifest[rel] = sha256.convert(bytes).toString();
      }
    }
  }
  processDir(Directory(p.join(toolRoot, 'bin')));
  processDir(Directory(p.join(toolRoot, 'lib')));
  final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
  await selfHashesFile.writeAsString(JsonEncoder.withIndent('  ').convert(manifest));
  print('SELF-HASHES-UPDATED');
}
