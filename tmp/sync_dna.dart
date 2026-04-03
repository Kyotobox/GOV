import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart sync_dna.dart <base_path>');
    exit(1);
  }

  final basePath = args[0];
  final vaultDir = Directory(p.join(basePath, 'vault'));
  if (!vaultDir.existsSync()) vaultDir.createSync(recursive: true);

  final manifests = ['kernel.hashes', 'self.hashes'];

  for (final manifestName in manifests) {
    print('--- Sincronizando $manifestName en $basePath ---');
    final Map<String, String> manifest = {};
    
    final binDir = Directory(p.join(basePath, 'bin'));
    final libDir = Directory(p.join(basePath, 'lib'));

    final sourceFiles = <File>[];
    if (binDir.existsSync()) sourceFiles.addAll(binDir.listSync(recursive: true).whereType<File>());
    if (libDir.existsSync()) sourceFiles.addAll(libDir.listSync(recursive: true).whereType<File>());

    sourceFiles.sort((a, b) => a.path.compareTo(b.path));

    for (final file in sourceFiles) {
      if (file.path.endsWith('.dart')) {
        final relativePath = p.relative(file.path, from: basePath).replaceAll('\\', '/');
        final bytes = file.readAsBytesSync();
        manifest[relativePath] = sha256.convert(bytes).toString().toUpperCase();
      }
    }

    // Include critical governance documents if they exist in root
    final rootDocs = ['VISION.md', 'GEMINI.md', 'backlog.json', 'PROJECT_LOG.md'];
    for (final doc in rootDocs) {
      final file = File(p.join(basePath, doc));
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        manifest[doc] = sha256.convert(bytes).toString().toUpperCase();
      }
    }

    final manifestFile = File(p.join(vaultDir.path, manifestName));
    await manifestFile.writeAsString(jsonEncode(manifest));
    print('[DONE] $manifestName generado con ${manifest.length} entradas.');
  }
}
