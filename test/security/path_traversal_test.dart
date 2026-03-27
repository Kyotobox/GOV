import 'dart:io';
import 'package:test/test.dart';
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';

void main() {
  late ComplianceGuard guard;
  late String basePath;

  setUp(() {
    guard = ComplianceGuard();
    basePath = Directory.current.path;
  });

  group('ComplianceGuard: Path Traversal Protection (VUL-19)', () {
    test('checkScopeLock: Block absolute path outside base', () {
      final modifiedFiles = ['/etc/passwd', 'C:/Windows/System32/cmd.exe'];
      final allowedScope = ['lib/'];
      
      expect(
        () => guard.checkScopeLock(
          allowedScope: allowedScope, 
          modifiedFiles: modifiedFiles, 
          basePath: basePath
        ),
        throwsA(predicate((e) => e.toString().contains('PATH-TRAVERSAL-DETECTED')))
      );
    });

    test('checkScopeLock: Block relative path outside base (../)', () {
      final modifiedFiles = ['../secret.txt'];
      final allowedScope = ['lib/'];
      
      expect(
        () => guard.checkScopeLock(
          allowedScope: allowedScope, 
          modifiedFiles: modifiedFiles, 
          basePath: basePath
        ),
        throwsA(predicate((e) => e.toString().contains('PATH-TRAVERSAL-DETECTED')))
      );
    });

    test('checkScopeLock: Block sneaky relative path (lib/../../secret.txt)', () {
      final modifiedFiles = ['lib/../../secret.txt'];
      final allowedScope = ['lib/'];
      
      expect(
        () => guard.checkScopeLock(
          allowedScope: allowedScope, 
          modifiedFiles: modifiedFiles, 
          basePath: basePath
        ),
        throwsA(predicate((e) => e.toString().contains('PATH-TRAVERSAL-DETECTED')))
      );
    });

    test('checkScopeLock: Allow valid relative path within base', () {
      final modifiedFiles = ['lib/src/security/integrity_engine.dart'];
      final allowedScope = ['lib/'];
      
      final violations = guard.checkScopeLock(
        allowedScope: allowedScope, 
        modifiedFiles: modifiedFiles, 
        basePath: basePath
      );
      
      expect(violations, isEmpty);
    });
  });
}
