import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/tasks/backlog_manager.dart';
import 'package:antigravity_dpi/src/tasks/compliance_guard.dart';
import 'package:antigravity_dpi/src/dash/dashboard_engine.dart';
import 'package:antigravity_dpi/src/security/vanguard_core.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/core/pack_engine.dart';
import 'package:antigravity_dpi/src/core/context_engine.dart';
import 'package:antigravity_dpi/src/core/hook_engine.dart';
import 'package:antigravity_dpi/src/core/test_engine.dart';
import 'package:antigravity_dpi/src/core/reconstitution_engine.dart';
import 'package:antigravity_dpi/src/core/report_engine.dart';
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

  // TASK-S16-03: Anti-Loop (CLI Rate Limiting)
  final rateFile = File(p.join(Directory.current.path, 'vault', '.gov_rate'));
  final now = DateTime.now().millisecondsSinceEpoch;
  List<int> timestamps = [];
  if (await rateFile.exists()) {
    try {
      timestamps = (jsonDecode(await rateFile.readAsString()) as List).cast<int>();
    } catch (_) {}
  }
  
  // Filter timestamps within the last 15 seconds
  timestamps = timestamps.where((t) => now - t < 15000).toList();
  if (timestamps.length >= 3) {
    print('[CRITICAL] ANTI-LOOP ACTIVATED: Demasiadas solicitudes en poco tiempo. Abortando.');
    final ledger = ForensicLedger();
    await ledger.appendEntry(
      sessionId: 'GATE-RED',
      type: 'ALERT',
      task: 'ANTI-LOOP',
      detail: 'Rate limiting triggered: 3+ calls in 15s.',
      basePath: Directory.current.path,
    );
    exit(1);
  }
  timestamps.add(now);
  if (!await rateFile.parent.exists()) await rateFile.parent.create(recursive: true);
  await rateFile.writeAsString(jsonEncode(timestamps));

  final parser = ArgParser()
    ..addCommand('act', ArgParser()
      ..addFlag('dry-run', negatable: false, help: 'Executes audit but does not persist pulse or history'))
    ..addCommand('audit')
    ..addCommand('baseline')
    ..addCommand('handover', ArgParser()
      ..addFlag('force', negatable: false, help: 'Force handover even if session is expired or invalid'))
    ..addCommand('takeover')
    ..addCommand('status')
    ..addCommand('context')
    ..addCommand('hook', ArgParser()
      ..addCommand('install'))
    ..addCommand('vault', ArgParser()
      ..addCommand('bind-key', ArgParser()
        ..addOption('project', abbr: 'p', help: 'Project ID')
        ..addOption('key', abbr: 'k', help: 'Path to RSA XML Key'))
      ..addCommand('status'))
    ..addCommand('pack')
    ..addCommand('report')
    ..addOption('path', abbr: 'p', help: 'Base path of the project', defaultsTo: Directory.current.path)
    ..addOption('key', abbr: 'k', help: 'Path to the private RSA key XML');

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Error: ${e.toString()}');
    return;
  }

  var basePath = (results['path'] ?? Directory.current.path) as String;
  basePath = basePath.replaceAll('"', '').trim();
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
      final ok = await runAudit(basePath);
      if (!ok) exit(1);
      break;
    case 'act':
      final dryRun = results.command!['dry-run'] as bool;
      await runAct(basePath, dryRun: dryRun);
      break;
    case 'baseline':
      await runBaseline(basePath, keyPath);
      break;
    case 'status':
      await runStatus(basePath);
      break;
    case 'context':
      await runContext(basePath);
      break;
    case 'hook':
      await runHook(basePath, results.command!);
      break;
    case 'pack':
      await runPack(basePath);
      break;
    case 'report':
      await runReport(basePath);
      break;
    case 'vault':
      await runVault(basePath, results.command!);
      break;
    case 'handover':
      final force = results.command!['force'] as bool;
      await runHandover(basePath, keyPath, force: force);
      break;
    case 'takeover':
      await runTakeover(basePath);
      break;
    default:
      print('Command not implemented: $command');
  }
}

