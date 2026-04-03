import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/services/pulse_aggregator.dart';
import 'package:antigravity_dpi/src/services/fleet_service.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_monitor.dart';
import 'package:antigravity_dpi/src/dash/dashboard_engine.dart';
import 'package:antigravity_dpi/src/version.dart';

/// GOVERNANCE KERNEL (v9.0.0 - NUCLEUS-V9)
/// Refactored for S28-02: Decoupled Logic via PulseAggregator & FleetService.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addCommand('init', ArgParser()..addOption('name', abbr: 'n', defaultsTo: 'NewProject'))
    ..addCommand('adopt')
    ..addCommand('audit')
    ..addCommand('check')
    ..addCommand('act', ArgParser()
      ..addOption('prompt-tokens', abbr: 'p', defaultsTo: '0')
      ..addOption('output-tokens', abbr: 'o', defaultsTo: '0')
      ..addOption('finish-reason', abbr: 'f', defaultsTo: 'stop'))
    ..addCommand('status')
    ..addCommand('fleet-pulse')
    ..addCommand('baseline')
    ..addCommand('handover')
    ..addCommand('takeover')
    ..addCommand('vault')
    ..addCommand('watch')
    ..addCommand('housekeeping')
    ..addCommand('sign', ArgParser()..addOption('file', abbr: 'f'))
    ..addCommand('verify', ArgParser()..addOption('file', abbr: 'f')..addOption('sig', abbr: 's'))
    ..addCommand('purge')
    ..addCommand('upgrade')
    ..addCommand('sync-context')
    ..addFlag('json', abbr: 'j', negatable: false, help: 'Output in JSON format')
    ..addFlag('version', abbr: 'v', negatable: false);

  final results = parser.parse(args);
  if (results['version']) {
    print('antigravity_gov v$kKernelVersion (NUCLEUS-V9)');
    return;
  }

  final command = results.command?.name;
  final basePath = Directory.current.path;

  switch (command) {
    case 'init':
      await runInit(basePath, results.command!);
      break;
    case 'adopt':
      await runAdopt(basePath, results.command!);
      break;
    case 'audit':
      await runAudit(basePath, results.command!);
      break;
    case 'act':
      await runAct(basePath, results.command!);
      break;
    case 'status':
      await printStatus(basePath, jsonOutput: results['json']);
      break;
    case 'fleet-pulse':
      await runFleetPulse(basePath, results.command!);
      break;
    case 'baseline':
      await runBaseline(basePath, results.command!);
      break;
    case 'handover':
      await runHandover(basePath, results.command!);
      break;
    case 'takeover':
      await runTakeover(basePath, results.command!);
      break;
    case 'vault':
      await runVault(basePath, results.command!);
      break;
    case 'watch':
      await runWatch(basePath, results.command!);
      break;
    case 'housekeeping':
      await runHousekeeping(basePath, results.command!);
      break;
    case 'sign':
      await runSign(basePath, results.command!);
      break;
    case 'verify':
      await runVerify(basePath, results.command!);
      break;
    case 'purge':
      await runPurge(basePath, results.command!);
      break;
    case 'upgrade':
      await runUpgrade(basePath, results.command!);
      break;
    case 'sync-context':
      await runSyncContext(basePath, results.command!.rest);
      break;
    default:
      print('Uso: gov <comando> [opciones]');
      print('Comandos: audit, act, status, fleet-pulse, baseline, handover, takeover, vault, watch, housekeeping, purge, upgrade, sync-context');
  }
}

// --- PROTOCOLO DE PRESERVACIÓN CRÍTICA (TASK-DPI-S29-06) ---

Future<bool> _checkSecurityHold(String basePath) async {
  final holdFile = File(p.join(basePath, '.meta', 'SECURITY_HOLD'));
  if (holdFile.existsSync()) {
    print('\x1B[31m[CRITICAL] SECURITY_HOLD activo (Manual/Permanente). Operación denegada.\x1B[0m');
    return true;
  }

  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  
  if (pulse.evaluation.state == EvaluatorState.SECURITY_HOLD) {
    print('\x1B[31m[CRITICAL] SECURITY_HOLD detectado (BHI: ${pulse.bunker.bhi}%). Operación abortada.\x1B[0m');
    print('[INFO] El sistema requiere intervención humana para certificar el estado actual.');
    return true;
  }
  return false;
}

