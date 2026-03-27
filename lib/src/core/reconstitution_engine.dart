import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';

/// Engine to detect and revert unauthorized changes based on sealed hashes.
class ReconstitutionEngine {
  /// Compares current files against sealed hashes and offers restoration.
  Future<void> restore({required String basePath}) async {
    print('--- [RESTORE] RECONSTITUCIÓN DE INTEGRIDAD ---');
    final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
    if (!await hashesFile.exists()) {
      print('[ERROR] No se encontró kernel.hashes. No hay un baseline para restaurar.');
      return;
    }

    final sealedHashes = Map<String, String>.from(jsonDecode(await hashesFile.readAsString()));
    final integrity = IntegrityEngine();
    final currentHashes = await integrity.generateHashes(basePath: basePath);
    
    final differences = <String>[];
    sealedHashes.forEach((path, hash) {
      if (currentHashes[path] != hash) {
        differences.add(path);
      }
    });

    if (differences.isEmpty) {
      print('[✅] Integridad perfecta. No se detectaron desviaciones del baseline.');
      return;
    }

    print('[⚠️] Se detectaron ${differences.length} archivos desviados:');
    for (var path in differences) {
      print('  [-] $path');
    }

    print('\n[PROCEDIMIENTO] Restaurando archivos mediante Git Checkout...');
    for (var path in differences) {
      final result = await Process.run('git', ['checkout', 'HEAD', '--', path], workingDirectory: basePath);
      if (result.exitCode == 0) {
        print('  [✅] Restaurado: $path');
      } else {
        print('  [❌] Error al restaurar $path: ${result.stderr}');
      }
    }

    final ledger = ForensicLedger();
    await ledger.appendEntry(
      sessionId: 'GATE-RED',
      type: 'SNAP',
      task: 'RESTORE',
      detail: 'Reconstitución manual de ${differences.length} archivos.',
      basePath: basePath,
    );

    print('\n[✅] Reconstitución FINALIZADA. El Kernel vuelve a estar alineado con el baseline.');
  }
}
