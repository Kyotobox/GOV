import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';

void main() {
  late ComplianceGuard guard;
  late String tempDir;

  setUp(() async {
    guard = ComplianceGuard();
    tempDir = Directory.systemTemp.createTempSync('compliance_test').path;
  });

  tearDown(() {
    Directory(tempDir).deleteSync(recursive: true);
  });

  group('ComplianceGuard - extractScopeFromMd', () {
    test('successfully extracts scope items from task md', () async {
      final taskFile = File(p.join(tempDir, 'TASK-TEST-01.md'));
      await taskFile.writeAsString('''
# TASK-TEST-01
## Context
Test task.

## Scope
- `lib/src/tasks/compliance_guard.dart`
- `bin/antigravity_dpi.dart`
- `test/`
- `TASK-TEST-01.md`

## Interfaz
''');

      final scope = await guard.extractScopeFromMd(
        taskId: 'TASK-TEST-01',
        basePath: tempDir,
      );

      expect(scope, contains('lib/src/tasks/compliance_guard.dart'));
      expect(scope, contains('bin/antigravity_dpi.dart'));
      expect(scope, contains('test/'));
      expect(scope, contains('TASK-TEST-01.md'));
      expect(scope.length, equals(4));
    });

    test('throws exception if task file missing', () async {
      expect(
        () => guard.extractScopeFromMd(taskId: 'MISSING', basePath: tempDir),
        throwsA(isA<ComplianceException>()),
      );
    });
  });

  group('ComplianceGuard - checkScopeLock', () {
    final allowedScope = [
      'lib/src/tasks/compliance_guard.dart',
      'bin/antigravity_dpi.dart',
      'test/',
      'TASK-TEST-01.md'
    ];

    test('allows files within scope (exact and directory)', () {
      final modified = [
        'lib/src/tasks/compliance_guard.dart',
        'test/compliance_guard_test.dart',
        'TASK-TEST-01.md'
      ];

      final violations = guard.checkScopeLock(
        allowedScope: allowedScope,
        modifiedFiles: modified,
        basePath: tempDir,
      );

      expect(violations, isEmpty);
    });

    test('detects violations outside scope', () {
      final modified = [
        'lib/src/tasks/compliance_guard.dart',
        'lib/src/security/sign_engine.dart', // Violation
        'README.md' // Violation
      ];

      final violations = guard.checkScopeLock(
        allowedScope: allowedScope,
        modifiedFiles: modified,
        basePath: tempDir,
      );

      expect(violations, contains('lib/src/security/sign_engine.dart'));
      expect(violations, contains('README.md'));
      expect(violations.length, equals(2));
    });

    test('handles windows paths correctly', () {
      final modified = [
        r'lib\src\tasks\compliance_guard.dart',
        r'test\some_test.dart'
      ];

      final violations = guard.checkScopeLock(
        allowedScope: allowedScope,
        modifiedFiles: modified,
        basePath: tempDir,
      );

      expect(violations, isEmpty);
    });

    test('prevents path traversal evasion (VUL-B)', () {
      final modified = [
        'lib/src/tasks/../security/sign_engine.dart', // Evasion attempt
      ];

      final violations = guard.checkScopeLock(
        allowedScope: allowedScope,
        modifiedFiles: modified,
        basePath: tempDir,
      );

      // Should be detected because it resolves to lib/src/security/sign_engine.dart
      // which is NOT in allowedScope.
      expect(violations, contains('lib/src/tasks/../security/sign_engine.dart'));
    });
  });

  group('ComplianceGuard - checkReferentialIntegrity', () {
    test('returns true for valid task file', () async {
      final taskFile = File(p.join(tempDir, 'TASK-OK.md'));
      await taskFile.writeAsString('''
# TASK-OK
**CP**: 5
## Scope
- foo.dart
''');

      final result = await guard.checkReferentialIntegrity(
        taskId: 'TASK-OK',
        basePath: tempDir,
      );

      expect(result, isTrue);
    });

    test('returns false for invalid task file missing CP', () async {
      final taskFile = File(p.join(tempDir, 'TASK-BAD.md'));
      await taskFile.writeAsString('''
# TASK-BAD
## Scope
- foo.dart
''');

      final result = await guard.checkReferentialIntegrity(
        taskId: 'TASK-BAD',
        basePath: tempDir,
      );

      expect(result, isFalse);
    });
  });

  group('ComplianceGuard - enforcePreBaseline', () {
    test('passes when all rules are met', () async {
      final taskFile = File(p.join(tempDir, 'TASK-FINAL.md'));
      await taskFile.writeAsString('''
# TASK-FINAL
**CP**: 5
## Scope
- lib/src/tasks/compliance_guard.dart
''');

      await expectLater(
        guard.enforcePreBaseline(
          taskId: 'TASK-FINAL',
          modifiedFiles: ['lib/src/tasks/compliance_guard.dart'],
          basePath: tempDir,
        ),
        completes,
      );
    });

    test('throws when scope is violated', () async {
      final taskFile = File(p.join(tempDir, 'TASK-VIOLATE.md'));
      await taskFile.writeAsString('''
# TASK-VIOLATE
**CP**: 5
## Scope
- lib/src/tasks/compliance_guard.dart
''');

      expect(
        () => guard.enforcePreBaseline(
          taskId: 'TASK-VIOLATE',
          modifiedFiles: ['README.md'],
          basePath: tempDir,
        ),
        throwsA(isA<ComplianceException>().having((e) => e.message, 'message', contains('SCOPE-VIOLATION'))),
      );
    });
  });
}