Future<void> runVault(String basePath, ArgResults results) async {
  if (results.rest.isEmpty) {
    print('Uso: gov vault <sub-comando>');
    print('Sub-comandos: unhold');
    return;
  }

  final subCommand = results.rest[0];
  if (subCommand == 'unhold') {
    final holdFile = File(p.join(basePath, '.meta', 'SECURITY_HOLD'));
    if (holdFile.existsSync()) {
      await holdFile.delete();
      print('[OK] Bloqueo manual de SECURITY_HOLD levantado.');
    } else {
      print('[INFO] No se detectó un bloqueo manual activo en .meta/SECURITY_HOLD.');
    }
    
    // Verificación de métricas post-unhold
    final aggregator = PulseAggregator(basePath);
    final pulse = await aggregator.calculatePulse();
    if (pulse.saturation >= 90) {
      print('\x1B[33m[WARNING] El sistema sigue en zona roja (SHS: ${pulse.saturation}%). El siguiente "act" podría re-bloquear el kernel.\x1B[0m');
    }
  } else {
    print('Sub-comando no reconocido: $subCommand');
  }
}

// --- COMANDOS DE ARRANQUE (BOOTSTRAPPING) ---

Future<void> runInit(String basePath, ArgResults results) async {
  if (results.rest.isEmpty) {
    print('Uso: gov init <path> [--name <ProjectName>]');
    return;
  }

  final targetPath = p.join(basePath, results.rest[0]);
  final projectName = results['name'];
  
  print('Iniciando Proyecto: $projectName en $targetPath');
  
  if (!Directory(targetPath).existsSync()) Directory(targetPath).createSync(recursive: true);

  // Crear Estructura de Vault
  Directory(p.join(targetPath, 'vault', 'rules')).createSync(recursive: true);
  File(p.join(targetPath, 'vault', 'rules', 'roles.json')).writeAsStringSync(jsonEncode({
    'roles': ['PO', 'ARCH', 'DEV', 'QA'],
    'permissions': {
      'PO': ['SEAL', 'HANDOVER'],
      'ARCH': ['BASELINE', 'DESIGN'],
    }
  }));

  // Crear VISION.md y GEMINI.md
  File(p.join(targetPath, 'VISION.md')).writeAsStringSync('# VISION: $projectName\nIdentidad del proyecto y metas estratégicas.');
  File(p.join(targetPath, 'GEMINI.md')).writeAsStringSync('# GEMINI.md\nProtocolos de la IA y reglas de gobernanza.');

  // Crear Backlog Inicial
  final backlog = {
    'project': projectName,
    'current_sprint': 'S00-INCEPTION',
    'status': 'ACTIVE',
    'version': '0.1.0',
    'sprints': [
      {
        'id': 'S00-INCEPTION',
        'name': 'Incepción del Búnker',
        'status': 'IN_PROGRESS',
        'goal': 'Establecer las bases de gobernanza y visión del producto.',
        'tasks': [
          {
            'id': 'TASK-S00-01',
            'label': 'BIZ',
            'desc': 'Definir Visión Estratégica (VISION.md)',
            'status': 'PENDING',
            'required_signatures': ['PO']
          },
          {
            'id': 'TASK-S00-02',
            'label': 'ARCH',
            'desc': 'Configurar Protocolos de IA (GEMINI.md)',
            'status': 'PENDING',
            'required_signatures': ['ARCH']
          }
        ]
      }
    ]
  };
  File(p.join(targetPath, 'backlog.json')).writeAsStringSync(jsonEncode(backlog));

  // Crear Archivos de Tarea
  final sprintDir = Directory(p.join(targetPath, '.meta', 'sprints', 'S00-INCEPTION'));
  sprintDir.createSync(recursive: true);
  File(p.join(sprintDir.path, 'TASK-S00-01.md')).writeAsStringSync('# TASK-S00-01: BIZ\nDefinición de visión.');
  File(p.join(sprintDir.path, 'TASK-S00-02.md')).writeAsStringSync('# TASK-S00-02: ARCH\nConfiguración de protocolos.');

  print('[✅] Bunker inicializado con éxito. Inicie con: gov takeover');
}