Future<bool> runAudit(String basePath, {bool skipSignatureCheck = false}) async {
  print('--- [AUDIT] INICIANDO ESCANEO DE INTEGRIDAD ---');
  
  // TASK-S16-02: Kill-Switch (Zombie Sessions)
  final lockFile = File(p.join(basePath, 'session.lock'));
  if (await lockFile.exists()) {
    try {
      final lockData = jsonDecode(await lockFile.readAsString());
      if (lockData['status'] == 'IN_PROGRESS' && lockData['timestamp'] != null) {
        final startTime = DateTime.parse(lockData['timestamp']);
        final diff = DateTime.now().difference(startTime);
        if (diff.inHours >= 8) {
          print('[CRITICAL] SESSION-EXPIRED: Esta sesión tiene ${diff.inHours}h de antigüedad.');
          print('           El bloqueo del Kernel ha expirado para prevenir Sesiones Zombie.');
          print('           ACCIÓN REQUERIDA: Ejecute "gov handover --force" para liberar el estado.');
          
          final ledger = ForensicLedger();
          await ledger.appendEntry(
            sessionId: 'GATE-RED',
            type: 'ALERT',
            task: 'KILL-SWITCH',
            detail: 'Zombie session detected: ${diff.inHours}h old.',
            basePath: basePath,
          );
          return false;
        }
      }
    } catch (_) {}
  }

  try {
    final integrity = IntegrityEngine();

    // 1. Manifest Signature Check (VUL-08)
    final poPublicKeyXml = await _resolvePublicKey(basePath);
    if (poPublicKeyXml != null && !skipSignatureCheck) {
      final isManifestOk = await integrity.verifyManifest(
        basePath: basePath,
        publicKeyXml: poPublicKeyXml,
      );
      if (!isManifestOk) {
        print('[CRITICAL] KERNEL-VIOLATION: La firma del manifiesto (kernel.hashes.sig) es INVÁLIDA.');
        return false;
      }
      print('  [✅] MANIFEST-SIG: OK');
    } else {
      print('  [!] WARNING: Omitiendo validación de firma de manifiesto.');
    }

    // 2. Hash Verification
    final results = await integrity.verifyAll(basePath: basePath);
    bool allOk = true;
    for (var entry in results.entries) {
      final status = entry.value ? '[OK]' : '[CORRUPT]';
      print('  $status ${entry.key}');
      if (!entry.value) allOk = false;
    }

    if (allOk) {
      print('[✅] Auditoría de Integridad PASSED.');
    } else {
      print('[‼️] CRITICAL: Violación de Integridad detectada.');
    }

    // 3. Compliance Check
    final backlog = BacklogManager();
    final activeTasks = await backlog.checkConcurrency(basePath: basePath);
    if (activeTasks.isNotEmpty) {
      final taskId = activeTasks.first;
      final compliance = ComplianceGuard();
      final gitResult = await Process.run('git', ['status', '--porcelain', '--untracked-files=all'], workingDirectory: basePath);
      final stdout = gitResult.stdout as String;
      final modifiedFiles = stdout.split('\n')
          .where((l) => l.length >= 3)
          .map((l) => l.substring(3).trim())
          .where((f) => f.isNotEmpty)
          .toList();

      try {
        await compliance.enforcePreBaseline(taskId: taskId, modifiedFiles: modifiedFiles, basePath: basePath);
        print('  [✅] COMPLIANCE-OK: $taskId');
      } catch (e) {
        print('  [❌] COMPLIANCE-FAIL: $e');
        allOk = false;
      }
    }

    // 4. Ledger Anchor Verification (VUL-11)
    final isLedgerOk = await integrity.verifyLedgerAnchor(basePath: basePath);
    if (!isLedgerOk) {
      allOk = false;
    }

    // 5. Orphan Detection
    final orphans = await integrity.detectOrphans(basePath: basePath);
    if (orphans.isNotEmpty) {
      print('\n  [!] WARNING: Archivos huérfanos detectados: ${orphans.join(", ")}\n');
    }

    print('Audit COMPLETED.');
    return allOk;
  } catch (e, stack) {
    print('[CRITICAL] Error inesperado en audit: $e');
    print(stack);
    return false;
  }
}

