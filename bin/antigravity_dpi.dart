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
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:path/path.dart' as p;

const String version = '1.0.0';

void main(List<String> arguments) async {
  final integrityEngine = IntegrityEngine();
  final isSelfIntact = await integrityEngine.verifySelf(
    toolRoot: Directory.current.path,
  );
  if (!isSelfIntact) {
    print('[CRITICAL] SELF-AUDIT FAILED: El código fuente de la herramienta ha sido alterado. Operación abortada.');
    exit(2);
  }

  final parser = ArgParser()
    ..addCommand('act')
    ..addCommand('audit')
    ..addCommand('baseline')
    ..addCommand('handover')
    ..addCommand('takeover')
    ..addCommand('status')
    ..addCommand('vault')
    ..addOption('path', abbr: 'p', help: 'Base path of the project', defaultsTo: Directory.current.path)
    ..addOption('key', abbr: 'k', help: 'Path to the private RSA key XML');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    return;
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

    final backlog = BacklogManager();
    final activeTasks = await backlog.checkConcurrency(basePath: basePath);
    
    if (activeTasks.isNotEmpty) {
      final taskId = activeTasks.first;
      final compliance = ComplianceGuard();
      
      final gitResult = await Process.run('git', ['status', '--porcelain'], workingDirectory: basePath);
      final stdout = gitResult.stdout as String;
      final modifiedFiles = stdout.split('\n')
          .where((l) => l.length >= 3)
          .map((l) => l.substring(3).trim())
          .where((f) => f.isNotEmpty)
          .toList();

      try {
        await compliance.enforcePreBaseline(taskId: taskId, modifiedFiles: modifiedFiles, basePath: basePath);
        print('  [✅] COMPLIANCE-OK: $taskId');

        final ledger = ForensicLedger();
        await ledger.appendEntry(
          sessionId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          type: 'SNAP',
          task: taskId,
          detail: 'Audit successful for $taskId',
          basePath: basePath,
        );
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
  await runAudit(basePath);

  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);

  print('--- [TELEMETRY] PULSE ---');
  print('Saturation: ${pulse.saturation}% | CP: ${pulse.cp}');

  if (pulse.saturation > 90) {
    print('[FATIGUE] Hard-stop: Saturation too high. Run handover.');
  }

  await telemetry.incrementTurns(basePath: basePath);
  await telemetry.persistPulse(pulse, basePath: basePath);

  final backlogManager = BacklogManager();
  final activeTasks = await backlogManager.checkConcurrency(basePath: basePath);
  final ledger = ForensicLedger();
  await ledger.appendEntry(
      sessionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}', 
      type: 'EXEC', 
      task: activeTasks.isNotEmpty ? activeTasks.first : 'S04-GENERAL', 
      detail: 'Pulse: ${pulse.saturation}% sat, ${pulse.cp} CP', 
      basePath: basePath
  );

  print('Pulse PERSISTED.');
}

Future<void> runStatus(String basePath) async {
  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);
  print('Status: ${pulse.saturation}% saturated. ${pulse.cp} complexity points.');
}

Future<void> runHandover(String basePath, String? keyPath) async {
  print('--- [HANDOVER] CIERRE DE SESIÓN ---');
  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  final vanguard = VanguardCore();
  final dashboard = DashboardEngine();

  await runAudit(basePath);

  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
  final pulse = await telemetry.computePulse(basePath: basePath);

  await vanguard.issueChallenge(
    level: 'TACTICAL',
    project: backlog['project'] ?? 'UNKNOWN',
    files: ['session.lock', 'intel_pulse.json'],
    basePath: basePath,
  );

  final signed = await vanguard.waitForSignature(basePath: basePath);
  if (!signed) {
    print('[CRITICAL] Handover abortado: Se requiere firma del PO.');
    return;
  }

  final gitResult = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: basePath);
  final gitHash = (gitResult.stdout as String).trim();

  final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceFirst('T', ' ');
  
  final lockFile = File(p.join(basePath, 'session.lock'));
  await lockFile.writeAsString(jsonEncode({
    'status': 'HANDOVER_SEALED',
    'timestamp': timestamp,
    'shs_at_close': pulse.saturation,
    'git_hash': gitHash,
  }));

  await telemetry.resetCounters(basePath: basePath);

  final ledger = ForensicLedger();
  await ledger.appendEntry(
    sessionId: activeSprint?['id'] ?? 'S04-GENERAL',
    type: 'SNAP',
    task: 'HANDOVER',
    detail: 'Handover completed. SHS: ${pulse.saturation}%. Git: $gitHash',
    basePath: basePath,
  );

  print('Handover COMPLETADO. Sesión SELLADA.');
}