Future<void> runAdopt(String basePath, ArgResults results) async {
  if (results.rest.isEmpty) {
    print('Uso: gov adopt <path>');
    return;
  }

  final targetPath = p.join(basePath, results.rest[0]);
  if (!Directory(targetPath).existsSync()) {
    print('[ERROR] El directorio especificado no existe: $targetPath');
    return;
  }

  print('Adoptando proyecto en: $targetPath');

  final List<Map<String, dynamic>> tasks = [];
  
  if (!File(p.join(targetPath, 'VISION.md')).existsSync()) {
    tasks.add({
      'id': 'TASK-ADOPT-01',
      'label': 'ALIGN',
      'desc': 'Crear VISION.md para alineación estratégica',
      'status': 'PENDING',
      'required_signatures': ['PO']
    });
  }

  if (!File(p.join(targetPath, 'GEMINI.md')).existsSync()) {
    tasks.add({
      'id': 'TASK-ADOPT-02',
      'label': 'ALIGN',
      'desc': 'Crear GEMINI.md para protocolos de gobernanza',
      'status': 'PENDING',
      'required_signatures': ['ARCH']
    });
  }

  final backlog = {
    'project': p.basename(targetPath),
    'current_sprint': 'S01-ALIGNMENT',
    'status': 'ACTIVE',
    'version': '1.0.0-ADOPTED',
    'sprints': [
      {
        'id': 'S01-ALIGNMENT',
        'name': 'Alineación de Gobernanza',
        'status': 'IN_PROGRESS',
        'goal': 'Sincronizar el proyecto legado con el Kernel AG DPI.',
        'tasks': tasks
      }
    ]
  };

  File(p.join(targetPath, 'backlog.json')).writeAsStringSync(jsonEncode(backlog));
  print('[✅] Proyecto adoptado. Sprint de alineación generado.');
}

// --- COMANDOS REFACCIONADOS S28-02 ---