Future<void> runAct(String basePath, {bool dryRun = false}) async {
  if (dryRun) {
    print('--- [DRY-RUN] SIMULACIÓN DE VUELO ACTIVA ---');
  }
  await runAudit(basePath);

  final telemetry = TelemetryService();
  final pulse = await telemetry.computePulse(basePath: basePath);

  print('--- [TELEMETRY] PULSE ---');
  print('Saturation: ${pulse.saturation}% | CP: ${pulse.cp}');

  if (pulse.saturation > 90) {
    print('[FATIGUE] Hard-stop: Saturation too high. Run handover.');
  }

  if (dryRun) {
    print('\n[INFO] DRY-RUN: Omitiendo persistencia de telemetría y registros en historia.');
    return;
  }

  await telemetry.incrementTurns(basePath: basePath);
  await telemetry.persistPulse(pulse, basePath: basePath);

  final backlogManager = BacklogManager();
  final activeTasks = await backlogManager.checkConcurrency(basePath: basePath);
  final ledger = ForensicLedger();
  
  final taskId = activeTasks.isNotEmpty ? activeTasks.first : 'S06-GENERAL';
  
  try {
    await ledger.appendEntry(
      sessionId: 'ACT-${DateTime.now().millisecondsSinceEpoch}', 
      type: 'EXEC', 
      task: taskId, 
      detail: 'Pulse: ${pulse.saturation}% sat, ${pulse.cp} CP', 
      basePath: basePath
    );
    print('[✅] Pulse PERSISTIDO en historial.');
  } catch (e) {
    print('[⚠️] WARNING: No se pudo persistir el pulso en el historial: $e');
  }
}

Future<void> runStatus(String basePath) async {
  try {
    final telemetry = TelemetryService();
    final lockFile = File(p.join(basePath, 'session.lock'));
    
    double carryOver = 0.0;
    String sessionState = 'UNKNOWN';
    
    if (await lockFile.exists()) {
      final lockData = jsonDecode(await lockFile.readAsString());
      
      final integrity = IntegrityEngine();
      if (!integrity.verifySessionMAC(lockData)) {
          print('[CRITICAL] KERNEL-VIOLATION: session.lock MAC inválido o inexistente.');
          return;
      }
      
      sessionState = lockData['status'] ?? 'UNKNOWN';
      carryOver = (lockData['inherited_fatigue'] as num?)?.toDouble() ?? 0.0;
    }

    final pulse = await telemetry.computePulse(basePath: basePath, carryOverCP: carryOver);
    
    print('--- [GOV] PROJECT STATUS ---');
    print('Estado Sesión: $sessionState');
    print('Saturación:    ${pulse.saturation}%');
    print('Puntos CP:     ${pulse.cp} (Heredado: $carryOver)');
    print('----------------------------');
  } catch (e) {
    print('[CRITICAL] Fallo al recuperar estado: $e');
  }
}

Future<void> runContext(String basePath) async {
  final engine = ContextEngine();
  await engine.generateContext(basePath: basePath);
}

Future<void> runRestore(String basePath) async {
  final engine = ReconstitutionEngine();
  await engine.restore(basePath: basePath);
}

Future<void> runReport(String basePath) async {
  final engine = ReportEngine();
  final report = await engine.generateExecutiveReport(basePath);
  print(report);
}

Future<void> runHook(String basePath, ArgResults command) async {
  final subCommand = command.command;
  if (subCommand?.name == 'install') {
    final engine = HookEngine();
    await engine.installHooks(basePath: basePath);
  } else {
    print('[ERROR] Debe especificar un subcomando de hook (install).');
  }
}

