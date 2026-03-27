import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/tasks/backlog_manager.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';

/// Engine to install and manage Git Hooks for governance enforcement.
class HookEngine {
  Future<void> installHooks({required String basePath}) async {
    final gitHooksDir = Directory(p.join(basePath, '.git', 'hooks'));
    final ledger = ForensicLedger();
    final backlogManager = BacklogManager();

    if (!await gitHooksDir.exists()) {
      print('[ERROR] Directorio .git/hooks no encontrado. ¿Es un repositorio Git?');
      return;
    }

    print('--- [HOOKS] INSTALANDO GANCHOS NATIVOS ---');

    final hooks = ['pre-commit', 'pre-push'];
    final hookContent = '''#!/bin/sh
# [GOV] GANCHO DE GOBERNANZA AUTOMÁTICO
dart run bin/antigravity_dpi.dart audit
if [ \$? -ne 0 ]; then
  echo ""
  echo "--- [‼️] AUDITORÍA DE GOBERNANZA FALLIDA ---"
  echo "Operación de Git abortada por incumplimiento o violación de integridad."
  echo "Ejecute 'gov audit' para más detalles."
  echo "--------------------------------------------"
  exit 1
fi
''';

    for (var hookName in hooks) {
      final hookFile = File(p.join(gitHooksDir.path, hookName));
      await hookFile.writeAsString(hookContent);
      
      // En Unix/Linux/macOS necesitaríamos chmod +x. 
      // En Windows, Git Bash lo maneja, pero intentamos ser preventivos si es posible.
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', hookFile.path]);
      }
      
      print('  [✅] Instalado: $hookName');
    }

    // Registro en Historia
    final backlog = await backlogManager.loadBacklog(basePath: basePath);
    final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
    
    await ledger.appendEntry(
      sessionId: activeSprint?['id'] ?? 'S04-GENERAL',
      type: 'SNAP',
      task: 'HOOKS',
      detail: 'Git Hooks (pre-commit, pre-push) instalados exitosamente.',
      basePath: basePath,
    );

    print('\n[✅] Ganchos instalados. La gobernanza ahora es INESCAPABLE.');
  }
}