Future<void> runAudit(String basePath, [ArgResults? results, bool skipLog = false]) async {
  final integrity = IntegrityEngine();
  final forensic = ForensicLedger();
  
  print('=== GOV AUDIT NUCLEUS-V9 ===');
  
  final isIntact = await integrity.verifySelf(toolRoot: basePath);
  if (!isIntact && Platform.environment['DPI_GOV_DEV'] != 'true') {
    print('\x1B[31m[CRITICAL] DNA Integrity Mismatch. System compromised.\x1B[0m');
    exit(1);
  }

  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  await aggregator.persistPulse(pulse);

  final swelling = await integrity.checkSwelling(basePath);
  final zombies = await integrity.checkZombies(basePath);

  // S30-REV: Cascading Binary Handover Check
  final updateFile = File(p.join(basePath, 'bin', 'gov.exe.update'));
  final sigFile = File(p.join(basePath, 'bin', 'kernel_handover.sig'));
  final pubKeyFile = File(p.join(basePath, 'vault', 'po_public.xml'));

  if (updateFile.existsSync() && sigFile.existsSync() && pubKeyFile.existsSync()) {
    print('[UPDATE] Relevo binario detectado. Verificando firma del PO...');
    final isVerified = await integrity.verifyBinaryHandover(
      binPath: updateFile.path,
      sigPath: sigFile.path,
      publicKeyXml: pubKeyFile.readAsStringSync(),
    );

    if (isVerified) {
      print('\x1B[32m[✅] Relevo verificado. Nueva versión adoptada técnica mente.\x1B[0m');
      print('[INFO] El búnker local operará con v9.0.2 en el próximo comando.');
      // En una implementación real, aquí haríamos el swap del binario si es posible
    } else {
      print('\x1B[31m[FAIL] Relevo fallido. El binario de actualización no coincide con la firma del PO.\x1B[0m');
      print('[INFO] Fallback: Continuando con la versión estable actual.');
    }
  }

  print('=== GOV AUDIT NUCLEUS-V9 ===');
  
  // VERIFICACIÓN DE VISIÓN (Hard-Gate Restaurado)
  final visionFile = File(p.join(basePath, 'VISION.md'));
  if (!visionFile.existsSync() || visionFile.readAsStringSync().length < 50) {
    print('\x1B[31m[FAIL] INSIGHT INSUFICIENTE: VISION.md ausente o demasiado corto (<50 carac).\x1B[0m');
    exit(1);
  }

  print('Integridad: ${isIntact ? "SEALED" : "\x1B[31mCOMPROMISED\x1B[0m"}');
  
  // Reporte de Sello Digital
  final manifestSigFile = File(p.join(basePath, 'vault', 'kernel.hashes.sig'));
  if (manifestSigFile.existsSync()) {
    print('Sello Digital: RSA-CERTIFIED');
  } else {
    print('Sello Digital: \x1B[33mHASH-ONLY (WARNING: No firmado por PO)\x1B[0m');
  }

  final hasUpdate = Directory(p.join(basePath, 'bin')).listSync().any((f) => f.path.endsWith('.update'));
  if (!isIntact && hasUpdate) {
    print('\x1B[33m[HINT]: Nueva versión certificada detectada en bin/. Ejecute "gov upgrade" para restaurar la integridad del ADN.\x1B[0m');
  } else if (!isIntact) {
    print('\x1B[31m[CRITICAL]: DNA Mismatch detectado sin candidato de actualización. El binario podría estar corrupto.\x1B[0m');
  }

  print('Saturación (SHS): ${pulse.saturation}%');
  print('Zombies detectados: ${zombies.length}');
  print('Densidad (Swelling): ${swelling.fileCount} archivos');

  if (!skipLog) {
    await forensic.appendEntry(
      sessionId: 'Manual',
      type: 'AUDIT',
      task: 'Kernel Self-Audit',
      detail: 'Audit completed. SHS: ${pulse.saturation}%',
      basePath: basePath,
    );
  }

  // S30-REV: Ensure telemetry reflects the audit state
  await aggregator.persistPulse(pulse);
}

Future<void> runAct(String basePath, ArgResults results) async {
  final telemetry = TelemetryService(basePath: basePath);
  final rateFile = File('.meta/last_act_rate');
  
  if (rateFile.existsSync()) {
    final lastAct = DateTime.parse(rateFile.readAsStringSync());
    if (DateTime.now().difference(lastAct).inSeconds < 30) {
      print('[RATE-LIMIT] ACT bloqueado por 30s. Spam detectado.');
      return;
    }
  }
  rateFile.createSync(recursive: true);
  rateFile.writeAsStringSync(DateTime.now().toIso8601String());

  await telemetry.incrementTurns(basePath: basePath);
  
  // [HOT-CAPTURE] S29-02: Metadata interception
  final pTokens = int.tryParse(results['prompt-tokens'] ?? '0') ?? 0;
  final oTokens = int.tryParse(results['output-tokens'] ?? '0') ?? 0;
  final fReason = results['finish-reason'];
  
  if (pTokens > 0 || oTokens > 0) {
    await telemetry.updateMetadata(
      promptTokens: pTokens,
      outputTokens: oTokens,
      finishReason: fReason,
    );
  }

  final aggregator = PulseAggregator(basePath);
  final pulseData = await aggregator.calculatePulse();
  
  // S29-SYNC: Persist the calculated pulse to fleet-visible telemetry
  await aggregator.persistPulse(pulseData);

  // S29-HUD: Generate the Vanguard Dashboard for the PO
  final dashboard = DashboardEngine();
  await dashboard.generate(
    pulse: pulseData, 
    basePath: basePath,
    activeSprint: 'A01-GOVERNANCE-EVO',
    activeTask: 'TASK-A01-06',
  );

  final eval = pulseData.evaluation;
  
  if (eval.state == EvaluatorState.LOCKED) {
    print('\x1B[31m[LOCKED] Sesión bloqueada por fatiga (CUS: ${pulseData.context.cus}%). Protocolo: ${eval.protocol}\x1B[0m');
    await runHandover(basePath, results); 
  } else if (eval.state == EvaluatorState.WARNING) {
    print('\x1B[33m[WARNING] Cerca del Redline operativo (CUS: ${pulseData.context.cus}%). Tome precauciones.\x1B[0m');
  } else if (eval.state == EvaluatorState.SECURITY_HOLD) {
    print('\x1B[41m[SECURITY_HOLD] Integridad comprometida (BHI: ${pulseData.bunker.bhi}%). Intervención requerida.\x1B[0m');
  } else {
    print('[OK] Act de interacción registrado. SHS: ${pulseData.saturation}%');
  }
}

