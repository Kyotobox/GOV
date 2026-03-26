import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final manifestFile = File('vault/kernel.hashes');
  final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final newManifest = <String, String>{};
  for (final key in manifest.keys) {
    final file = File(key);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      newManifest[key] = sha256.convert(bytes).toString().toUpperCase();
    }
  }
  // Add missing files to manifest if they are core
  final coreFiles = ['backlog.json', 'VISION.md', 'GEMINI.md', 'COMMANDS.md', 'CHANGELOG.md', 'task.md', 'pubspec.yaml'];
  for (final f in coreFiles) {
    final file = File(f);
    if (await file.exists()) {
       final bytes = await file.readAsBytes();
       newManifest[f] = sha256.convert(bytes).toString().toUpperCase();
    }
  }

  await manifestFile.writeAsString(jsonEncode(newManifest));
  print('KERNEL-SYNC-OK');
}
