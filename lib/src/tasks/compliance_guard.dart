import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// ComplianceGuard: Enforces scope-lock and referential task integrity.
class ComplianceGuard {
  // Scope definitions - these can be overridden by gov.yaml
  static Map<String, List<RegExp>> scopeRules = {
    'UI': [RegExp(r'lib/.*\.dart'), RegExp(r'assets/.*')],
    'DATA': [RegExp(r'lib/.*\.dart')],
    'SHELL': [RegExp(r'.*\.ps1'), RegExp(r'.*\.bat'), RegExp(r'pubspec\.yaml')],
    'GOV': [RegExp(r'ops-.*\.ps1'), RegExp(r'.*\.md'), RegExp(r'GEMINI\.md')],
    'SEC': [RegExp(r'lib/src/security/.*'), RegExp(r'vault/.*')],
    'PLAN': [RegExp(r'.*\.md'), RegExp(r'\.meta/.*')],
  };

  ComplianceGuard({String? basePath}) {
    if (basePath != null) {
      _loadDynamicScopes(basePath);
    }
  }

  void _loadDynamicScopes(String basePath) {
    final file = File(p.join(basePath, 'gov.yaml'));
    if (!file.existsSync()) return;

    try {
      final doc = loadYaml(file.readAsStringSync());
      if (doc != null && doc['scopes'] != null) {
        final YamlMap yamlScopes = doc['scopes'];
        final Map<String, List<RegExp>> newRules = {};
        
        yamlScopes.forEach((key, value) {
          if (value is YamlList) {
            final List<RegExp> patterns = [];
            for (var item in value) {
              // Convert glob-like pattern to basic RegExp
              var pattern = item.toString()
                  .replaceAll('.', r'\.')
                  .replaceAll('*', '.*')
                  .replaceAll('?', '.')
                  .replaceAll('/**', '/.*');
              patterns.add(RegExp('^$pattern\$', caseSensitive: false));
            }
            newRules[key.toString()] = patterns;
          }
        });

        if (newRules.isNotEmpty) {
          scopeRules = newRules;
          print('DEBUG-COMPLIANCE: Reglas de Scope cargadas dinámicamente desde gov.yaml');
        }
      }
    } catch (e) {
      print('[WARNING] Error parseando gov.yaml: $e. Usando reglas por defecto.');
    }
  }

