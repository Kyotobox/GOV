import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'sign_engine.dart';

/// IntegrityEngine: Verifies the integrity of kernel files against the signed manifest.
class IntegrityEngine {
  // S21-02: Reglas de Saturación (Inmutables)
  static const int kMaxRootFiles = 20;
  static const double kZombiePenalty = 20.0;
  static const double kPanicThreshold = 90.0;

  final SignEngine _signer = SignEngine();

  /// S19-FORTRESS: Verifies the cryptographic chain of HISTORY.md (VUL-11/12).
  Future<bool> verifyChain({required String basePath}) async {
    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    if (!await historyFile.exists()) return true;

    final lines = await historyFile.readAsLines();
    if (lines.length < 3) return true; // Just header or empty

    // [REPORT-FIX]: Determinar dinámicamente el índice de la columna PrevHash (VUL-11/12)
    final headerParts = lines[0].split('|').map((e) => e.trim()).toList();
    int prevHashIndex = headerParts.indexOf('PrevHash');
    
    if (prevHashIndex == -1) {
      print('[FORENSIC-FAIL] No se encontró la columna "PrevHash" en HISTORY.md.');
      return false;
    }

    String expectedPrevHash = '0000000000000000000000000000000000000000000000000000000000000000';
    
    for (int i = 2; i < lines.length; i++) {
      final rawLine = lines[i];
      if (rawLine.trim().isEmpty) continue;

      final parts = rawLine.split('|');
      if (parts.length <= prevHashIndex) continue;

      final actualPrevHash = parts[prevHashIndex].trim();
      
      if (actualPrevHash != expectedPrevHash) {
        print('[FORENSIC-FAIL] Ruptura de cadena en línea ${i + 1}.');
        print('                Esperado: $expectedPrevHash');
        print('                Encontrado: $actualPrevHash');
        return false;
      }
      
      expectedPrevHash = sha256.convert(utf8.encode(rawLine)).toString();
    }
    
    // [REPORT-FIX]: Consolidate with verifyLedgerAnchor to ensure HMAC and DRY.
    return await verifyLedgerAnchor(basePath: basePath, currentTipHash: expectedPrevHash);
  }

  /// SSSoT: Verifies the tool itself against vault/self.hashes (VUL-01).
  Future<bool> verifySelf({required String toolRoot}) async {
    // 1. Verificar ADN Binario si existe gov_hash.sig
    final isBinaryIntact = await verifyBinaryDNA(toolRoot: toolRoot);
    if (!isBinaryIntact) return false;

    // 2. Verificar Manifiesto de Fuentes (Solo si hay fuentes)
    final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
    if (!await selfHashesFile.exists()) return true;
    
    // S24-GOLD: Si no hay carpeta 'bin' o 'lib', asumimos entorno de puro binario (Consumidor)
    final binDir = Directory(p.join(toolRoot, 'bin'));
    final libDir = Directory(p.join(toolRoot, 'lib'));
    if (!binDir.existsSync() && !libDir.existsSync()) {
      return true; // Bypass source check in purely binary environments
    }
    
    final Map<String, dynamic> manifest = jsonDecode(await selfHashesFile.readAsString());
    for (var entry in manifest.entries) {
      final file = File(p.join(toolRoot, entry.key));
      if (!await file.exists()) {
        // VUL-01: Si el manifiesto dice que debe existir, pero no está, y estamos en entorno DEV
        return false;
      }
      final actual = await _calculateHash(file);
      if (actual.toLowerCase() != entry.value.toString().toLowerCase()) return false;
    }
    return true;
  }

  /// S104-DNA: Real-Time Binary SHA-256 Validation.
  Future<bool> verifyBinaryDNA({required String toolRoot}) async {
    // S24-GOLD: Localización dinámica del binario para entornos distribuidos
    String exePath = p.join(toolRoot, 'gov.exe');
    if (!File(exePath).existsSync()) {
      exePath = Platform.resolvedExecutable;
      if (!exePath.endsWith('gov.exe') && !exePath.endsWith('vanguard.exe')) {
        return true; // No es un binario sellado (ej. dart run)
      }
    }

    final exeFile = File(exePath);
    final sigFile = File(p.join(p.dirname(exePath), '..', 'vault', 'intel', 'gov_hash.sig'));

    if (!sigFile.existsSync()) {
      // Fallback para búsqueda en raíz de proyecto
      final altSig = File(p.join(toolRoot, 'vault', 'intel', 'gov_hash.sig'));
      if (!altSig.existsSync()) {
         print('\x1B[33m[WARN] ALARMA DE ADN: Firma maestra (gov_hash.sig) no encontrada en rutas estándar.\x1B[0m');
         return true; // No bloqueamos si no hay firma (fase de transición)
      }
      return _checkDNA(exeFile, altSig);
    }

    return _checkDNA(exeFile, sigFile);
  }