Future<void> runHandover(String basePath, String? keyPath, {bool force = false}) async {
  print('--- [HANDOVER] CIERRE DE SESIÓN ---');
  final backlogManager = BacklogManager();
  final telemetry = TelemetryService();
  final vanguard = VanguardCore();
  final dashboard = DashboardEngine();

  if (force) {
    print('[WARNING] FORCE-HANDOVER: Ignorando validaciones de integridad por orden superior.');
  } else {
    final ok = await runAudit(basePath);
    if (!ok) {
       print('[CRITICAL] Handover abortado: El sistema no es íntegro. Use --force si es una emergencia.');
       return;
    }
  }

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
  final lockData = {
    'status': 'HANDOVER_SEALED',
    'timestamp': timestamp,
    'shs_at_close': pulse.saturation,
    'git_hash': gitHash,
  };
  
  final integrity = IntegrityEngine();
  lockData['_mac'] = integrity.generateSessionMAC(lockData);
  
  await lockFile.writeAsString(jsonEncode(lockData));

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
    
    final integrity = IntegrityEngine();
    if (!integrity.verifySessionMAC(lock)) {
        print('[CRITICAL] KERNEL-VIOLATION: session.lock MAC inválido o inexistente.');
        return;
    }
    
    if (lock['status'] != 'HANDOVER_SEALED') {
      print('[CRITICAL] FAIL-SAFE: La sesión previa no fue cerrada correctamente.');
      return;
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
    return;
  }

  await runAudit(basePath);

  final lockData = {
    'status': 'IN_PROGRESS',
    'timestamp': DateTime.now().toIso8601String(),
    'inherited_fatigue': inheritedCP,
  };
  
  final integrity = IntegrityEngine();
  lockData['_mac'] = integrity.generateSessionMAC(lockData);
  
  await lockFile.writeAsString(jsonEncode(lockData));

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
  // En baseline, saltamos el check de firma porque precisamente vamos a regenerarla (VUL-08)
  await runAudit(basePath, skipSignatureCheck: true);
  print('DEBUG-BASELINE: Audit returned, continuing to seal...');

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

  print('DEBUG-BASELINE: Audit complete. Resolving key...');
  // Resolve key from vault if not provided (VUL-02)
  final resolvedKeyPath = keyPath ?? await _resolveKeyPath(basePath, activeSprint['id']);
  print('DEBUG-BASELINE: Resolved Key Path: $resolvedKeyPath');
  if (resolvedKeyPath == null) {
     print('[CRITICAL] No se encontró clave vinculada para el proyecto. Use "gov vault bind-key".');
     return;
  }

  final gitResult = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: basePath);
  final gitHash = (gitResult.stdout as String).trim();
  print('DEBUG-BASELINE: Git Hash: $gitHash');
  final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceFirst('T', ' ');

  final lockFile = File(p.join(basePath, 'session.lock'));
  final lockData = {
    'status': 'BASELINE_SEALED',
    'timestamp': timestamp,
    'sprint_id': activeSprint['id'],
    'git_hash': gitHash,
  };
  
  final integrity = IntegrityEngine();
  lockData['_mac'] = integrity.generateSessionMAC(lockData);
  
  await lockFile.writeAsString(jsonEncode(lockData));
  print('DEBUG-BASELINE: session.lock updated.');

  // 2. Generate and Sign Manifest (VUL-08)
  print('[DEBUG] Generando nuevo manifiesto de hashes...');
  final newHashes = await integrity.generateHashes(basePath: basePath);
  
  // Enforce sorted keys for deterministic JSON (VUL-08)
  final sortedHashesArr = newHashes.keys.toList()..sort();
  final sortedHashes = { for (var k in sortedHashesArr) k : newHashes[k] };
  
  final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
  await hashesFile.writeAsString(JsonEncoder.withIndent('  ').convert(sortedHashes));
  print('DEBUG-BASELINE: kernel.hashes written.');

  final keyFile = File(resolvedKeyPath);
  if (!await keyFile.exists()) {
    print('[ERROR] SignEngine: Error al cargar clave privada del PO. El archivo NO EXISTE en esa ruta.');
    return;
  }
  final privateKeyXml = await keyFile.readAsString();
  print('DEBUG-BASELINE: Signing manifest...');
  await integrity.signManifest(basePath: basePath, privateKeyXml: privateKeyXml);
  print('DEBUG-BASELINE: Manifest signed.');

  // TASK-S16-01: Auto-Commit Semántico
  final activeTask = backlogManager.getActiveTask(activeSprint);
  String commitMsg = 'chore(${activeSprint['id']}): Baseline seal';
  if (activeTask != null) {
     commitMsg = 'feat(${activeSprint['id']}): ${activeTask['id']} - ${activeTask['desc']}';
  }
  
  print('[OPS] Ejecutando Auto-Commit: $commitMsg');
  await Process.run('git', ['add', '.'], workingDirectory: basePath);
  final commitResult = await Process.run('git', ['commit', '-m', commitMsg], workingDirectory: basePath);
  if (commitResult.exitCode == 0) {
    print('  [✅] GIT-COMMIT: OK');
  } else {
    print('  [!] GIT-COMMIT: No hay cambios pendientes o error en commit.');
  }

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

