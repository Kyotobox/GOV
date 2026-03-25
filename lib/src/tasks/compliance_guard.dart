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

  /// Verifies that modified files match the active task's label scope.
  /// Returns a list of filenames that violate the scope.
  List<String> checkScopeLock({
    required String activeTaskLabel,
    required List<String> modifiedFiles,
  }) {
    final rules = scopeRules[activeTaskLabel.toUpperCase()];
    if (rules == null) return []; // No rules for this label = open scope?

    List<String> violations = [];
    for (final file in modifiedFiles) {
      bool isAllowed = false;
      for (final rule in rules) {
        if (rule.hasMatch(file)) {
          isAllowed = true;
          break;
        }
      }
      if (!isAllowed) {
        violations.add(file);
      }
    }
    return violations;
  }

  /// Verifies referential integrity: TASK-ID.md must exist and be valid.
  Future<bool> checkReferentialIntegrity({
    required String taskId,
    required String basePath,
  }) async {
    final taskFile = File(p.join(basePath, '$taskId.md'));
    if (!await taskFile.exists()) return false;

    final content = await taskFile.readAsString();
    // Simple validation: must contain Scope and CP fields
    return content.contains('Scope:') && content.contains('CP:');
  }

  /// Enforces all compliance rules before allowing a baseline.
  Future<void> enforcePreBaseline({
    required String taskId,
    required String activeTaskLabel,
    required List<String> modifiedFiles,
    required String basePath,
  }) async {
    // 1. Check Scope Lock
    final violations = checkScopeLock(
      activeTaskLabel: activeTaskLabel,
      modifiedFiles: modifiedFiles,
    );
    if (violations.isNotEmpty) {
      throw ComplianceException('SCOPE-VIOLATION: Les siguientes archivos no pertenecen al label $activeTaskLabel: ${violations.join(", ")}');
    }

    // 2. Check Referential Integrity
    final isRefOk = await checkReferentialIntegrity(taskId: taskId, basePath: basePath);
    if (!isRefOk) {
      throw ComplianceException('REFERENTIAL-FAIL: No se encontró un $taskId.md válido en el root.');
    }
  }
}

class ComplianceException implements Exception {
  final String message;
  ComplianceException(this.message);
  @override
  String toString() => 'Compliance Violation: $message';
}