  Future<bool> _checkDNA(File exeFile, File sigFile) async {
    final bytes = exeFile.readAsBytesSync();
    final currentHash = sha256.convert(bytes).toString().toLowerCase();
    final masterHash = sigFile.readAsStringSync().trim().toLowerCase();

    if (currentHash == masterHash) {
      return true;
    } else {
      print('\x1B[31m[CRITICAL] ALARMA DE INTEGRIDAD DE ADN: Hash mismatch detectado.\x1B[0m');
      print('[INFO] ADN Actual: $currentHash');
      return false;
    }
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

    // Include critical governance documents in the root
    final rootDocs = ['VISION.md', 'GEMINI.md', 'backlog.json'];
    for (final doc in rootDocs) {
      final file = File(p.join(basePath, doc));
      if (await file.exists()) {
        manifest[doc] = await _calculateHash(file);
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
  Future<bool> verifyLedgerAnchor({required String basePath, String? currentTipHash}) async {
    final lockFile = File(p.join(basePath, 'session.lock'));
    if (!await lockFile.exists()) return true; // No session, nothing to anchor

    final Map<String, dynamic> lockData = jsonDecode(await lockFile.readAsString());
    
    // [REPORT-FIX]: Mandatory HMAC verification (VUL-16)
    if (!verifySessionMAC(lockData)) {
      print('[CRITICAL] KERNEL-VIOLATION: session.lock MAC inválido o manipulado.');
      return false;
    }

    final String? anchoredHash = lockData['ledger_tip_hash'];
    if (anchoredHash == null) return true; // Not anchored yet

    String actualHash = '';
    if (currentTipHash != null) {
      actualHash = currentTipHash;
    } else {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      if (!await historyFile.exists()) return false;

      final lines = await historyFile.readAsLines();
      if (lines.isEmpty) return false;

      final lastLine = lines.lastWhere((l) => l.trim().startsWith('|'), orElse: () => '');
      if (lastLine.isEmpty) return false;

      actualHash = sha256.convert(utf8.encode(lastLine)).toString();
    }
    
    if (actualHash != anchoredHash) {
      print('[CRITICAL] LEDGER-CORRUPTION: El hash del historial no coincide con el ancla en session.lock.');
      print('  Esperado (Ancla): $anchoredHash');
      print('  Actual (Ledger):  $actualHash');
      return false;
    }

    print('  [✅] LEDGER-ANCHOR: OK');
    return true;
  }

  /// S22-01 [OPTIMIZADO]: Verifies SHS Root Density and Weight (Excluye 'Fontanería').
  Future<({int fileCount, int totalBytes, List<String> files})> checkSwelling(String basePath) async {
    final rootDir = Directory(basePath);
    final fileEntities = rootDir.listSync().whereType<File>().toList();
    
    // S24-GOLD: Definición de Fontanería (Ineludible pero no es carga cognitiva)
    const kPlumbing = {
      '.gitignore', 'pubspec.yaml', 'pubspec.lock', 
      '.flutter-plugins-dependencies', 'analysis_options.yaml'
    };

    int totalBytes = 0;
    int densityCount = 0;
    final fileNames = <String>[];
    
    for (var f in fileEntities) {
      final name = p.basename(f.path);
      fileNames.add(name);
      
      // Whitelist Estricta: Ignorar gov.exe en el peso
      if (name.toLowerCase() != 'gov.exe') {
        totalBytes += f.lengthSync();
      }

      // S24-GOLD: No contar archivos de infraestructura en la saturación (Density)
      if (!kPlumbing.contains(name) && !name.startsWith('.flutter-')) {
        densityCount++;
      }
    }
    
    return (fileCount: densityCount, totalBytes: totalBytes, files: fileNames);
  }

  /// S22-01: Detects non-allowed "Zombie" files in root.
  Future<List<String>> checkZombies(String basePath) async {
    final allowed = {
      'GEMINI.md', 'VISION.md', 'METHODOLOGY.md', 'PROJECT_LOG.md', 
      'task.md', 'backlog.json', 'DASHBOARD.md', 'README.md', 
      '.gitignore', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml',
      'session.lock', 'HISTORY.md', 'OP_IMPROVEMENTS.md'
    };
    final root = Directory(basePath).listSync().whereType<File>();
    final zombies = <String>[];
    for (var f in root) {
      final name = p.basename(f.path);
      if (allowed.contains(name) || name.startsWith('.') || name.endsWith('.exe')) continue;
      
      // TASK-*.md are managed by housekeeping relocation but marked as zombies for root
      if (name.startsWith('TASK-') && name.endsWith('.md')) continue;

      zombies.add(name);
    }
    return zombies;
  }

  /// S5.5: Blindaje Antialucinaciones - Verificación de Estabilidad Semántica.
  Future<bool> checkStability(String basePath) async {
    print('  [STABILITY] Auditando sanidad del código fuente...');
    try {
      final result = await Process.run('dart', ['analyze', '.'], workingDirectory: basePath);
      if (result.exitCode != 0) {
        print('\x1B[31m[CRITICAL] DRIFT SEMÁNTICO DETECTADO: El código contiene errores sintácticos.\x1B[0m');
        print(result.stdout);
        return false;
      }
      return true;
    } catch (_) {
      return true; // Si no hay dart, no bloqueamos (graceful degradation)
    }
  }
}
