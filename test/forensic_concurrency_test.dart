import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';

void main() {
  late Directory tempDir;
  late ForensicLedger ledger;
  late String basePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forensic_test_');
    basePath = tempDir.path;
    ledger = ForensicLedger();
    
    // Create initial session.lock to allow anchoring
    final integrity = IntegrityEngine();
    final lockFile = File(p.join(basePath, 'session.lock'));
    final lockData = {'status': 'IN_PROGRESS', 'timestamp': DateTime.now().toIso8601String()};
    lockData['_mac'] = integrity.generateSessionMAC(lockData);
    await lockFile.writeAsString(jsonEncode(lockData));
    
    // Create vault dir
    await Directory(p.join(basePath, 'vault')).create();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('ForensicLedger: Concurrency Stress Test (VUL-12)', () async {
    const numParallel = 10;
    final futures = <Future>[];

    for (var i = 0; i < numParallel; i++) {
        futures.add(ledger.appendEntry(
          sessionId: 'TEST-SESSION', 
          type: 'EXEC', 
          task: 'TASK-$i', 
          detail: 'Concurrent entry $i', 
          basePath: basePath
        ));
    }

    await Future.wait(futures);

    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    final lines = await historyFile.readAsLines();
    
    // Header (2 lines) + numParallel entries
    expect(lines.length, equals(numParallel + 2));
    
    // Verify chain integrity
    for (int i = 3; i < lines.length; i++) {
        final prevLine = lines[i-1];
        final currLine = lines[i];
        
        final prevHash = sha256.convert(utf8.encode(prevLine)).toString();
        // The current line's 4th column (index 3 in split('|')) should be prevHash
        final parts = currLine.split('|');
        final recordedPrevHash = parts[3].trim();
        
        expect(recordedPrevHash, equals(prevHash), reason: 'Chain broken at line $i');
    }
  });
}