Future<void> runTakeover(String basePath) async {
  print('--- [TAKEOVER] RECUPERACIÓN DE SESIÓN ---');
  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  double inheritedCP = 0.0;
  String? lastHash;
  
  final lockFile = File(p.join(basePath, 'session.lock'));
  if (lockFile.existsSync()) {
    final lock = jsonDecode(await lockFile.readAsString());
    if (lock['status'] != 'HANDOVER_SEALED') {
      print('[CRITICAL] FAIL-SAFE: La sesión previa no fue cerrada correctamente.');
      exit(1);
    }
    inheritedCP = (lock['shs_at_close'] as num?)?.toDouble() ?? 0.0;
    lastHash = lock['git_hash'] as String?;
  }

  // ALIGNMENT: Ensure we are on master to avoid detached HEAD drift
  await Process.run('git', ['checkout', 'master'], workingDirectory: basePath);

  // 2. Verificar Git Hash (HARD-STOP)
  final gitResult = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: basePath);
  final currentHash = (gitResult.stdout as String).trim();
  if (lastHash != null && lastHash != currentHash) {
    print('[CRITICAL] GIT-DRIFT: El hash actual ($currentHash) no coincide con el cierre ($lastHash). Abortando para proteger integridad.');
    exit(1);
  }

  await runAudit(basePath);

  final lockData = jsonEncode({
    'status': 'IN_PROGRESS',
    'timestamp': DateTime.now().toIso8601String(),
    'inherited_fatigue': inheritedCP,
  });
  await lockFile.writeAsString(lockData);

  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);

  // 3. Búsqueda de Tarea Objetivo
  String targetTask = 'S04-GENERAL';
  if (activeSprint != null) {
    final tasks = activeSprint['tasks'] as List?;
    if (tasks != null) {
      final pending = tasks.firstWhere((t) => t['status'] == 'PENDING', orElse: () => null);
      if (pending != null) {
        targetTask = pending['id'];
      }
    }
  }

  // 4. Cálculo de Pulso Real
  final pulse = await telemetry.computePulse(basePath: basePath, carryOverCP: inheritedCP);

  final ledger = ForensicLedger();
  await ledger.appendEntry(
    sessionId: activeSprint?['id'] ?? 'S04-GENERAL',
    type: 'SNAP',
    task: 'TAKEOVER',
    detail: 'Takeover success. Inherited CP: $inheritedCP',
    basePath: basePath,
  );

  // 5. Consola Táctica
  print('\n----------------------------------------');
  print('  [GOV] TAKEOVER EXITOSO');
  print('  Saturación Real: ${pulse.saturation}% (CP: ${pulse.cp})');
  print('  Tarea Objetivo:  $targetTask');
  print('\n[STATUS] Sesión reanudada con persistencia de fatiga heredada.');
  print('----------------------------------------\n');
}

Future<void> runBaseline(String basePath, String? keyPath) async {
  print('--- [BASELINE] SELLADO FORMAL DE KERNEL ---');
  await runAudit(basePath);

  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  final vanguard = VanguardCore();

  final backlog = await backlogManager.loadBacklog(basePath: basePath);
  final activeSprint = await backlogManager.getActiveSprint(backlog: backlog);
  final pulse = await telemetry.computePulse(basePath: basePath);

  if (activeSprint == null) {
    print('[CRITICAL] No se encontró sprint activo.');
    return;
  }

  final gitResult = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: basePath);
  final gitHash = (gitResult.stdout as String).trim();
  final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceFirst('T', ' ');

  final lockFile = File(p.join(basePath, 'session.lock'));
  await lockFile.writeAsString(jsonEncode({
    'status': 'BASELINE_SEALED',
    'timestamp': timestamp,
    'sprint_id': activeSprint['id'],
    'git_hash': gitHash,
  }));

  final ledger = ForensicLedger();
  await ledger.appendEntry(
    sessionId: activeSprint['id'],
    type: 'BASE',
    task: 'BASELINE',
    detail: 'Baseline sealed. Git: $gitHash',
    basePath: basePath,
  );

  print('Baseline COMPLETADO. Sprint ${activeSprint['id']} SELLADO con éxito.');
}