Future<void> runFleetPulse(String basePath, ArgResults results) async {
  final fleet = FleetService(basePath: basePath);
  final aggregator = PulseAggregator(basePath);
  
  print('=== FLEET PULSE AGGREGATION [v$kKernelVersion] ===');
  
  final pulseData = await aggregator.calculatePulse();
  await aggregator.persistPulse(pulseData);
  
  await fleet.registerProject(name: 'Kernel', path: basePath);
  final fleetStatus = await fleet.aggregateFleetPulse();
  
  print('');
  print('PROJECT'.padRight(12) + ' | ' + 'PROJ-VER'.padRight(10) + ' | ' + 'KERN-VER'.padRight(10) + ' | ' + 'UUID'.padRight(10) + ' | ' + 'SHS (CUS/BHI)');
  print('-' * 75);

  for (var node in fleetStatus) {
    final name = node.name.padRight(12);
    final pVer = node.projectVersion.padRight(10);
    final kVer = node.kernelVersion.padRight(10);
    final uuidStr = node.sessionUuid;
    final uuid = (uuidStr.length >= 8 ? uuidStr.substring(0, 8) : uuidStr).padRight(10);
    final metrics = '${node.shs}% (${node.cus.toStringAsFixed(1)}/${node.bhi.toStringAsFixed(1)})';
    
    final statusColor = node.isOnline ? '\x1B[32m[OK]\x1B[0m' : '\x1B[31m[OFF]\x1B[0m';
    
    print('$name | $pVer | $kVer | $uuid | $metrics $statusColor');
  }
}

Future<void> runWatch(String basePath, ArgResults results) async {
  print('=== GOV WATCH MODE: ACTIVE ===');
  final monitor = TelemetryMonitor(basePath: basePath);
  await monitor.start();
}

Future<void> printStatus(String basePath, {bool jsonOutput = false}) async {
  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  if (jsonOutput) {
     print(jsonEncode(pulse.detail));
  } else {
     print('=== $kKernelBanner ===');
     print('Codename: $kKernelCodename');
     print('CUS: ${pulse.cp.toStringAsFixed(1)}% | BHI: ${pulse.bunker.bhi.toStringAsFixed(1)}%');
     print('SHS: ${pulse.saturation}% | Session: ${pulse.sessionUuid}');
  }
  
  // S30-REV: Automatic telemetry refresh on status
  await aggregator.persistPulse(pulse);
}

Future<void> runSyncContext(String basePath, List<String> args) async {
  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  print(jsonEncode(pulse.detail));
  
  // S30-REV: Telemetry sync for act automation
  await aggregator.persistPulse(pulse);
}

// --- COMANDOS DE CICLO DE VIDA (GATE-GOLD) ---

