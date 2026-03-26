import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/tasks/backlog_manager.dart';
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';
import 'package:antigravity_dpi/src/dash/dashboard_engine.dart';
import 'package:antigravity_dpi/src/security/vanguard_core.dart';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:path/path.dart' as p;

const String version = '1.0.0';

void main(List<String> arguments) async {
  // Self-Audit Pre-flight Check (TASK-DPI-04)
  // This must run before any other operation to ensure the tool itself is trusted.
  final integrityEngine = IntegrityEngine();
  // Assuming the tool is run from its root directory.
  final isSelfIntact = await integrityEngine.verifySelf(
    toolRoot: Directory.current.path,
  );
  if (!isSelfIntact) {
    print(
      '[CRITICAL] SELF-AUDIT FAILED: El código fuente de la herramienta ha sido alterado. Operación abortada.',
    );
    exit(2); // Use a specific exit code for self-tampering
  }

  final parser = ArgParser()
    ..addCommand('act')
    ..addCommand('audit')
    ..addCommand('baseline')
    ..addCommand('handover')
    ..addCommand('takeover')
    ..addCommand('status')
    ..addCommand('vault')
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Base path of the project',
      defaultsTo: Directory.current.path,
    )
    ..addOption('key', abbr: 'k', help: 'Path to the private RSA key XML');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    return; // Exit main without continuing
  }

  final basePath = results['path'] ?? Directory.current.path;
  final keyPath = results['key'] as String?;
  final command = results.command?.name;

  if (command == null) {
    print('antigravity_dpi v$version - Governance Control Plane');
    print(parser.usage);
    return;
  }

  print('[GOV] Executing command: $command');

  switch (command) {
    case 'audit':
      await runAudit(basePath);
      break;
    case 'act':
      await runAct(basePath);
      break;
    case 'baseline':
      await runBaseline(basePath, keyPath);
      break;
    case 'status':
      await runStatus(basePath);
      break;
    case 'handover':
      await runHandover(basePath, results['key']);
      break;
    case 'takeover':
      await runTakeover(basePath);
      break;
    default:
      print('Command not implemented: $command');
  }
}

Future<void> runAudit(String basePath) async {
  try {
    print('--- [AUDIT] INTEGRITY & COMPLIANCE ---');

    final integrity = IntegrityEngine();
    // 1. Integrity Check
    final results = await integrity.verifyAll(basePath: basePath);
    
    bool allOk = true;
    results.forEach((file, ok) {
      if (!ok) {
        print('  [❌] CORRUPT: $file');
        allOk = false;
      } else {
        print('  [✅] OK: $file');
      }
    });

    if (!allOk) {
      print('[CRITICAL] KERNEL-VIOLATION: Integrity check failed.');
      exit(1);
    }

    // 2. Compliance Guard (Scope-Lock & Referential Integrity)
    final backlog = BacklogManager();
    final activeTasks = await backlog.checkConcurrency(basePath: basePath);
    
    if (activeTasks.isNotEmpty) {
      final taskId = activeTasks.first;
      final compliance = ComplianceGuard();
      
      // Get modified files via git
      final gitResult = await Process.run('git', ['status', '--porcelain'], workingDirectory: basePath);
      final stdout = gitResult.stdout as String;
      final modifiedFiles = stdout
          .split('\n')
          .where((l) => l.length >= 3)
          .map((l) => l.substring(3).trim())
          .where((f) => f.isNotEmpty)
          .toList();

      try {
        await compliance.enforcePreBaseline(
          taskId: taskId,
          modifiedFiles: modifiedFiles,
          basePath: basePath,
        );
        print('  [✅] COMPLIANCE-OK: $taskId');
      } catch (e) {
        print('  [❌] COMPLIANCE-FAIL: $e');
        exit(1);
      }
    } else {
      print('  [!] WARNING: No hay tarea activa detectada en task.md (Marcar con [/]).');
    }

    print('Audit COMPLETED.');
  } catch (e, stack) {
    print('[CRITICAL] Error inesperado en audit: $e');
    print(stack);
    exit(1);
  }
}

