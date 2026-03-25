import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main() async {
  final toolRoot = Directory.current.path;
  final manifest = <String, String>{};
  
  final binDir = Directory(p.join(toolRoot, 'bin'));
  final libDir = Directory(p.join(toolRoot, 'lib'));
  
  final sourceFiles = <File>[];
  if (await binDir.exists()) {
    sourceFiles.addAll(binDir.listSync(recursive: true).whereType<File>());
  }
  if (await libDir.exists()) {
    sourceFiles.addAll(libDir.listSync(recursive: true).whereType<File>());
  }
  
  for (final file in sourceFiles) {
    if (file.path.endsWith('.dart')) {
      final relativePath = p.relative(file.path, from: toolRoot).replaceAll('\\', '/');
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      manifest[relativePath] = hash;
    }
  }
  
  final vaultDir = Directory(p.join(toolRoot, 'vault'));
  if (!await vaultDir.exists()) await vaultDir.create();
  
  final selfHashesFile = File(p.join(vaultDir.path, 'self.hashes'));
  await selfHashesFile.writeAsString(JsonEncoder.withIndent('  ').convert(manifest));
  
  print('[INFO] self.hashes generado exitosamente con ${manifest.length} archivos.');
}
