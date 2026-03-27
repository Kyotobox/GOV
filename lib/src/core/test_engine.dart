import 'dart:io';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';

/// Engine to execute and validate project tests before sealing a baseline.
class TestEngine {
  /// Runs all project tests. Returns true if all tests pass.
  Future<bool> runAllTests({required String basePath}) async {
    print('--- [TEST-GUARD] EJECUTANDO PRUEBAS UNITARIAS ---');
    
    // In a real scenario, this command could be configurable via gov.yaml
    // For now, we use standard 'dart test'
    final result = await Process.run(
      'dart',
      ['test'],
      workingDirectory: basePath,
      runInShell: true,
    );

    final ledger = ForensicLedger();
    
    if (result.exitCode == 0) {
      print('  [✅] TEST-PASS: Todas las pruebas han pasado.');
      return true;
    } else {
      print('\n[‼️] CRITICAL: Fallo detectado en las pruebas unitarias.');
      print(result.stdout);
      print(result.stderr);
      
      await ledger.appendEntry(
        sessionId: 'GATE-RED',
        type: 'ALERT',
        task: 'TEST-FAIL',
        detail: 'Pruebas unitarias fallidas durante el baseline.',
        basePath: basePath,
      );
      return false;
    }
  }
}