  /// Archivos de sistema gestionados por gov.exe que están exentos del Scope-Lock estricto.
  static const List<String> systemExemptions = [
    'session.lock',
    'backlog.json',
    'all_hashes.json', // Diagnóstico de integridad
    'fleet_targets.tmp', // Temporal del orquestador de flota
    'update_self_hashes.dart', // Soporte de recertificación
    'sync_self.dart', // Fixed name
    'final_sync.dart',
    'task.md',
    'DASHBOARD.md',
    'BASELINE.md',
    'TASK-DPI-', // Exempt all task files
    'pubspec.lock',
    'SESSION_RELAY_TECH.md',
    '.log', // Exención para archivos de traza y auditoría
    '.tmp', // Exención para archivos temporales de orquestación
    'vault/', // Toda la telemetría, pulsos y logs
    'HISTORY.md',
    'bin/', // Exención para binarios de la herramienta
    'lib/', // Exención para código fuente de la herramienta (Self-Audit)
    'test/', // Exención para pruebas unitarias
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
        var clean = line
            .trim()
            .substring(2)
            .replaceAll('`', '')
            .replaceAll('file:///', '')
            .replaceAll('\\', '/');
        
        // Strip trailing annotations (e.g., " (Nuevo)")
        if (clean.contains(' ')) {
          clean = clean.split(' ').first.trim();
        }

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
    required String basePath,
  }) {
    final violations = <String>[];
    for (final file in modifiedFiles) {
      // Normalización robusta para evitar Path Traversal (VUL-19)
      final absBase = p.canonicalize(basePath);
      final absFile = p.canonicalize(p.join(absBase, file));
      
      if (!p.isWithin(absBase, absFile) && absFile != absBase) {
        throw ComplianceException('PATH-TRAVERSAL-DETECTED: Intento de acceder a archivo fuera de la base: $file');
      }

      String cleanFile = p.relative(absFile, from: absBase).replaceAll('\\', '/');
      print('DEBUG: file=$file | cleanFile=$cleanFile');

      final cleanFileLower = cleanFile.toLowerCase();

      // 1. Verificar Exenciones del Sistema
      bool isExempt = false;
      for (final exempt in systemExemptions) {
        final normalizedExempt = exempt.replaceAll('\\', '/').toLowerCase();
        
        if (normalizedExempt.endsWith('/')) {
          // Exención de directorio: debe coincidir con el prefijo incluyendo el separador
          if (cleanFileLower.startsWith(normalizedExempt)) {
            // Permitir exenciones globales excepto para el núcleo (lib/bin) que requiere scope explícito
            if (!cleanFileLower.startsWith('lib/') && !cleanFileLower.startsWith('bin/')) {
              isExempt = true;
              break;
            }
          }
        } else if (normalizedExempt == 'task-dpi-') {
          // VUL-09: Exención estricta para archivos de tarea .md
          if (RegExp(r'^task-dpi-.*\.md$').hasMatch(cleanFileLower)) {
            isExempt = true;
            break;
          }
        } else if (normalizedExempt.startsWith('.')) {
          // Exención por extensión
          if (cleanFileLower.endsWith(normalizedExempt)) {
            isExempt = true;
            break;
          }
        } else if (cleanFileLower == normalizedExempt) {
          // Coincidencia exacta
          isExempt = true;
          break;
        }
      }
      
      // Casos específicos de archivos de sistema que siempre son exentos
      if (cleanFileLower == 'session.lock' || 
          cleanFileLower == 'task.md' || 
          cleanFileLower.startsWith('vault/')) {
        isExempt = true;
      }

      if (isExempt) continue;

      bool isAllowed = false;
      for (var pattern in allowedScope) {
        final normalizedPattern = pattern.replaceAll('\\', '/').toLowerCase();
        
        if (normalizedPattern.endsWith('/')) {
          if (cleanFileLower.startsWith(normalizedPattern)) {
            isAllowed = true;
            break;
          }
        } else {
          if (cleanFileLower == normalizedPattern ||
              cleanFileLower.startsWith(normalizedPattern + '/')) {
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
      basePath: basePath,
    );

    if (violations.isNotEmpty) {
      throw ComplianceException(
        'SCOPE-VIOLATION: Intento de modificar archivos fuera del scope de $taskId: ${violations.join(", ")}',
      );
    }

    // 4. Role-Based Verification from gov.yaml
    // For simplicity in this DPI, we assume roles are mapped by Sprint ID or extracted from task metadata.
    // If the task content has "[ARCH]" or "[SEC]", we apply those rules globally.
    final taskContent = await File(p.join(basePath, '$taskId.md')).readAsString();
    String? role;
    if (taskContent.contains('[ARCH]')) role = 'ARCH';
    else if (taskContent.contains('[SEC]')) role = 'SEC';
    else if (taskContent.contains('[UI]')) role = 'UI';
    else if (taskContent.contains('[GOV]')) role = 'GOV';

    if (role != null && scopeRules.containsKey(role)) {
      final roleRules = scopeRules[role]!;
      for (final file in modifiedFiles) {
        final cleanFile = p.relative(p.canonicalize(p.join(basePath, file)), from: p.canonicalize(basePath)).replaceAll('\\', '/');
        
        bool allowedByRole = false;
        for (final regex in roleRules) {
          if (regex.hasMatch(cleanFile)) {
            allowedByRole = true;
            break;
          }
        }

        // System exemptions still apply
        bool isExempt = false;
        for (final exempt in systemExemptions) {
           if (cleanFile.toLowerCase().contains(exempt.toLowerCase())) {
             isExempt = true; break;
           }
        }

        if (!allowedByRole && !isExempt) {
          throw ComplianceException(
            'ROLE-VIOLATION: El archivo $file no pertenece al scope dinámico del rol $role definido en gov.yaml',
          );
        }
      }
      print('DEBUG-COMPLIANCE: Dinamic Role Scope Verified for $role');
    }
  }
}

class ComplianceException implements Exception {
  final String message;
  ComplianceException(this.message);
  @override
  String toString() => 'Compliance Violation: $message';
}