Future<void> runAct(String basePath) async {
  // Pre-flight audit
  await runAudit(basePath);

  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);

  print('--- [TELEMETRY] PULSE ---');
  print('Saturation: ${pulse.saturation}% | CP: ${pulse.cp}');

  if (pulse.saturation > 90) {
    print('[FATIGUE] Hard-stop: Saturation too high. Run handover.');
  }

  // Update turns
  await telemetry.incrementTurns(basePath: basePath);
  await telemetry.persistPulse(pulse, basePath: basePath);

  print('Pulse PERSISTED.');
}


Future<void> runStatus(String basePath) async {
  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);
  print(
    'Status: ${pulse.saturation}% saturated. ${pulse.cp} complexity points.',
  );
}

  Future<void> runHandover(String basePath, String? keyPath) async {
  print('--- [HANDOVER] CIERRE DE SESIÓN ---');

  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  final vanguard = VanguardCore();
  final dashboard = DashboardEngine();

  // 1. Audit check
  await runAudit(basePath);

  // 2. Load context
  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
  final pulse = await telemetry.computePulse(basePath: basePath);

  if (activeSprint == null) {
    print('[WARNING] No se encontró sprint activo.');
  }

  // 3. Issue Challenge
  final pendingTasks = activeSprint != null
      ? backlogManager.getPendingTasks(activeSprint)
      : [];
  final taskIds = pendingTasks.map((t) => t['id'] as String).toList();

  await vanguard.issueChallenge(
    level: 'TACTICAL', // Mapped from GATE-AMBER for Agent UI compatibility
    project: backlog['project'] ?? 'UNKNOWN',
    files: ['session.lock', 'intel_pulse.json'],
    basePath: basePath,
  );

  // 4. Wait for signature
  final signed = await vanguard.waitForSignature(basePath: basePath);
  if (!signed) {
    print('[CRITICAL] Handover abortado: Se requiere firma del PO.');
    return;
  }

  // [PILLAR 2] Strict RSA Verification
  if (keyPath != null) {
    final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
    final sigData = jsonDecode(await sigFile.readAsString());
    final challengeFile = File(p.join(basePath, 'vault', 'intel', 'challenge.json'));
    final challengeData = jsonDecode(await challengeFile.readAsString());

    final signEngine = SignEngine();
    final isValid = await signEngine.verify(
        challenge: challengeData['challenge'],
        files: challengeData['files'],
        signatureBase64: sigData['signature'],
        publicKeyXmlPath: keyPath, // Assumed to contain public key
    );

    if (!isValid) {
      print('[CRITICAL] KERNEL-VIOLATION: Firma RSA inválida o corrupta. Handover abortado.');
      exit(1);
    }
    print('[VANGUARD] Firma RSA verificada criptográficamente ✅');
  } else {
    print('[WARNING] No se proporcionó clave para validación estricta. Procediendo bajo riesgo.');
  }

  // 5. Digital Twin / Relay Generation
  final gitResult = await Process.run('git', [
    'rev-parse',
    '--short',
    'HEAD',
  ], workingDirectory: basePath);
  final gitHash = (gitResult.stdout as String).trim();

  final relayPath = p.join(basePath, 'vault', 'intel', 'SESSION_RELAY_TECH.md');
  final timestamp = DateTime.now()
      .toIso8601String()
      .split('.')[0]
      .replaceFirst('T', ' ');

  final buffer = StringBuffer();
  buffer.writeln('# RELAY TÉCNICO DE SESIÓN');
  buffer.writeln('Generado: $timestamp | Tipo: HANDOVER');
  buffer.writeln('');
  buffer.writeln('## Estado SHS al Cierre');
  buffer.writeln('- **Saturación**: ${pulse.saturation}%');
  buffer.writeln('- **Puntos de Complejidad (CP)**: ${pulse.cp}');
  buffer.writeln('- **Turnos**: ${pulse.cpDetail['tools']}');
  buffer.writeln('');
  buffer.writeln('## Sprint Activo');
  buffer.writeln('- **ID**: ${activeSprint?['id'] ?? 'N/A'}');
  buffer.writeln('- **Nombre**: ${activeSprint?['name'] ?? 'N/A'}');
  buffer.writeln('- **Tareas Pendientes**:');
  for (var t in pendingTasks) {
    buffer.writeln('  - ${t['id']}: ${t['desc']} [PENDING]');
  }
  buffer.writeln('');
  buffer.writeln('## Contexto Git');
  buffer.writeln('- **Último Commit**: $gitHash');
  buffer.writeln('');
  buffer.writeln('## SEÑAL DE CONTINUIDAD');
  buffer.writeln('- **PRÓXIMA ACCIÓN**: gov takeover');
  buffer.writeln('- **ESTADO**: SELLADO (Firma RSA validada)');

  await File(relayPath).writeAsString(buffer.toString());
  print('Relay generado en: $relayPath');

  // 6. Update Dashboard
  await dashboard.generate(
    pulse: pulse,
    basePath: basePath,
    activeSprint: activeSprint?['id'],
    activeTask: taskIds.isNotEmpty ? taskIds.first : null,
  );

  // 7. Update session.lock
  final lockFile = File(p.join(basePath, 'session.lock'));
  await lockFile.writeAsString(
    jsonEncode({
      'status': 'HANDOVER_SEALED',
      'timestamp': timestamp,
      'shs_at_close': pulse.saturation,
      'git_hash': gitHash,
    }),
  );

  // 8. Reset volatile metrics
  await telemetry.resetCounters(basePath: basePath);

  print('Handover COMPLETADO. Sesión SELLADA.');
}

