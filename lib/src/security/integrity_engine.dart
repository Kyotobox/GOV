import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// IntegrityEngine: Verifies the integrity of kernel files against the signed manifest.
class IntegrityEngine {
  /// Verifies all files listed in vault/kernel.hashes.
  /// Returns a map of filename to verification status (true = OK, false = CORRUPT).
  Future<Map<String, bool>> verifyAll({required String basePath}) async {
    final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
    if (!await hashesFile.exists()) {
      throw Exception('Integrity check failed: vault/kernel.hashes not found.');
    }

    final content = await hashesFile.readAsString();
    final Map<String, dynamic> expectedHashes = jsonDecode(content);
    Map<String, bool> results = {};

    for (var entry in expectedHashes.entries) {
      final fileName = entry.key;
      final expectedHash = entry.value.toString().toUpperCase();
      final file = File(p.join(basePath, fileName));

      if (!await file.exists()) {
        results[fileName] = false;
        continue;
      }

      final actualHash = await _calculateHash(file);
      results[fileName] = (actualHash.toLowerCase() == expectedHash.toString().toLowerCase());
    }

    return results;
  }

  /// Calculates the SHA-256 hash of a file (Hex string, Uppercase).
  Future<String> _calculateHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString().toUpperCase();
  }

  /// Verifies the integrity of the tool's own source code against a manifest.
  /// (TASK-DPI-04: Self-Audit Mechanism)
  Future<bool> verifySelf({required String toolRoot}) async {
    final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
    if (!await selfHashesFile.exists()) {
      print(
        '[CRITICAL] SELF-AUDIT-FAIL: El manifiesto de hashes (vault/self.hashes) no fue encontrado.',
      );
      return false; // Per GEMINI.md, self-audit is mandatory.
    }

    final manifest =
        jsonDecode(await selfHashesFile.readAsString()) as Map<String, dynamic>;
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
      // Normalize path for cross-platform consistency in the manifest
      final relativePath = p
          .relative(file.path, from: toolRoot)
          .replaceAll('\\', '/');
      final expectedHash = manifest[relativePath];

      if (expectedHash == null) {
        print(
          '[CRITICAL] SELF-AUDIT-FAIL: Archivo no registrado en manifiesto encontrado: $relativePath',
        );
        return false; // Untracked file is a violation
      }

      final fileBytes = await file.readAsBytes();
      final actualHash = sha256.convert(fileBytes).toString();

      if (actualHash.toLowerCase() != expectedHash.toString().toLowerCase()) {
        print(
          '[CRITICAL] SELF-AUDIT-FAIL: Hash incorrecto para: $relativePath',
        );
        print('  - Esperado: $expectedHash');
        print('  - Obtenido: $actualHash');
        return false; // Hash mismatch
      }
    }

    print('[INFO] Self-Audit PASSED. Integridad de la herramienta verificada.');
    return true;
  }

  /// Detects files in the root directory that are NOT in the manifest.
  /// (TASK-DPI-S07-02: Strict Audit)
  Future<List<String>> detectOrphans({
    required String basePath,
    required List<String> knownFiles,
  }) async {
    final rootDir = Directory(basePath);
    final orphans = <String>[];
    
    final entries = await rootDir.list().where((e) => e is File).toList();
    final systemPrefixes = ['.', 'lib', 'bin', 'test', 'vault', 'pubspec', 'analysis_options'];

    for (var entity in entries) {
      final name = p.basename(entity.path);
      
      // Skip system directories and hidden files
      if (systemPrefixes.any((prefix) => name.startsWith(prefix))) continue;
      
      // Skip known files in manifest
      if (knownFiles.contains(name)) continue;

      orphans.add(name);
    }

    return orphans;
  }
}