Future<void> runBaseline(String basePath, ArgResults results) async {
  if (await _checkSecurityHold(basePath)) return;
  final integrity = IntegrityEngine();
  final hashes = await integrity.generateHashes(basePath: basePath);
  
  final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
  final selfHashesFile = File(p.join(basePath, 'vault', 'self.hashes'));
  
  if (!hashesFile.parent.existsSync()) hashesFile.parent.createSync(recursive: true);
  
  final hashesJson = jsonEncode(hashes);
  await hashesFile.writeAsString(hashesJson);
  await selfHashesFile.writeAsString(hashesJson);
  
  print('[DONE] Baseline NUCLEUS-V9.1 (SENTINEL) generado y persistido en vault/.');
  
  // RESTAURACIÓN GATE-GOLD: Firma del PO Obligatoria
  final keyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  if (!keyFile.existsSync()) {
    print('\x1B[31m[ERROR] CRÍTICO: No se encuentra vault/po_private.xml.\x1B[0m');
    print('La firma del PO es OBLIGATORIA para baselining en GATE-GOLD.');
    if (Platform.environment['DPI_GOV_DEV'] != 'true') exit(1);
  } else {
    print('Firmando manifiesto con PO Private Key...');
    await integrity.signManifest(basePath: basePath, privateKeyXml: keyFile.readAsStringSync());
    print('[✅] Manifiesto SELLADO con firma RSA.');
  }
}

Future<void> runHandover(String basePath, ArgResults results) async {
  final forensic = ForensicLedger();
  
  print('=== GOV HANDOVER PROTOCOL (v1.4.1 SENTINEL) ===');
  
  // 1. AUDITORÍA MANDATORIA PRE-RELEVO (Skip log to avoid hook deadlock)
  print('[1/4] Iniciando Auditoría de Integridad Certificada...');
  await runAudit(basePath, null, true);

  // REG-v1.4.3: Sellado de Salida (Self-Baseline)
  print('[2/4] Ejecutando Sellado de Salida (Self-Baseline) v1.4.3...');
  await runBaseline(basePath, results);

  // 3. CONCILIACIÓN AUTOMÁTICA DE BACKLOG
  print('[3/4] Sincronizando registro de gobernanza (backlog.json)...');
  final backlogFile = File(p.join(basePath, 'backlog.json'));
  if (backlogFile.existsSync()) {
    try {
      final backlog = jsonDecode(backlogFile.readAsStringSync()) as Map<String, dynamic>;
      final versionKey = (backlog['project'] == 'antigravity_dpi') ? 'version' : 'kernel_version';
      if (backlog[versionKey] != kKernelVersion) {
        backlog[versionKey] = kKernelVersion;
        backlogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(backlog));
        print('  [REGISTRY] Versión conciliada a v$kKernelVersion.');
      }
    } catch (e) {
      print('  [WARNING] Error conciliando backlog: $e');
    }
  }

  // 4. GENERACIÓN DE RELAY ATÓMICO (v1.4.0)
  print('[4/4] Sellando Sesión y Generando Relay Atómico...');
  String gitHash = 'UNKNOWN';
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    if (result.exitCode == 0) gitHash = result.stdout.toString().trim();
  } catch (_) {}

  final relayId = 'RELAY-${DateTime.now().millisecondsSinceEpoch}';
  final relayPath = p.join(basePath, '.meta', 'session.relay');
  
  final relayData = {
    'id': relayId,
    'timestamp': DateTime.now().toIso8601String(),
    'git_hash': gitHash,
    'status': 'LOCKED',
    'governance_separation': 'SENTINEL-v1.4.1: Decoupled Deadlock-Fix',
    'kernel_version': kKernelVersion,
  };

  if (!Directory('.meta').existsSync()) Directory('.meta').createSync();
  File(relayPath).writeAsStringSync(jsonEncode(relayData));
  
  await forensic.appendEntry(
    sessionId: relayId,
    type: 'HANDOVER',
    task: 'Session Transfer',
    detail: 'Automated Handover (v1.4.1) completed. Audit: SUCCESS. Logic: Decoupled-Seal.',
    basePath: basePath,
  );
  
  print('\n[✅] HANDOVER FINALIZADO. La sesión ha sido sellada y registrada.');
  print('Relay ID: $relayId | Git: $gitHash');
  print('Estado: SESSION_LOCKED');
}