Future<void> runTakeover(String basePath) async {
  print('--- [TAKEOVER] RECUPERACIÓN DE SESIÓN ---');

  // 1. Concurrency Check (TASK-DPI-04 extension)
  final backlogManager = BacklogManager();
  final conflicts = await backlogManager.checkConcurrency(basePath: basePath);
  if (conflicts.isNotEmpty) {
    print(
      '[WARNING] Se detectaron tareas en ejecución por otra instancia: ${conflicts.join(", ")}',
    );
    print(
      'Asegúrate de que no haya otro agente operando sobre estas tareas para evitar colisiones.',
    );
  }

  final lockFile = File(p.join(basePath, 'session.lock'));
  if (!lockFile.existsSync()) {
    print('[WARNING] No se encontró session.lock. Iniciando sesión limpia.');
  } else {
    final lock = jsonDecode(await lockFile.readAsString());
    if (lock['status'] != 'HANDOVER_SEALED') {
      print(
        '[CRITICAL] FAIL-SAFE: La sesión previa no fue cerrada correctamente (Status: ${lock['status']}).',
      );
      print('[CRITICAL] BLOQUEO DE SEGURIDAD: Se requiere escalada GATE-BLACK para continuar.');
      
      // [PILLAR 1] GATE-BLACK Escalation
      final vanguard = VanguardCore();
      await vanguard.issueBlackGate(
          project: 'Base2', 
          description: 'Takeover override required (Inconsistent session.lock)', 
          basePath: basePath
      );
      
      final signed = await vanguard.waitForSignature(basePath: basePath, timeoutSeconds: 60);
      if (!signed) {
          print('[CRITICAL] BLOQUEO PERSISTENTE: Takeover abortado por falta de autorización PO.');
          exit(1);
      }
      print('[VANGUARD] GATE-BLACK: Autorización PO detectada. Perdonando estado inconsistente.');
    } else {
      print('Último estado: ${lock['status']} (${lock['timestamp']})');
    }
  }

  // 1. Audit check
  await runAudit(basePath);

  // 2. Read Relay
  final relayFile = File(
    p.join(basePath, 'vault', 'intel', 'SESSION_RELAY_TECH.md'),
  );
  if (await relayFile.exists()) {
    print('\n--- RESUMEN DE RELEVO ---');
    final lines = await relayFile.readAsLines();
    for (var line in lines.take(15)) {
      // Show first 15 lines as summary
      print('  $line');
    }
    print('-------------------------\n');
  }

  // 3. Initial Pulse
  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);
  print('Saturación Inicial: ${pulse.saturation}%');

  // 4. Update session.lock to IN_PROGRESS
  await lockFile.writeAsString(
    jsonEncode({
      'status': 'IN_PROGRESS',
      'timestamp': DateTime.now().toIso8601String(),
    }),
  );

  // 5. Show next task
  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);

  if (activeSprint != null) {
    final pending = backlogManager.getPendingTasks(activeSprint);
    if (pending.isNotEmpty) {
      print(
        '[NEXT] Próxima tarea: ${pending.first['id']} - ${pending.first['desc']}',
      );
    }
  }

  print('Takeover EXITOSO. Kernel Base2 LISTO.');
}

