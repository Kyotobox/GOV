import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/services/pulse_aggregator.dart';
import 'package:antigravity_dpi/src/services/fleet_service.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/security/vanguard_core.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_monitor.dart';
import 'package:antigravity_dpi/src/version.dart';

/// GOVERNANCE KERNEL (v9.0.0 - NUCLEUS-V9)
/// Refactored for S28-02: Decoupled Logic via PulseAggregator & FleetService.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addCommand('audit')
    ..addCommand('check')
    ..addCommand('act')
    ..addCommand('status')
    ..addCommand('fleet-pulse')
    ..addCommand('baseline')
    ..addCommand('handover')
    ..addCommand('takeover')
    ..addCommand('vault')
    ..addCommand('watch')
    ..addCommand('housekeeping')
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
    case 'audit':
      await runAudit(basePath, results.command!.arguments);
      break;
    case 'act':
      await runAct(basePath, results.command!.arguments);
      break;
    case 'status':
      await printStatus(basePath, jsonOutput: results['json']);
      break;
    case 'fleet-pulse':
      await runFleetPulse(basePath, results.command!.arguments);
      break;
    case 'baseline':
      await runBaseline(basePath, results.command!.arguments);
      break;
    case 'handover':
      await runHandover(basePath, results.command!.arguments);
      break;
    case 'takeover':
      await runTakeover(basePath, results.command!.arguments);
      break;
    case 'vault':
      await runVault(basePath, results.command!.arguments);
      break;
    case 'watch':
      await runWatch(basePath, results.command!.arguments);
      break;
    case 'housekeeping':
      await runHousekeeping(basePath, results.command!.arguments);
      break;
    default:
      print('Uso: gov <comando> [opciones]');
      print('Comandos: audit, act, status, fleet-pulse, baseline, handover, takeover, vault, watch, housekeeping');
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

Future<void> runVault(String basePath, List<String> args) async {
  if (args.isEmpty) {
    print('Uso: gov vault <sub-comando>');
    print('Sub-comandos: unhold');
    return;
  }

  final subCommand = args[0];
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

// --- COMANDOS REFACCIONADOS S28-02 ---

Future<void> runAudit(String basePath, List<String> args) async {
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

  print('Integridad: ${isIntact ? "SEALED" : "UNSTABLE (DEV)"}');
  print('Saturación (SHS): ${pulse.saturation}%');
  print('Zombies detectados: ${zombies.length}');
  print('Densidad (Swelling): ${swelling.fileCount} archivos');

  await forensic.appendEntry(
    sessionId: 'Manual',
    type: 'AUDIT',
    task: 'Kernel Self-Audit',
    detail: 'Audit completed. SHS: ${pulse.saturation}%',
    basePath: basePath,
  );
}

Future<void> runAct(String basePath, List<String> args) async {
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
  final aggregator = PulseAggregator(basePath);
  final pulseData = await aggregator.calculatePulse();
  final eval = pulseData.evaluation;
  
  if (eval.state == EvaluatorState.LOCKED) {
    print('\x1B[31m[LOCKED] Sesión bloqueada por fatiga (CUS: ${pulseData.context.cus}%). Protocolo: ${eval.protocol}\x1B[0m');
    await runHandover(basePath, ['--force']);
  } else if (eval.state == EvaluatorState.WARNING) {
    print('\x1B[33m[WARNING] Cerca del Redline operativo (CUS: ${pulseData.context.cus}%). Tome precauciones.\x1B[0m');
  } else if (eval.state == EvaluatorState.SECURITY_HOLD) {
    print('\x1B[41m[SECURITY_HOLD] Integridad comprometida (BHI: ${pulseData.bunker.bhi}%). Intervención requerida.\x1B[0m');
  } else {
    print('[OK] Act de interacción registrado. SHS: ${pulseData.saturation}%');
  }
}

Future<void> runFleetPulse(String basePath, List<String> args) async {
  final fleet = FleetService(basePath: basePath);
  final aggregator = PulseAggregator(basePath);
  
  print('=== FLEET PULSE AGGREGATION ===');
  
  final pulseData = await aggregator.calculatePulse();
  await aggregator.persistPulse(pulseData);
  
  await fleet.registerProject(name: 'Kernel', path: basePath);
  final fleetStatus = await fleet.aggregateFleetPulse();
  
  print('Nodos Activos: ${fleetStatus.length}');
  for (var node in fleetStatus) {
    print('- [${node.name}]: SHS ${node.shs}% | Last Seen: ${node.lastSeen ?? "N/A"}');
  }
}

Future<void> runWatch(String basePath, List<String> args) async {
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
     print('=== STATUS NUCLEUS-V9 ===');
     print('CUS: ${pulse.cp.toStringAsFixed(1)}% | BHI: ${pulse.bunker.bhi.toStringAsFixed(1)}%');
     print('SHS: ${pulse.saturation}% | Session: ${Platform.environment['VANGUARD_CHAT_UUID']}');
  }
}

Future<void> runSyncContext(String basePath, List<String> args) async {
  final aggregator = PulseAggregator(basePath);
  final pulse = await aggregator.calculatePulse();
  print(jsonEncode(pulse.detail));
}

// --- COMANDOS DE CICLO DE VIDA (GATE-GOLD) ---

Future<void> runBaseline(String basePath, List<String> args) async {
  if (await _checkSecurityHold(basePath)) return;
  final integrity = IntegrityEngine();
  final hashes = await integrity.generateHashes(basePath: basePath);
  
  final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
  if (!hashesFile.parent.existsSync()) hashesFile.parent.createSync(recursive: true);
  await hashesFile.writeAsString(jsonEncode(hashes));
  
  print('[DONE] Baseline NUCLEUS-V9 generado y persistido en vault/kernel.hashes.');
  
  // S29: Firma automática si existe la llave privada
  final keyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  if (keyFile.existsSync()) {
    print('Firmando manifiesto con PO Private Key...');
    await integrity.signManifest(basePath: basePath, privateKeyXml: keyFile.readAsStringSync());
  }
}

Future<void> runHandover(String basePath, List<String> args) async {
  final forensic = ForensicLedger();
  
  print('=== GOV HANDOVER PROTOCOL ===');
  
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
  };

  if (!Directory('.meta').existsSync()) Directory('.meta').createSync();
  File(relayPath).writeAsStringSync(jsonEncode(relayData));
  
  await forensic.appendEntry(
    sessionId: relayId,
    type: 'HANDOVER',
    task: 'Session Transfer',
    detail: 'Session relay generated. ID: $relayId',
    basePath: basePath,
  );
  
  print('Relay ID: $relayId');
  print('Git Hash: $gitHash');
  print('Estado: SESSION_LOCKED');
}

Future<void> runTakeover(String basePath, List<String> args) async {
  if (await _checkSecurityHold(basePath)) return;
  final telemetry = TelemetryService(basePath: basePath);
  final relayPath = p.join(basePath, '.meta', 'session.relay');

  print('=== GOV TAKEOVER PROTOCOL ===');
  
  if (!File(relayPath).existsSync()) {
    print('\x1B[31m[ERROR] No se encontró relay activo. Takeover bloqueado.\x1B[0m');
    return;
  }

  final relayData = jsonDecode(File(relayPath).readAsStringSync());
  print('Restaurando sesión: ${relayData['id']}');

  await telemetry.resetCounters(basePath: basePath);
  File(relayPath).deleteSync();
  
  print('Estado: SESSION_ACTIVE');
  print('Métricas reseteadas para nueva fase cognitiva.');
}

Future<void> runHousekeeping(String basePath, List<String> args) async {
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
