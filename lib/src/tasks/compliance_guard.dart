import 'dart:io';
import 'package:path/path.dart' as p;

/// ComplianceGuard: Enforces scope-lock and referential task integrity.
class ComplianceGuard {
  // Scope definitions migrated from Base2/ops-audit.ps1
  static final Map<String, List<RegExp>> scopeRules = {
    'UI': [RegExp(r'lib/.*\.dart'), RegExp(r'assets/.*')],
    'DATA': [RegExp(r'lib/.*\.dart')],
    'SHELL': [RegExp(r'.*\.ps1'), RegExp(r'.*\.bat'), RegExp(r'pubspec\.yaml')],
    'GOV': [RegExp(r'ops-.*\.ps1'), RegExp(r'.*\.md'), RegExp(r'GEMINI\.md')],
    'SEC': [RegExp(r'lib/src/security/.*'), RegExp(r'vault/.*')],
    'PLAN': [RegExp(r'.*\.md'), RegExp(r'\.meta/.*')],
  };

  /// Archivos de sistema gestionados por gov.exe que están exentos del Scope-Lock estricto.
  static const List<String> systemExemptions = [
    'session.lock',
    'backlog.json',
    'task.md',
    'DASHBOARD.md',
    'BASELINE.md',
    'vault/self.hashes',
    'vault/intel/', // Toda la telemetría y pulsos
    'HISTORY.md',
  ];

  /// Extracts the allowed files/patterns from the "## Scope:" section of a TASK-ID.md.
  Future<List<String>> extractScopeFromMd({
    required String taskId,
    required String basePath,
  }) async {
    final taskFile = File(p.join(basePath, '$taskId.md'));
    if (!await taskFile.exists()) {
      throw ComplianceException('TASK-NOT-FOUND: $taskId.md no existe.');
    }

    final lines = await taskFile.readAsLines();
    bool inScopeSection = false;
    List<String> allowedPatterns = [];

    for (var line in lines) {
      if (line.trim().startsWith('## Scope')) {
        inScopeSection = true;
        continue;
      }
      if (inScopeSection && line.trim().startsWith('## ')) {
        break; // End of section
      }
      if (inScopeSection && line.trim().startsWith('- ')) {
        // Extract and normalize
        final clean = line
            .trim()
            .substring(2)
            .replaceAll('`', '')
            .replaceAll('file:///', '')
            .replaceAll('\\', '/');
        if (clean.isNotEmpty) {
          allowedPatterns.add(clean);
        }
      }
    }
    return allowedPatterns;
  }

  /// Verifies that modified files match the active task's strict scope.
  List<String> checkScopeLock({
    required List<String> allowedScope,
    required List<String> modifiedFiles,
  }) {
    final violations = <String>[];
    for (final file in modifiedFiles) {
      final normalizedFile = file.replaceAll('\\', '/');

      // 1. Verificar Exenciones del Sistema
      bool isExempt = false;
      for (final exempt in systemExemptions) {
        if (exempt.endsWith('/') && normalizedFile.startsWith(exempt)) {
          isExempt = true;
          break;
        } else if (normalizedFile == exempt) {
          isExempt = true;
          break;
        }
      }
      if (isExempt) continue;

      bool isAllowed = false;
      for (var pattern in allowedScope) {
        pattern = pattern.replaceAll('\\', '/');
        // If pattern ends with /, it's a directory
        if (pattern.endsWith('/')) {
          if (normalizedFile.startsWith(pattern)) {
            isAllowed = true;
            break;
          }
        } else {
          // Exact match or directory prefix match
          if (normalizedFile == pattern ||
              normalizedFile.startsWith(pattern + '/')) {
            isAllowed = true;
            break;
          }
        }
      }
      if (!isAllowed) {
        violations.add(file);
      }
    }
    return violations;
  }

  /// Verifies referential integrity: TASK-ID.md must exist and have Scope/CP.
  Future<bool> checkReferentialIntegrity({
    required String taskId,
    required String basePath,
  }) async {
    final taskFile = File(p.join(basePath, '$taskId.md'));
    if (!await taskFile.exists()) return false;

    final content = await taskFile.readAsString();
    final hasScope = content.contains(
      RegExp(r'^## Scope|^Scope:', multiLine: true),
    );
    final hasCp = content.contains(
      RegExp(r'^\*\*CP\*\*:\s*\d+|^CP:\s*\d+', multiLine: true),
    );
    return hasScope && hasCp;
  }

  /// Enforces all compliance rules before allowing an operation.
  Future<void> enforcePreBaseline({
    required String taskId,
    required List<String> modifiedFiles,
    required String basePath,
  }) async {
    // 1. Referential Integrity First
    final isRefOk = await checkReferentialIntegrity(
      taskId: taskId,
      basePath: basePath,
    );
    if (!isRefOk) {
      throw ComplianceException(
        'REFERENTIAL-FAIL: $taskId.md es inválido o no existe.',
      );
    }

    // 2. Extract Dynamic Scope
    final allowedScope = await extractScopeFromMd(
      taskId: taskId,
      basePath: basePath,
    );
    if (allowedScope.isEmpty) {
      print(
        '[WARNING] Scope vacío detectado en $taskId.md. Bloqueo preventivo activado.',
      );
    }

    // 3. Check Scope Lock
    final violations = checkScopeLock(
      allowedScope: allowedScope,
      modifiedFiles: modifiedFiles,
    );

    if (violations.isNotEmpty) {
      throw ComplianceException(
        'SCOPE-VIOLATION: Intento de modificar archivos fuera del scope de $taskId: ${violations.join(", ")}',
      );
    }
  }
}

class ComplianceException implements Exception {
  final String message;
  ComplianceException(this.message);
  @override
  String toString() => 'Compliance Violation: $message';
}
