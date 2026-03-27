import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'sign_engine.dart';

/// IntegrityEngine: Verifies the integrity of kernel files against the signed manifest.
class IntegrityEngine {
  final SignEngine _signer = SignEngine();

  /// SSSoT: Verifies the tool itself against vault/self.hashes (VUL-01).
  Future<bool> verifySelf({required String toolRoot}) async {
    final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
    if (!await selfHashesFile.exists()) return true;
    
    final Map<String, dynamic> manifest = jsonDecode(await selfHashesFile.readAsString());
    for (var entry in manifest.entries) {
      final file = File(p.join(toolRoot, entry.key));
      if (!await file.exists()) return false;
      final actual = await _calculateHash(file);
      if (actual.toLowerCase() != entry.value.toString().toLowerCase()) return false;
    }
    return true;
  }

  /// Generates hashes for all critical files in the kernel (S12).
  Future<Map<String, String>> generateHashes({required String basePath}) async {
    final Map<String, String> manifest = {};
    final binDir = Directory(p.join(basePath, 'bin'));
    final libDir = Directory(p.join(basePath, 'lib'));

    final sourceFiles = <File>[];
    if (await binDir.exists()) sourceFiles.addAll(binDir.listSync(recursive: true).whereType<File>());
    if (await libDir.exists()) sourceFiles.addAll(libDir.listSync(recursive: true).whereType<File>());

    sourceFiles.sort((a, b) => a.path.compareTo(b.path));

    for (final file in sourceFiles) {
      if (file.path.endsWith('.dart')) {
        final relativePath = p.relative(file.path, from: basePath).replaceAll('\\', '/');
        manifest[relativePath] = await _calculateHash(file);
      }
    }
    return manifest;
  }

  /// Verifies all files listed in vault/kernel.hashes.
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

  /// Detects files in the kernel that are NOT in the manifest.
  Future<List<String>> detectOrphans({required String basePath}) async {
    final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
    if (!await hashesFile.exists()) return [];

    final Map<String, dynamic> manifest = jsonDecode(await hashesFile.readAsString());
    final List<String> orphans = [];

    final binDir = Directory(p.join(basePath, 'bin'));
    final libDir = Directory(p.join(basePath, 'lib'));

    final List<FileSystemEntity> actualFiles = [];
    if (await binDir.exists()) actualFiles.addAll(binDir.listSync(recursive: true));
    if (await libDir.exists()) actualFiles.addAll(libDir.listSync(recursive: true));

    for (var entity in actualFiles) {
      if (entity is File) {
        // VUL-09: Cualquier archivo extra en bin/ o lib/ debe ser detectado como huérfano.
        final relativePath = p.relative(entity.path, from: basePath).replaceAll('\\', '/');
        if (!manifest.containsKey(relativePath)) {
          orphans.add(relativePath);
        }
      }
    }
    return orphans;
  }

  /// S12-02: Signs the manifest file (VUL-08).
  Future<void> signManifest({required String basePath, required String privateKeyXml}) async {
    final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
    final sigFile = File(p.join(basePath, 'vault', 'kernel.hashes.sig'));
    
    final content = await hashesFile.readAsBytes();
    stderr.writeln('DEBUG-INTEGRITY: SignManifest - Content Hash: ${sha256.convert(content)}');
    final signature = await _signer.sign(
      challenge: Uint8List.fromList(content),
      privateKeyXml: privateKeyXml,
    );
    
    print('DEBUG-INTEGRITY: Signature generated, length: ${signature.length} bytes');
    await sigFile.writeAsBytes(signature);
    print('[✅] Manifiesto SELLADO con firma RSA.');
  }

  /// S12-02: Verifies the manifest file signature (VUL-08).
  Future<bool> verifyManifest({required String basePath, required String publicKeyXml}) async {
    final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
    final sigFile = File(p.join(basePath, 'vault', 'kernel.hashes.sig'));
    
    if (!await sigFile.exists()) return false;
    
    final content = await hashesFile.readAsBytes();
    stderr.writeln('DEBUG-INTEGRITY: VerifyManifest - Content Hash: ${sha256.convert(content)}');
    final signature = await sigFile.readAsBytes();
    
    return await _signer.verify(
      challenge: Uint8List.fromList(content),
      signature: signature,
      publicKeyXml: publicKeyXml,
    );
  }

  Future<String> _calculateHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString().toUpperCase();
  }

  /// Generates a MAC for session data (VUL-16).
  String generateSessionMAC(Map<String, dynamic> data) {
    final Map<String, dynamic> copy = Map.from(data);
    copy.remove('_mac');
    final sortedKeys = copy.keys.toList()..sort();
    final buffer = StringBuffer();
    for (var key in sortedKeys) {
      buffer.write('$key:${copy[key]}|');
    }
    
    final key = utf8.encode('GATE-GOLD-HMAC-KEY-S11'); 
    final bytes = utf8.encode(buffer.toString());
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Verifies the MAC of the session data (VUL-16).
  bool verifySessionMAC(Map<String, dynamic> data) {
    if (!data.containsKey('_mac')) return false;
    final expectedMac = data['_mac'];
    final actualMac = generateSessionMAC(data);
    return actualMac == expectedMac;
  }

  /// S13-01: Anchors the ledger tip hash in the session lock (VUL-11).
  Future<void> updateLedgerAnchor({required String basePath, required String tipHash}) async {
    final lockFile = File(p.join(basePath, 'session.lock'));
    if (!await lockFile.exists()) return;

    final lockData = jsonDecode(await lockFile.readAsString());
    lockData['ledger_tip_hash'] = tipHash;
    lockData['_mac'] = generateSessionMAC(lockData);

    await lockFile.writeAsString(jsonEncode(lockData));
    print('DEBUG-INTEGRITY: Ledger anchor UPDATED in session.lock.');
  }

  /// S13-01: Verifies the ledger anchor against HISTORY.md (VUL-11).
  Future<bool> verifyLedgerAnchor({required String basePath}) async {
    final lockFile = File(p.join(basePath, 'session.lock'));
    if (!await lockFile.exists()) return true; // No session, nothing to anchor

    final lockData = jsonDecode(await lockFile.readAsString());
    if (!verifySessionMAC(lockData)) {
      print('[CRITICAL] KERNEL-VIOLATION: session.lock MAC inválido (VUL-11).');
      return false;
    }

    final String? anchoredHash = lockData['ledger_tip_hash'];
    if (anchoredHash == null) return true; // Not anchored yet

    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    if (!await historyFile.exists()) return false;

    final lines = await historyFile.readAsLines();
    if (lines.isEmpty) return false;

    final lastLine = lines.lastWhere((l) => l.startsWith('|'), orElse: () => '');
    if (lastLine.isEmpty) return false;

    final actualHash = sha256.convert(utf8.encode(lastLine)).toString();
    
    if (actualHash != anchoredHash) {
      print('[CRITICAL] LEDGER-CORRUPTION: El hash del historial no coincide con el ancla en session.lock.');
      print('  Esperado: $anchoredHash');
      print('  Actual:   $actualHash');
      return false;
    }

    print('  [✅] LEDGER-ANCHOR: OK');
    return true;
  }
}