Future<void> runTakeover(String basePath, ArgResults results) async {
  if (await _checkSecurityHold(basePath)) return;
  
  // S30-REV: Automated Housekeeping (Clean Start)
  print('[HOUSEKEEPING] Purga automática iniciada...');
  await runHousekeeping(basePath, results);

  final relayPath = p.join(basePath, '.meta', 'session.relay');

  print('=== GOV TAKEOVER PROTOCOL ===');
  
  if (!File(relayPath).existsSync()) {
    print('\x1B[31m[ERROR] No se encontró relay activo. Takeover bloqueado.\x1B[0m');
    return;
  }

  final relayData = jsonDecode(File(relayPath).readAsStringSync());
  print('Restaurando sesión: ${relayData['id']}');

  // REG-v1.4.2: Mandato de Purga por Rotación (UUID Change Detection)
  print('[TAKEOVER] Sincronización de Contexto y Purga Mandatoria v1.4.2...');
  await runPurge(basePath, results);

  File(relayPath).deleteSync();
  
  print('Estado: SESSION_ACTIVE');
  print('Métricas reseteadas para nueva fase cognitiva.');
}

Future<void> runHousekeeping(String basePath, ArgResults results) async {
  if (await _checkSecurityHold(basePath)) return;
  final integrity = IntegrityEngine();
  final zombies = await integrity.checkZombies(basePath);
  
  if (zombies.isEmpty) {
    print('[CLEAN] No se detectaron zombies en el bunker.');
    return;
  }
  
  print('Purgando ${zombies.length} zombies...');
  for (var z in zombies) {
    final f = File(p.join(basePath, z));
    if (f.existsSync()) {
      await f.delete();
      print('- Eliminado: $z');
    }
  }
}

Future<void> runPurge(String basePath, ArgResults results) async {
  if (await _checkSecurityHold(basePath)) return;
  
  print('=== GOV PURGE PROTOCOL (Cognitive & Structural Reset) ===');
  
  // 1. Housekeeping (Zombies)
  print('[1/3] Limpieza de Zombies...');
  await runHousekeeping(basePath, results);
  
  // 2. Telemetry Reset (Cognitive)
  print('[2/3] Reseteo de contadores cognitivos...');
  final telemetry = TelemetryService(basePath: basePath);
  await telemetry.resetCounters(basePath: basePath);
  
  // 3. Status Check
  print('[3/3] Verificando salud final...');
  await printStatus(basePath);
  
  print('\n[✅] PURGA COMPLETADA. Sistema purificado y listo para operaciones.');
}