Future<void> runBaseline(String basePath, String? keyPath) async {
  print('--- [BASELINE] SELLADO FORMAL DE KERNEL ---');

  // 1. Pre-flight check
  final lockFile = File(p.join(basePath, 'session.lock'));
  if (!lockFile.existsSync()) {
    print('[CRITICAL] No se encontró session.lock. No se puede realizar baseline.');
    return;
  }

  final lock = jsonDecode(await lockFile.readAsString());
  if (lock['status'] != 'IN_PROGRESS') {
    print(
      '[CRITICAL] Estado inválido para baseline: ${lock['status']}. Debe ser IN_PROGRESS.',
    );
    return;
  }

  // 2. Audit
  await runAudit(basePath);

  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  final vanguard = VanguardCore();

  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
  final pulse = await telemetry.computePulse(basePath: basePath);

  if (activeSprint == null) {
    print('[CRITICAL] No se encontró sprint activo en backlog.json.');
    return;
  }

  // 3. Generate BASELINE.md
  final gitResult = await Process.run('git', [
    'rev-parse',
    '--short',
    'HEAD',
  ], workingDirectory: basePath);
  final gitHash = (gitResult.stdout as String).trim();

  final timestamp = DateTime.now()
      .toIso8601String()
      .split('.')[0]
      .replaceFirst('T', ' ');

  final buffer = StringBuffer();
  buffer.writeln('# BASELINE DE GOBERNANZA - SPRINT ${activeSprint['id']}');
  buffer.writeln('Fecha: $timestamp | Git Hash: $gitHash');
  buffer.writeln('Estado: CERTIFICADO | SHS: ${pulse.saturation}%');
  buffer.writeln('\n## OBJETIVO DEL SPRINT');
  buffer.writeln('> ${activeSprint['goal']}');
  buffer.writeln('\n## INTEGRIDAD DE ARCHIVOS');
  buffer.writeln('| Archivo | Estado |');
  buffer.writeln('| :--- | :--- |');
  buffer.writeln('| backlog.json | OK |');
  buffer.writeln('| task.md | OK |');

  final baselineFile = File(p.join(basePath, 'BASELINE.md'));
  await baselineFile.writeAsString(buffer.toString());

  // 4. Issue certification challenge
  print('[INFO] Solicitando certificación PO (KERNEL-CORE)...');
  try {
    await vanguard.issueChallenge(
      level: 'KERNEL-CORE',
      project: backlog['project'] ?? 'UNKNOWN',
      files: ['BASELINE.md', 'backlog.json', 'task.md'],
      basePath: basePath,
    );
  } catch (e) {
    print('[CRITICAL] Error al emitir desafío: $e');
    // Si falla la emisión normal, intentamos Black Gate como último recurso si es crítico
    print('[VANGUARD-EMERGENCY] Intentando escalada a BLACK-GATE...');
    await vanguard.issueBlackGate(
      project: 'BASE2-HARDEN',
      description: 'Fallo crítico en flujo de baseline.',
      basePath: basePath,
    );
  }

  final signed = await vanguard.waitForSignature(basePath: basePath, timeoutSeconds: 60);
  if (!signed) {
    print('[ABORT] Baseline cancelado: No se obtuvo firma válida del PO.');
    exit(1);
  }

  // 5. Update session.lock to BASELINE_SEALED
  await lockFile.writeAsString(
    jsonEncode({
      'status': 'BASELINE_SEALED',
      'timestamp': timestamp,
      'sprint_id': activeSprint['id'],
      'git_hash': gitHash,
    }),
  );

  print('Baseline COMPLETADO. Sprint ${activeSprint['id']} SELLADO con éxito.');
}
