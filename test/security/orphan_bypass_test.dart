import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';

void main() {
  late ComplianceGuard guard;
  late IntegrityEngine integrity;
  late String basePath;

  setUp(() {
    guard = ComplianceGuard();
    integrity = IntegrityEngine();
    basePath = Directory.current.path;
  });

  group('VUL-09: Orphan Substring Bypass Protection', () {
    test('ComplianceGuard: Block libpayload.dart (substring of lib/)', () {
       // lib/ is exempted, but libpayload.dart is NOT under lib/
       final modifiedFiles = ['libpayload.dart'];
       final allowedScope = <String>[]; // No extra scope
       
       // Should NOT be exempt, and since it is NOT in allowedScope, it's a violation
       final violations = guard.checkScopeLock(
         allowedScope: allowedScope, 
         modifiedFiles: modifiedFiles, 
         basePath: basePath
       );
       
       expect(violations, contains('libpayload.dart'));
    });

    test('ComplianceGuard: Block TASK-DPI-EXPLOIT.exe (substring of TASK-DPI-)', () {
       final modifiedFiles = ['TASK-DPI-EXPLOIT.exe'];
       final allowedScope = <String>[];
       
       final violations = guard.checkScopeLock(
         allowedScope: allowedScope, 
         modifiedFiles: modifiedFiles, 
         basePath: basePath
       );
       
       expect(violations, contains('TASK-DPI-EXPLOIT.exe'));
    });

    test('ComplianceGuard: Allow valid TASK-DPI-S13-03.md', () {
       final modifiedFiles = ['TASK-DPI-S13-03.md'];
       final allowedScope = <String>[];
       
       final violations = guard.checkScopeLock(
         allowedScope: allowedScope, 
         modifiedFiles: modifiedFiles, 
         basePath: basePath
       );
       
       expect(violations, isEmpty, reason: 'Valid task file should be exempted');
    });

    test('IntegrityEngine: Detect non-Dart orphan (lib/malware.txt)', () async {
       // This test requires a real manifest or a mock check
       // We'll just verify the logic of detectOrphans by creating a temp file
       final tempDir = await Directory.systemTemp.createTemp('integrity_test_');
       final bp = tempDir.path;
       
       try {
         await Directory(p.join(bp, 'lib')).create();
         await File(p.join(bp, 'lib', 'valid.dart')).writeAsString('//');
         await File(p.join(bp, 'lib', 'malware.txt')).writeAsString('EVIL');
         
         // Create mock kernel.hashes containing ONLY valid.dart
         await Directory(p.join(bp, 'vault')).create();
         final hashes = {'lib/valid.dart': 'HASH'};
         await File(p.join(bp, 'vault', 'kernel.hashes')).writeAsString(jsonEncode(hashes));
         
         final orphans = await integrity.detectOrphans(basePath: bp);
         expect(orphans, contains('lib/malware.txt'), reason: 'Non-Dart file should be detected as orphan');
       } finally {
         await tempDir.delete(recursive: true);
       }
    });
  });
}