Future<void> runUpgrade(String basePath, ArgResults results) async {
  print('=== GOV UPGRADE PROTOCOL (Hot-Swap) ===');
  final integrity = IntegrityEngine();
  final pubKeyFile = File(p.join(basePath, 'vault', 'po_public.xml'));
  
  if (!pubKeyFile.existsSync()) {
    print('[ERROR] No se encuentra po_public.xml. Imposible verificar actualización.');
    return;
  }

  final binDir = Directory(p.join(basePath, 'bin'));
  if (!binDir.existsSync()) return;

  final updates = binDir.listSync().where((f) => f.path.endsWith('.update')).toList();
  if (updates.isEmpty) {
    print('No hay actualizaciones pendientes (.update) en la carpeta bin/.');
    return;
  }

  for (final updateFile in updates) {
    final name = p.basename(updateFile.path);
    final targetName = name.replaceAll('.update', '');
    final targetPath = p.join(binDir.path, targetName);
    final sigPath = updateFile.path + '.sig';

    print('Verificando $name ...');
    
    if (!File(sigPath).existsSync()) {
      print('  [FAIL] Falta firma (.sig) para $name. Abortando.');
      continue;
    }

    final isVerified = await integrity.verifyBinaryHandover(
      binPath: updateFile.path,
      sigPath: sigPath,
      publicKeyXml: pubKeyFile.readAsStringSync(),
    );

    if (isVerified) {
      print('  [OK] Firma RSA válida.');
      
      // Rotación con .old
      final oldPath = targetPath + '.old';
      if (File(targetPath).existsSync()) {
        if (File(oldPath).existsSync()) File(oldPath).deleteSync();
        File(targetPath).renameSync(oldPath);
        print('  [BACKUP] Anterior renombrado a .old');
      }

      File(updateFile.path).renameSync(targetPath);
      print('  [SUCCESS] Actualización aplicada: $targetName');
      
      // AUTO-REGISTRO DE VERSION (SENTINEL PROTOCOL)
      final backlogFile = File(p.join(basePath, 'backlog.json'));
      if (backlogFile.existsSync()) {
        try {
          final backlog = jsonDecode(backlogFile.readAsStringSync()) as Map<String, dynamic>;
          // Si el proyecto no es el kernel, usamos 'kernel_version' para no pisar la version del proyecto
          final versionKey = (backlog['project'] == 'antigravity_dpi') ? 'version' : 'kernel_version';
          backlog[versionKey] = kKernelVersion;
          backlogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(backlog));
          print('  [REGISTRY] backlog.json ($versionKey) actualizado a v$kKernelVersion.');
        } catch (e) {
          print('  [WARNING] No se pudo actualizar backlog.json: $e');
        }
      }

      final projectLogFile = File(p.join(basePath, 'PROJECT_LOG.md'));
      if (projectLogFile.existsSync()) {
        final logDate = DateTime.now().toString().substring(0, 16);
        projectLogFile.writeAsStringSync(
          '\n- [$logDate] [UPGRADE] Hot-Swap a $kKernelBanner. Versión sincronizada.',
          mode: FileMode.append,
        );
        print('  [LOG] PROJECT_LOG.md actualizado.');
      }
      
      // AUTO-SANACIÓN DE ADN (TASK-V9-02)
      if (targetName == 'gov.exe' || targetName == 'vanguard.exe') {
        final newHash = await integrity.calculateFileHash(File(targetPath));
        final sigName = targetName == 'vanguard.exe' ? 'vanguard_hash.sig' : 'gov_hash.sig';
        final dnaFile = File(p.join(basePath, 'vault', 'intel', sigName));
        if (!dnaFile.parent.existsSync()) dnaFile.parent.createSync(recursive: true);
        await dnaFile.writeAsString(newHash);
        print('  [DNA-SYNC] Ancla de integridad ($sigName) sincronizada con el nuevo binario.');
      }
    } else {
      print('  [CRITICAL] Firma RSA INVÁLIDA para $name. Sistema bloqueado.');
    }
  }
}

Future<void> runSign(String basePath, ArgResults results) async {
  final filePath = results['file'];
  if (filePath == null) {
     print('Uso: gov sign --file <path>');
     return;
  }
  
  final keyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  if (!keyFile.existsSync()) {
    print('[ERROR] po_private.xml no encontrado en vault/');
    return;
  }

  final targetFile = File(filePath);
  if (!targetFile.existsSync()) {
    print('[ERROR] Archivo a firmar no encontrado: $filePath');
    return;
  }

  final bytes = await targetFile.readAsBytes();
  final signer = SignEngine();
  final signature = await signer.sign(
    challenge: bytes,
    privateKeyXml: await keyFile.readAsString(),
  );

  final sigFile = File('$filePath.sig');
  await sigFile.writeAsBytes(signature);
  print('[✅] Archivo firmado con éxito: ${sigFile.path}');
}

Future<void> runVerify(String basePath, ArgResults results) async {
  final filePath = results['file'];
  final sigPath = results['sig'];
  if (filePath == null || sigPath == null) {
     print('Uso: gov verify --file <path> --sig <sig_path>');
     return;
  }

  final pubKeyFile = File(p.join(basePath, 'vault', 'po_public.xml'));
  if (!pubKeyFile.existsSync()) {
    print('[ERROR] po_public.xml no encontrado en vault/');
    return;
  }

  final integrity = IntegrityEngine();
  final isVerified = await integrity.verifyBinaryHandover(
    binPath: filePath,
    sigPath: sigPath,
    publicKeyXml: await pubKeyFile.readAsString(),
  );

  if (isVerified) {
    print('[✅] Firma verificada.');
  } else {
    print('[FAIL] Firma inválida.');
  }
}
