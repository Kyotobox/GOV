import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/tasks/backlog_manager.dart';
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';

/// Engine to aggregate source code and governance files for AI context.
class ContextEngine {
  Future<void> generateContext({required String basePath}) async {
    final backlogManager = BacklogManager();
    final compliance = ComplianceGuard();
    final ledger = ForensicLedger();

    print('--- [CONTEXT] GENERANDO FOCO PARA IA ---');

    // 1. Identificar Tarea Activa
    final backlog = await backlogManager.loadBacklog(basePath: basePath);
    final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
    
    if (activeSprint == null) {
      print('[ERROR] No hay sprint activo para determinar el scope.');
      return;
    }

    final List? tasks = activeSprint['tasks'] as List?;
    dynamic activeTask;
    
    if (tasks != null) {
      activeTask = tasks.firstWhere(
        (t) => t['status'] == 'IN_PROGRESS', 
        orElse: () => tasks.firstWhere((t) => t['status'] == 'PENDING', orElse: () => null)
      );
    }

    if (activeTask == null) {
      print('[WARNING] No se encontró tarea activa/pendiente. Usando scope general.');
    }

    final String taskId = activeTask?['id'] ?? 'S04-GENERAL';
    print('[INFO] Tarea detectada: $taskId');

    // 2. Extraer Scope
    List<String> scopedFiles = [];
    try {
      scopedFiles = await compliance.extractScopeFromMd(taskId: taskId, basePath: basePath);
    } catch (e) {
      print('[WARNING] Fallo al extraer scope de $taskId.md: $e');
    }

    // 3. Agregar archivos CORE obligatorios
    final mandatory = ['DASHBOARD.md', 'GEMINI.md', 'VISION.md'];
    final allFiles = {...scopedFiles, ...mandatory}.toList();

    // 4. Agregación de Contenido
    final outputFile = File(p.join(basePath, 'vault', 'ai_context.txt'));
    final buffer = StringBuffer();
    buffer.writeln('=== AI CONTEXT GENERATED: ${DateTime.now()} ===');
    buffer.writeln('TASK_ID: $taskId');
    buffer.writeln('================================================\n');

    for (var filePath in allFiles) {
      final file = File(p.join(basePath, filePath));
      if (await file.exists()) {
        final content = await file.readAsString();
        buffer.writeln('FILE: $filePath');
        buffer.writeln('--- CONTENT START ---');
        buffer.writeln(content);
        buffer.writeln('--- CONTENT END ---\n');
        print('  [+] Incluido: $filePath');
      } else {
        print('  [!] Omitido (No existe): $filePath');
      }
    }

    await outputFile.writeAsString(buffer.toString());

    // 5. Registro en Historia
    await ledger.appendEntry(
      sessionId: activeSprint['id'],
      type: 'SNAP',
      task: taskId,
      detail: 'CONTEXT: vault/ai_context.txt generado para $taskId',
      basePath: basePath,
    );

    print('\n[✅] Contexto exportado exitosamente a: ${outputFile.path}');
  }
}