/// S12-01: Vault implementation for secure key binding (VUL-02).
Future<void> runVault(String basePath, ArgResults command) async {
  final vaultFile = File(p.join(basePath, 'vault', 'keys.json'));
  Map<String, String> keys = {};
  
  if (await vaultFile.exists()) {
    keys = Map<String, String>.from(jsonDecode(await vaultFile.readAsString()));
  }

  final subCommand = command.command;
  if (subCommand == null) {
    print('[ERROR] Debe especificar un subcomando de vault (bind-key, status).');
    return;
  }

  switch (subCommand.name) {
    case 'bind-key':
      final id = subCommand['project'] as String?;
      final path = subCommand['key'] as String?;
      if (id == null || path == null) {
        print('[ERROR] Faltan argumentos: --project <ID> --key <PATH>');
        return;
      }
      keys[id] = path;
      await vaultFile.writeAsString(jsonEncode(keys));
      print('[✅] Clave vinculada exitosamente para: $id');
      break;
    case 'status':
      print('--- [VAULT] CLAVES VINCULADAS ---');
      keys.forEach((id, path) => print('  $id -> $path'));
      break;
    default:
      print('[ERROR] Subcomando de vault no reconocido: ${subCommand.name}');
  }
}

Future<String?> _resolvePublicKey(String basePath) async {
  final vaultFile = File(p.join(basePath, 'vault', 'keys.json'));
  if (await vaultFile.exists()) {
    final Map<String, dynamic> keys = jsonDecode(await vaultFile.readAsString());
    print('DEBUG: [VAULT-LOAD] Claves cargadas: ${keys.length}');
    for (var entry in keys.entries) {
      final keyPath = entry.value as String;
      final pubKeyPath = keyPath.replaceFirst('_private.xml', '_public.xml');
      final pubKeyFile = File(p.join(basePath, pubKeyPath));
      print('DEBUG: [VAULT-LOAD] Probando clave: ${pubKeyFile.path}');
      if (await pubKeyFile.exists()) {
        return await pubKeyFile.readAsString();
      }
    }
  }

  // Fallback to default path
  final pubKeyFile = File(p.join(basePath, 'vault', 'po_public.xml'));
  print('DEBUG: Buscando clave pública (fallback) en: ${pubKeyFile.path}');
  if (await pubKeyFile.exists()) {
    return await pubKeyFile.readAsString();
  }
  return null;
}

Future<String?> _resolveKeyPath(String basePath, String projectId) async {
  final vaultFile = File(p.join(basePath, 'vault', 'keys.json'));
  if (!await vaultFile.exists()) return null;
  
  final Map<String, dynamic> keys = jsonDecode(await vaultFile.readAsString());
  return keys[projectId] as String?;
}

Future<void> runPack(String basePath) async {
  try {
    print('--- [PACK] EXPORTACIÓN PARA AUDITORÍA ---');
    
    // 1. Mandatory Audit
    print('[INFO] Ejecutando auditoría previa...');
    await runAudit(basePath);

    // 2. Packaging
    final packer = PackEngine();
    final zipPath = await packer.pack(basePath: basePath);

    final ledger = ForensicLedger();
    await ledger.appendEntry(
      sessionId: 'PACK-${DateTime.now().millisecondsSinceEpoch}',
      type: 'SNAP',
      task: 'PACK',
      detail: 'Project exported to ZIP: ${p.basename(zipPath)}',
      basePath: basePath,
    );

    print('\n----------------------------------------');
    print('  [GOV] EXPORTACIÓN EXITOSA');
    print('  Archivo: $zipPath');
    print('----------------------------------------\n');
  } catch (e, stack) {
    print('[CRITICAL] Error en pack: $e');
    print(stack);
  }
}
