import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';

void main() {
  group('Forensic Integrity Tests (GATE-GOLD)', () {
    late Directory tempDir;
    late IntegrityEngine engine;
    late String basePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('forensic_test');
      basePath = tempDir.path;
      engine = IntegrityEngine();
      
      // Setup minimal Vault structure
      await Directory(p.join(basePath, 'vault')).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('Valid Chain Verification', () async {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      final header = '| Timestamp | Role | SessionID | PrevHash | Type | Task | Detail |\n'
                     '| :--- | :--- | :--- | :--- | :--- | :--- | :--- |';
      
      final line1 = '| 2026-03-27 | AI | S1 | 0000000000000000000000000000000000000000000000000000000000000000 | BASE | T1 | D1 |';
      final h1 = sha256.convert(utf8.encode(line1)).toString();
      
      final line2 = '| 2026-03-27 | AI | S1 | $h1 | SNAP | T2 | D2 |';
      
      await historyFile.writeAsString('$header\n$line1\n$line2\n');
      
      final result = await engine.verifyChain(basePath: basePath);
      expect(result, isTrue, reason: 'Chain should be valid');
    });

    test('Broken Chain Detection (Invalid PrevHash)', () async {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      final header = '| T | R | S | P | T | T | D |\n|---|---|---|---|---|---|---|';
      
      final line1 = '| 2026-03-27 | AI | S1 | 0000000000000000000000000000000000000000000000000000000000000000 | BASE | T1 | D1 |';
      // INCORRECT PrevHash in line 2
      final line2 = '| 2026-03-27 | AI | S1 | WRONG-HASH-1234567890 | SNAP | T2 | D2 |';
      
      await historyFile.writeAsString('$header\n$line1\n$line2\n');
      
      final result = await engine.verifyChain(basePath: basePath);
      expect(result, isFalse, reason: 'Should detect broken cryptographic link');
    });

    test('Byte-Accuracy Detection (Trailing Space)', () async {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      final header = '| T | R | S | P | T | T | D |\n|---|---|---|---|---|---|---|';
      
      final line1 = '| 2026-03-27 | AI | S1 | 0000000000000000000000000000000000000000000000000000000000000000 | BASE | T1 | D1 |';
      final h1 = sha256.convert(utf8.encode(line1)).toString();
      
      // Tamper line 1 by adding a space at the end AFTER hashing
      final line1Tampered = '$line1 '; 
      final line2 = '| 2026-03-27 | AI | S1 | $h1 | SNAP | T2 | D2 |';
      
      await historyFile.writeAsString('$header\n$line1Tampered\n$line2\n');
      
      final result = await engine.verifyChain(basePath: basePath);
      expect(result, isFalse, reason: 'Should detect trailing space modification');
    });

    test('Anchor vs Tip Mismatch Detection', () async {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      final header = '| T | R | S | P | T | T | D |\n|---|---|---|---|---|---|---|';
      final line1 = '| 2026-03-27 | AI | S1 | 0000000000000000000000000000000000000000000000000000000000000000 | BASE | T1 | D1 |';
      final h1 = sha256.convert(utf8.encode(line1)).toString();
      await historyFile.writeAsString('$header\n$line1\n');

      // Create valid session.lock but with WRONG tip hash
      final lockFile = File(p.join(basePath, 'session.lock'));
      final lockData = {
        'session_id': 'S1',
        'ledger_tip_hash': 'ANOTHER-TIP-HASH',
      };
      lockData['_mac'] = engine.generateSessionMAC(lockData);
      await lockFile.writeAsString(jsonEncode(lockData));
      
      final result = await engine.verifyChain(basePath: basePath);
      expect(result, isFalse, reason: 'Should fail if anchor doesn\'t match ledger tip');
    });

    test('Anchored MAC Violation Detection', () async {
      final historyFile = File(p.join(basePath, 'HISTORY.md'));
      final header = '| T | R | S | P | T | T | D |\n|---|---|---|---|---|---|---|';
      final line1 = '| 2026-03-27 | AI | S1 | 0000000000000000000000000000000000000000000000000000000000000000 | BASE | T1 | D1 |';
      final h1 = sha256.convert(utf8.encode(line1)).toString();
      await historyFile.writeAsString('$header\n$line1\n');

      // Create session.lock with INVALID MAC
      final lockFile = File(p.join(basePath, 'session.lock'));
      final lockData = {
        'session_id': 'S1',
        'ledger_tip_hash': h1,
        '_mac': 'INVALID-MAC-12345'
      };
      await lockFile.writeAsString(jsonEncode(lockData));
      
      final result = await engine.verifyChain(basePath: basePath);
      expect(result, isFalse, reason: 'Should fail if session.lock MAC is invalid');
    });
  });
}
