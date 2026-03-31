import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/security/vanguard_core.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';

/// Base2 Governance Motor [DPI-GATE-GOLD]
/// Hardened with Vanguard RSA-2048 Lock.
void main(List<String> args) async {
  final basePath = Directory.current.path;
  final lockFile = File(p.join(basePath, '.meta', 'SESSION_LOCKED'));

  if (args.isEmpty) {
    print('Base2 Governance Motor v8.0.0 [DPI-GATE-GOLD]');
    print('Usage: gov <command> [options]');
    print('Commands: audit, status, act, baseline, takeover, handover, health, dashboard, prompt, sync-tasks, init, adopt, plan');
    exit(0);
  }

  final command = args[0];

  // Session Lock Guard (Criogénico)
  if (lockFile.existsSync() && command != 'takeover' && command != 'status' && command != 'dashboard' && command != 'sync-context') {
    print('[ERROR] Sesión Sellada. Relevo requerido via "gov takeover" en nuevo chat.');
    exit(1);
  }

  switch (command) {
    case 'audit':
      await _runAudit(basePath);
      break;
    case 'status':
      await _printStatus(basePath, jsonOutput: args.contains('--json'));
      break;
    case 'act':
      await runAct(basePath, args);
      break;
    case 'baseline':
      await _runBaseline(basePath, args.length > 1 ? args[1] : 'Manual Update');
      break;
    case 'takeover':
      await runTakeover(basePath, forceLast: args.contains('--force-last'));
      break;
    case 'handover':
      await runHandover(basePath, args);
      break;
    case 'health':
      await runHealthCheck(basePath, args);
      break;
    case 'seal-dna':
      await runSealDNA(basePath, args);
      break;
    case 'dashboard':
      await _runDashboard(basePath, watch: args.contains('--watch') || args.contains('-w'));
      break;
    case 'sync-tasks':
      await _runSyncTasks(basePath, args);
      break;
    case 'housekeeping':
      await _runHousekeeping(basePath);
      break;
    case 'prompt':
      await runPrompt(basePath);
      break;
    case 'pulse':
      await runPulse(basePath, args);
      break;
    case 'init':
      await runInit(basePath, args);
      break;
    case 'adopt':
      await runAdopt(basePath, args);
      break;
    case 'plan':
      await runPlan(basePath, args);
      break;
    case 'fleet-pulse':
      await runFleetPulse(basePath, args);
      break;
    case 'sync-context':
      await runSyncContext(basePath, args);
      break;
    default:
      print('Unknown command: $command');
      exit(1);
  }
}

void _printHelp() {
  print('=== [GOV] VANGUARD KERNEL v8.0.0 [DPI-GATE-GOLD] ===');
  print('Comandos Disponibles:');
  print('  help         : Muestra esta ayuda.');
  print('  status       : Estado global, SHS y tareas activas (CUS/BPI).');
  print('  pulse        : Calibra la estamina cognitiva. Use --declare <val> para forzar saturación.');
  print('  act          : Ejecuta/Sella la actividad actual.');
  print('  prompt       : Genera contexto condensado para el Agente.');
  print('  audit        : Ejecuta suite completa de integridad.');
  print('  baseline     : Certifica un hito con firma criptográfica.');
  print('  takeover     : Inicia sesión / Reclama control del búnker.');
  print('  handover     : Cierre seguro de sesión con relevo.');
  print('  init         : Inicializa un nuevo proyecto (Bootstrapping).');
  print('  adopt        : Adopta un proyecto existente (Rescue).');
  print('  plan         : Planificación de sprints y tareas.');
  print('  fleet-pulse  : Recolecta métricas agregadas de toda la flota registrada.');
  print('  health       : Certificación de coherencia del sistema.');
  print('  sync-tasks   : Sincroniza estado del backlog con task.md.');
  print('  sync-context : Sincronización atómica de telemetría (JSON).');
  print('  seal-dna     : Sella el ADN binario del motor con firma RSA del PO.');
  print('  dashboard    : Lanza telemetría visual (Terminal).');
}

// --- [COMMANDS] ---

Future<void> _runAudit(String basePath) async {
  print('=== [GOV] ATOMIC AUDIT [DPI-GATE-GOLD] ===');

  final integrity = IntegrityEngine();
  
  // S5.5: Valla Sanitaria de Sello (Blocking Baseline)
  if (!await integrity.checkStability(basePath)) {
    print('\x1B[31m[CRITICAL] BASELINE ABORTADO: No se puede sellar un búnker inestable semanticamente.\x1B[0m');
    print('[INFO] Corrija los errores de análisis (dart analyze) antes de intentar de nuevo.');
    return;
  }

  print('--- [INTEGRITY CHECK] ---');
  final cognitive = CognitiveEngine();

  final isSelfIntact = await integrity.verifySelf(toolRoot: basePath);
  if (!isSelfIntact) {
    print('[CRITICAL] SELF-AUDIT FAIL: El motor gov.dart ha sido alterado sin sello.');
  } else {
    print('[OK] Self-Audit: Motor Intacto');
  }

  final pulse = await cognitive.calculatePulse(basePath);
  await cognitive.persistPulse(basePath, pulse);

  final swelling = await integrity.checkSwelling(basePath);
  final zombies = await integrity.checkZombies(basePath);

  print('----------------------------------------');
  print('Root Density: ${swelling.fileCount} files');
  print('Root Weight:  ${(swelling.totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('Zombies:      ${zombies.length}');
  print('CUS (Context): ${pulse.context.cus.toStringAsFixed(1)}% [${pulse.context.cus < 90 ? 'NOMINAL' : 'CRITICAL'}]');
  print('BHI (Health):  ${pulse.bunker.bhi.toStringAsFixed(1)}% [${pulse.bunker.bhi < 90 ? 'SAFE' : 'DIRTY'}]');
  print('intel_pulse.json: actualizado (v8.0 Dual)');
  print('----------------------------------------');

  if (pulse.context.cus > 85 || pulse.bunker.bhi > 90) {
    print('[ALERT] Sistema en estado de fatiga o desorden extremo. Purga/Limpieza requerida.');
  }
}

Future<void> runAct(String basePath, List<String> args) async {
  print('=== [GOV] ACTIVIDAD (ACT) ===');

  // [S25-02] Incrementar contador de turnos ANTES del pre-gate
  final telemetry = TelemetryService();
  await telemetry.incrementTurns(basePath: basePath);

  // [S25-01] Pre-Gate: Verificar Saturación antes de permitir act
  final pulseData_new = await telemetry.computePulse(basePath: basePath);

  if (pulseData_new.saturation >= 80) {
    print('\x1B[31m[YIELD] Saturación al ${pulseData_new.saturation}%. Operación bloqueada por protocolo [DPI-GATE-GOLD].\x1B[0m');
    print('Ejecuta "gov handover" para sellar la sesión y liberar el núcleo.');
    exit(1);
  }

  if (pulseData_new.saturation >= 60) {
    print('\x1B[33m[WARNING] Saturación al ${pulseData_new.saturation}%. Considere un handover próximo.\x1B[0m');
  }

  final pulseFile = File(p.join(basePath, '.meta', 'session_pulse.json'));
  Map<String, dynamic> pulse = {'total_actions': 0, 'error_count': 0, 'chats': 0};

  if (pulseFile.existsSync()) {
    try { pulse = jsonDecode(pulseFile.readAsStringSync()); } catch (_) {}
  }

  // Incrementar latidos
  pulse['total_actions'] = (pulse['total_actions'] ?? 0) + 1;
  if (args.contains('--chat')) {
    pulse['chats'] = (pulse['chats'] ?? 0) + 1;
  }

  // Calcular fatiga y aplicar Guard de Saturación (Redline)
  final cognitive = CognitiveEngine();
  final pulseData = await cognitive.calculatePulse(basePath);
  await cognitive.persistPulse(basePath, pulseData);

  // [REFORMA V8.0] Bloqueo Preventivo: CUS (Contexto) es prioritario.
  if (pulseData.context.cus > 85) {
    print('\x1B[31m[CRITICAL] BLOQUEO DE SATURACIÓN: CUS Crítico (${pulseData.context.cus.toStringAsFixed(1)}%).\x1B[0m');
    print('[INFO] Operación denegada preventivamente para evitar alucinaciones.');
    print('[INFO] El contexto está agotado. Realice un Handover / Purge-Context.');
    return;
  }

  // [REFORMA V8.0] Advertencia de BHI (Salud)
  if (pulseData.bunker.bhi > 80) {
    print('\x1B[33m[WARN] ALTA PRESIÓN EN BÚNKER: BHI al ${pulseData.bunker.bhi.toStringAsFixed(1)}%.\x1B[0m');
    print('[INFO] Se recomienda "gov housekeeping" para reducir desorden estructural.');
    if (pulseData.bunker.bhi > 95) {
       print('\x1B[31m[BLOCK] BHI CRÍTICO: Limpieza obligatoria antes de proceder.\x1B[0m');
       return;
    }
  }

  // S5.5: Valla Sanitaria - Verificación tras cambio si hay fatiga moderada
  if (pulseData.context.cus > 65) {
    final integrity = IntegrityEngine();
    if (!await integrity.checkStability(basePath)) {
      print('\x1B[33m[WARN] DRIFT SEMÁNTICO: Inestabilidad detectada tras la acción.\x1B[0m');
    }
  }

  if (pulse['total_actions'] >= 25) {
    await runHandover(basePath, [], rationale: 'AUTO_SEAL_FATIGUE: Límite de 25 interacciones superado.');
    exit(1);
  }

  // Guard: Anti-Loop 3-Strikes
  if (args.contains('--error')) {
    pulse['error_count'] = (pulse['error_count'] ?? 0) + 1;
    if ((pulse['error_count'] ?? 0) >= 3) {
      print('\x1B[31m[CRITICAL-BLOCK] 3-Strikes Alcanzados. AUTO-SEALING POR DERIVA.\x1B[0m');
      pulseFile.writeAsStringSync(jsonEncode(pulse));
      await runHandover(basePath, [], rationale: 'AUTO_SEAL_DRIFT: 3 errores consecutivos detectados.');
      exit(1);
    }
  } else {
    pulse['error_count'] = 0;
  }

  // Timestamp de última acción (para Passive Tax)
  pulse['last_action_ts'] = DateTime.now().toIso8601String();
  pulseFile.writeAsStringSync(jsonEncode(pulse));

  if (pulseData.saturation >= 90) {
    print('\x1B[31m[REDLINE] SHS al ${pulseData.saturation}%. AUTO-SEALING POR AGOTAMIENTO.\x1B[0m');
    await runHandover(basePath, [], rationale: 'AUTO_SEAL_CRITICAL: Saturación SHS >= 90%.');
    exit(1);
  } else if (pulseData.saturation >= 70) {
    print('\x1B[33m[WARN] SHS al ${pulseData.saturation}%. Aproximándose al límite.\x1B[0m');
  }

  // Mostrar tarea activa
  final taskFile = File(p.join(basePath, 'task.md'));
  if (taskFile.existsSync()) {
    final lines = taskFile.readAsLinesSync();
    String activeTaskId = 'NONE';
    String activeTaskDesc = 'No se detectó tarea activa [/].';

    for (var line in lines) {
      if (line.trim().startsWith('- [/]')) {
        final idMatch = RegExp(r'(TASK-[A-Z0-9-]+)').firstMatch(line);
        if (idMatch != null) activeTaskId = idMatch.group(0)!;
        activeTaskDesc = line.replaceAll('- [/]', '').trim();
        break;
      }
    }

    if (activeTaskId == 'NONE') {
      print('\x1B[31m[WARN] No hay tarea [/] EN PROGRESO. Usa /plan para asignar meta.\x1B[0m');
    } else {
      print('Tarea Activa: $activeTaskId');
      print('Descripción:  $activeTaskDesc');

      // 🚦 [Freno de Gobernanza: Firmas de Supervisión]
      final backlogFile = File(p.join(basePath, 'backlog.json'));
      if (backlogFile.existsSync()) {
        try {
          final data = jsonDecode(backlogFile.readAsStringSync());
          final currentSprintId = data['current_sprint'] as String?;
          final isInception = currentSprintId != null && 
              (currentSprintId == 'S00-INCEPTION' || currentSprintId.contains('INCEPTION'));

          for (var sprint in data['sprints']) {
            for (var task in sprint['tasks']) {
              if (task['id'] == activeTaskId) {
                // [REFORMA V8.0: HARD-GATE]
                final label = (task['label'] as String?)?.toUpperCase() ?? 'TECH';
                if (isInception && (label == 'DEV' || label == 'UI')) {
                   final bizSig = File(p.join(basePath, '.meta', 'signatures', '${activeTaskId}.biz.ok'));
                   if (!bizSig.existsSync()) {
                     print('\x1B[31m[HARD-GATE] BLOQUEO DE INCEPTION: Las tareas $label en fase INCEPTION requieren firma BIZ.\x1B[0m');
                     print('[VANGUARD] El Product Owner debe autorizar el inicio de ejecución técnica.');
                     exit(0);
                   }
                }

                final sigs = List<String>.from(task['required_signatures'] ?? ["TECH"]);
                final humanSigs = sigs.where((s) => s != 'TECH').toList();

                if (humanSigs.isNotEmpty) {
                  print('[INFO] Esta tarea requiere supervisión Humana: ${humanSigs.join(", ")}');
                  for (var role in humanSigs) {
                    final sigFile = File(p.join(basePath, '.meta', 'signatures', '${activeTaskId}.${role.toLowerCase()}.ok'));
                    if (!sigFile.existsSync()) {
                      print('\x1B[33m[YIELD] Bloqueo por falta de firma: $role\x1B[0m');
                      print('La fábrica debe detenerse. Ejecute "gov baseline" para que el Humano certifique la tarea.');
                      exit(0);
                    }
                  }
                  print('\x1B[32m[OK] Todas las firmas humanas verificadas.\x1B[0m');
                }
              }
            }
          }
        } catch (e) {
          print('[ERROR] Orquestación de Gobernanza fallida: $e');
        }
      }
    }
  }

  print('SHS: ${pulseData.saturation}% | Latidos: ${pulse['total_actions']}/25 | Acción registrada.');
}

Future<void> runPrompt(String basePath) async {
  // Leer métricas actuales primero
  final cognitive = CognitiveEngine();
  final pulseData = await cognitive.calculatePulse(basePath);
  await cognitive.persistPulse(basePath, pulseData);

  print('<context_snapshot>');
  print('### SHS_STATUS:');
  print('  Saturation: ${pulseData.saturation}% | CP: ${pulseData.cp}');
  print('  Tools: ${pulseData.detail['tools']} | Chats: ${pulseData.detail['chats']} | Zombies: ${pulseData.zombieCount}');
  final shs = pulseData.saturation;
  if (shs >= 90) {
    print('  [HARD-STOP] Sistema en Redline. Handover obligatorio.');
  } else if (shs >= 70) {
    print('  [WARN] Fatiga elevada. Planificar handover pronto.');
  } else {
    print('  [OK] Sistema nominal.');
  }
  final vision = File(p.join(basePath, 'VISION.md'));
  if (vision.existsSync()) {
    print('### VISION_SSOT (Primeras 20 líneas):');
    final lines = vision.readAsLinesSync();
    lines.take(20).forEach(print);
  }

  final gemini = File(p.join(basePath, 'GEMINI.md'));
  if (gemini.existsSync()) {
    print('\n### REGLAS_CRITICAS (SSoT):');
    print(gemini.readAsStringSync());
  }

  final taskFile = File(p.join(basePath, 'task.md'));
  if (taskFile.existsSync()) {
    final lines = taskFile.readAsLinesSync();
    for (var line in lines) {
      if (line.trim().startsWith('- [/]')) {
        final idMatch = RegExp(r'(TASK-[^\s\]]+)').firstMatch(line);
        if (idMatch != null) {
          final taskId = idMatch.group(0);
          final sprintMatch = RegExp(r'S(\d+)').firstMatch(lines.first);
          final sprint = sprintMatch != null ? 'S${sprintMatch.group(1)}' : 'ACTIVE';
          final refPath = p.join(basePath, '.meta', 'sprints', sprint, '$taskId.md');
          final refFile = File(refPath);
          if (refFile.existsSync()) {
            print('\n### INSTRUCCIONES_TAREA ($taskId):');
            print(refFile.readAsStringSync());
          }
        }
        break;
      }
    }
  }
  print('</context_snapshot>');
}

Future<void> runHealthCheck(String basePath, List<String> args) async {
  print('=== [GOV] HEALTH CHECK (Auditoría Integral) ===');
  await _runAudit(basePath);
  
  print('\n[1/2] Ejecutando Flutter Analyze...');
  final analyze = await Process.run('flutter', ['analyze'], runInShell: true);
  if (analyze.stdout.toString().contains('error •')) {
    print('\x1B[31m[CRITICAL] Errores encontrados en análisis estático.\x1B[0m');
    print(analyze.stdout);
    exit(1);
  }
  print('\x1B[32m[OK] Análisis estático nominal.\x1B[0m');

  if (args.contains('--test')) {
    print('\n[2/2] Ejecutando Tests Unitarios (Bajo Demanda)...');
    final test = await Process.run('flutter', ['test'], runInShell: true);
    if (test.exitCode != 0) {
      print('\x1B[31m[CRITICAL] Fallo en la suite de tests unitarios.\x1B[0m');
      print(test.stdout);
      exit(1);
    }
    print('\x1B[32m[OK] Batería de tests superada.\x1B[0m');
  } else {
    print('\n[INFO] Salto de Tests Unitarios (Usa --test para ejecutarlos).');
  }
}

Future<void> _runDashboard(String basePath, {bool watch = false}) async {
  final now = DateTime.now().toLocal();
  final cognitive = CognitiveEngine();
  final integrity = IntegrityEngine();

  if (watch) {
    print('\x1B[2J\x1B[H'); // Clear screen
    print('Entrando en modo interactivo [DPI-WATCH]...');
    
    // Bucle de actualización
    while (true) {
      final pulse = await cognitive.calculatePulse(basePath);
      final swelling = await integrity.checkSwelling(basePath);
      final backlogStr = await _getRichContext(basePath);
      
      _printTermHUD(pulse, swelling, backlogStr);
      
      print('\n  Presione Ctrl+C para salir | Actualizado: ${DateTime.now().toLocal().toString().split(' ').last.split('.').first}');
      
      await Future.delayed(const Duration(seconds: 2));
      stdout.write('\x1B[H'); // Volver al inicio sin borrar (reduce parpadeo)
    }
  }

  // Comportamiento por defecto: Generar DASHBOARD.md
  print('=== [GOV] DASHBOARD REGENERATOR v8.0 ===');
  final swelling = await integrity.checkSwelling(basePath);
  final sizeMB = swelling.totalBytes / (1024 * 1024);
  final chatUuid = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'UNKNOWN';
  final pulse = await cognitive.calculatePulse(basePath);
  final cus = pulse.context.cus;
  final bhi = pulse.bunker.bhi;
  
  final cusStatus = cus < 70 ? '✅ NOMINAL' : (cus < 85 ? '⚠️ FATIGA' : '🛑 REDLINE');
  final bhiStatus = bhi < 70 ? '✅ SAFE' : (bhi < 90 ? '⚠️ DIRTY' : '🛑 CRITICAL');

  final content = '''
# 🛡️ VANGUARD HUD: Centro de Mando v8.0.0 [DPI-GATE-GOLD]
> **Sesión Activa:** `$chatUuid`

| Métrica | Valor | Estado | Dominio |
| :--- | :--- | :--- | :--- |
| **Context (CUS)** | ${cus.toStringAsFixed(1)}% | $cusStatus | 🧠 Cognitivo |
| **Bunker (BHI)**  | ${bhi.toStringAsFixed(1)}% | $bhiStatus | 🧪 Estructural |
| **Root Density**| ${swelling.fileCount} f | ${swelling.fileCount < IntegrityEngine.kMaxRootFiles ? '✅ OK' : '⚠️ SWELL'} | 🏗️ Arquitectura |
| **Root Weight** | ${sizeMB.toStringAsFixed(2)} MB | ${sizeMB < 9.0 ? '✅ OK' : '⚠️ PESADO'} | 💾 Almacenaje |
| **Zombies** | ${pulse.bunker.zombies} | ${pulse.bunker.zombies == 0 ? '✅ LIMPIO' : '🛑 INFECTADO'} | 🧪 Higiene |

---
*Ultima Actualización: $now*
*Protocolo: DUAL_ENGINE_REFORM | V8_CERTIFIED*
''';

  const dashboardFilename = 'DASHBOARD.md';
  const dashboardPath = 'docs';
  final destDir = Directory(p.join(basePath, dashboardPath));
  if (!destDir.existsSync()) destDir.createSync(recursive: true);

  await File(p.join(destDir.path, dashboardFilename)).writeAsString(content);
  print('[SUCCESS] ${p.join(dashboardPath, dashboardFilename)} actualizado con métricas v8.0.');
}

void _printTermHUD(DualPulseData pulse, dynamic swelling, String contextLine) {
  final cus = pulse.context.cus;
  final bhi = pulse.bunker.bhi;
  final chatUuid = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL-SESSION';
  final sizeMB = swelling.totalBytes / (1024 * 1024);

  String _bar(double val, Colors c) {
    const int width = 15;
    final int filled = (val / 100 * width).clamp(0, width).toInt();
    final String colorCode = c == Colors.red ? '\x1B[31m' : (c == Colors.orange ? '\x1B[33m' : (c == Colors.cyan ? '\x1B[36m' : '\x1B[32m'));
    return '$colorCode${'█' * filled}${'\x1B[0m\x1B[2m'}${ '░' * (width - filled)}\x1B[0m';
  }

  String _status(double val, {bool isBhi = false}) {
    if (val < 70) return isBhi ? '\x1B[32mSAFE\x1B[0m' : '\x1B[36mNOMINAL\x1B[0m';
    if (val < 85) return '\x1B[33mFATIGA\x1B[0m';
    return '\x1B[31mREDLINE\x1B[0m';
  }

  print('\x1B[1m┌──────────────────────────────────────────────────────────┐\x1B[0m');
  print('\x1B[1m│ \x1B[35mVANGUARD HUD\x1B[0m [DPI-GATE-GOLD] v8.1.0-DEBT                 │');
  print('\x1B[1m├──────────────────────────────────────────────────────────┤\x1B[0m');
  print('│ \x1B[2mSESSION:\x1B[0m ${chatUuid.take(12)}... | \x1B[2mSTRAT:\x1B[0m KERNEL-8.1     │');
  print('│ \x1B[2mCONTEXT:\x1B[0m ${contextLine.take(48).padRight(48)} │');
  print('\x1B[1m├──────────────────────────────────────────────────────────┤\x1B[0m');
  print('│ [BHI] BÚNKER   [${_bar(bhi, bhi < 70 ? Colors.green : (bhi < 90 ? Colors.orange : Colors.red))}] ${bhi.toStringAsFixed(1)}% (${_status(bhi, isBhi: true)})     │');
  print('│ [CUS] CONTEXTO [${_bar(cus, cus < 70 ? Colors.cyan : (cus < 85 ? Colors.orange : Colors.red))}] ${cus.toStringAsFixed(1)}% (${_status(cus)})   │');
  print('\x1B[1m├──────────────────────────────────────────────────────────┤\x1B[0m');
  print('│ FILES: ${swelling.fileCount.toString().padRight(2)} | SIZE: ${sizeMB.toStringAsFixed(2).padRight(4)} MB | ZOMBIES: ${pulse.bunker.zombies.toString().padRight(2)}            │');
  print('│ DRIFT: ${pulse.saturation < 85 ? '\x1B[32m✅ OPTIMAL\x1B[0m' : '\x1B[31m🛑 UNSTABLE\x1B[0m'} | CPU_TAX: ${(pulse.saturation / 40).toStringAsFixed(1)}%                        │');
  print('\x1B[1m└──────────────────────────────────────────────────────────┘\x1B[0m');
}

extension StringExt on String {
  String take(int n) => length <= n ? this : substring(0, n);
}

// Dummy Colors for CLI logic
enum Colors { green, cyan, orange, red }

Future<String> _getRichContext(String basePath) async {
  final bFile = File(p.join(basePath, 'backlog.json'));
  if (!bFile.existsSync()) return 'Estado Manual';
  try {
    final data = jsonDecode(bFile.readAsStringSync());
    final List<dynamic> sprints = data['sprints'] ?? [];
    final activeSprint = sprints.firstWhere((s) => s['status'] == 'IN_PROGRESS', orElse: () => null);
    if (activeSprint == null) return 'Fuera de Sprint';
    
    final List<dynamic> tasks = activeSprint['tasks'] ?? [];
    final activeTask = tasks.firstWhere((t) => t['status'] == 'IN_PROGRESS', orElse: () => null);
    
    final sprintId = activeSprint['id'] ?? 'S-UNK';
    final taskId = activeTask != null ? activeTask['id'] : 'SIN TAREA';
    final taskDesc = activeTask != null ? (activeTask['desc'] ?? activeTask['title'] ?? '') : '';
    
    return '$sprintId / $taskId: $taskDesc';
  } catch (_) {
    return 'Contexto Indefinido';
  }
}

Future<void> _runBaseline(String basePath, String message) async {
  print('=== [GOV] SELLO DE CALIDAD ESTRATÉGICO ===');

  // [S25-02] Un baseline también cuenta como interacción significativa
  final telemetry = TelemetryService();
  await telemetry.incrementTurns(basePath: basePath);
  
  final vanguard = VanguardCore();
  final publicKeyFile = File(p.join(basePath, 'vault', 'intel', 'guard_pub.xml'));
  
  if (!publicKeyFile.existsSync()) {
    print('[ERROR] No se encontró guard_pub.xml. El sistema no puede verificar tu identidad.');
    exit(1);
  }

  final publicKeyXml = await publicKeyFile.readAsString();
  
  await _generateImpactSummary(basePath, message);

  final richContext = await _getRichContext(basePath);
  final fullDesc = 'SELLO DE CALIDAD: $richContext';

  final challengeId = await vanguard.issueChallenge(
    level: 'STRATEGIC-GOLD',
    project: 'Base2-Kernel',
    description: fullDesc,
    basePath: basePath,
    files: [], // El sello estratégico usa un manifiesto implícito en el nivel GOLD
  );

  print('[VANGUARD] Desafío generado: $challengeId');
  print('[VANGUARD] Esperando firma en Vanguard Agent...');

  final isSigned = await vanguard.waitForSignature(
    basePath: basePath,
    challenge: challengeId,
    publicKeyXml: publicKeyXml,
    timeoutSeconds: 60,
  );

  if (!isSigned) {
    print('[CRITICAL] Baseline ABORTADO: Firma RSA inválida o tiempo de espera agotado.');
    exit(1);
  }

  print('[OK] Firma RSA Verificada. Sellando integridad...');
  
  final finalMessage = message == 'Manual Update' ? richContext : '$richContext | $message';

  final log = File(p.join(basePath, 'PROJECT_LOG.md'));
  final timestamp = DateTime.now().toIso8601String();
  await log.writeAsString('\n- [$timestamp] [SELLADO] $finalMessage (Signed by PO)', mode: FileMode.append);

  print('[SUCCESS] Sello de Calidad consolidado y registrado cryptográficamente.');
  
  final ledger = ForensicLedger();
  await ledger.appendEntry(
    sessionId: 'S24-GOLD',
    type: 'BASE',
    task: 'Sello de Calidad',
    detail: finalMessage,
    basePath: basePath,
    role: 'PO',
  );

  await _triggerDashboardSync(basePath);

  // [DPI-BASELINE-CONTEXT] Bitácora de Conocimiento Incremental
  final cognitive = CognitiveEngine();
  final pulse = await cognitive.calculatePulse(basePath);
  final memoFile = File(p.join(basePath, 'vault', 'intel', 'BASELINE_MEMO.md'));
  final memoTitle = message == 'Manual Update' ? 'Sello Manual' : message;
  final now = DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ');
  
  String memoEntry = '''

## [$now] - $memoTitle
> [!IMPORTANT]
> **Puntos por Resolver / Pendientes**:
> - [ ] Sincronizar tareas huérfanas en el próximo ciclo.
> - [ ] Validar integridad de los últimos cambios binarios.
> - [ ] [REGISTRO MANUAL] Pendientes operativos detectados.

> [!NOTE]
> **Estado de Salud de la Base**:
> - Saturación SHS: ${pulse.saturation}%
> - Carga de Metadatos: ${pulse.detail['context_load'] ?? 'N/A'}
''';

  if (memoFile.existsSync()) {
    await memoFile.writeAsString(memoEntry, mode: FileMode.append);
  } else {
    await memoFile.writeAsString('# VANGUARD: BITÁCORA DE CONOCIMIENTO INCREMENTAL\n$memoEntry');
  }
}

Future<void> _generateImpactSummary(String basePath, String message) async {
  final root = Directory(basePath);
  final changedFiles = <String>[];
  // Simulación: Archivos modificados en raíz (sin .git o .meta)
  for (var f in root.listSync().whereType<File>()) {
    final name = p.basename(f.path);
    if (!name.startsWith('.') && name != 'backlog.json') {
       changedFiles.add(name);
    }
  }

  final summary = {
    'action': 'BASELINE',
    'message': message,
    'affected_files': changedFiles.take(5).toList(),
    'file_count': changedFiles.length,
    'timestamp': DateTime.now().toIso8601String(),
  };

  await File(p.join(basePath, 'vault', 'intel', 'impact_summary.json')).writeAsString(jsonEncode(summary));
}

Future<void> _printStatus(String basePath, {bool jsonOutput = false}) async {
  final Map<String, dynamic> status = {};
  final backlogFile = File(p.join(basePath, 'backlog.json'));
  if (backlogFile.existsSync()) {
    final data = jsonDecode(await backlogFile.readAsStringSync());
    status['project'] = data['project'];
    status['version'] = data['version'];
    final List<dynamic> sprints = (data['sprints'] as List<dynamic>?) ?? [];
    String sprintStr = 'TBD';
    if (sprints.isNotEmpty) {
      final active = sprints.firstWhere((s) => s['status'] == 'IN_PROGRESS', orElse: () => null);
      if (active != null) {
        sprintStr = active['id'];
      } else {
        final pending = sprints.firstWhere((s) => s['status'] == 'PENDING', orElse: () => null);
        sprintStr = pending != null ? pending['id'] : sprints.last['id'];
      }
    }
    status['sprint'] = sprintStr;
  }

  final intelPulse = File(p.join(basePath, 'vault', 'intel', 'intel_pulse.json'));
  if (intelPulse.existsSync()) {
    try {
      final data = jsonDecode(intelPulse.readAsStringSync());
      status['cus'] = data['context']['cus'];
      status['bpi'] = data['hygiene']['bpi'];
      status['tokens'] = data['context']['tokens'];
      status['zombies'] = data['hygiene']['zombies'];
      status['chat_uuid'] = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'UNKNOWN-SESSION';
    } catch (_) {}
  }

  if (jsonOutput) {
    print(jsonEncode(status));
  } else {
    print('=== [GOV] SYSTEM STATUS v8.0.0 ===');
    print('Project: ${status['project']} | v${status['version']}');
    print('Sprint:  ${status['sprint']}');
    print('Context (CUS): ${status['cus']?.toStringAsFixed(1)}% | Tokens: ~${status['tokens']}');
    print('Hygiene (BPI): ${status['bpi']?.toStringAsFixed(1)}% | Zombies: ${status['zombies']}');
    print('Session ID: ${status['chat_uuid']}');
  }
}

Future<void> runSyncContext(String basePath, List<String> args) async {
  final Map<String, dynamic> result = {
    'timestamp': DateTime.now().toIso8601String(),
    'session': {
      'locked': File(p.join(basePath, '.meta', 'SESSION_LOCKED')).existsSync(),
      'chat_uuid': Platform.environment['VANGUARD_CHAT_UUID'] ?? 'UNKNOWN',
    },
    'health': {},
    'project': {},
    'task_reference': null,
  };

  // 1. Salud Dual (CUS / BPI)
  try {
    final cognitive = CognitiveEngine();
    final pulse = await cognitive.calculatePulse(basePath);
    result['health'] = pulse.toJson();
  } catch (e) {
    result['errors'] ??= [];
    result['errors'].add('Health Check Fail: $e');
  }

  // 2. Backlog Status
  final backlogFile = File(p.join(basePath, 'backlog.json'));
  if (backlogFile.existsSync()) {
    try {
      final data = jsonDecode(backlogFile.readAsStringSync());
      result['project'] = {
        'name': data['project'],
        'version': data['version'],
        'current_sprint': data['current_sprint'],
        'current_task': data['current_task'],
      };
    } catch (_) {}
  }

  // 3. Task.md Snapshot
  final taskFile = File(p.join(basePath, 'task.md'));
  if (taskFile.existsSync()) {
    result['task_md'] = taskFile.readAsStringSync();
  }

  // 4. Relay Metadata
  final relayFile = File(p.join(basePath, 'vault', 'intel', 'SESSION_RELAY.json'));
  if (relayFile.existsSync()) {
    try {
      result['relay'] = jsonDecode(relayFile.readAsStringSync());
    } catch (_) {}
  }

  // Output Atómico
  print(JsonEncoder.withIndent('  ').convert(result));
}

Future<void> runTakeover(String basePath, {bool forceLast = false}) async {
  print('=== [GOV] SESSION TAKEOVER ===');
  final lockFile = File(p.join(basePath, '.meta', 'SESSION_LOCKED'));
  final bool wasClean = lockFile.existsSync();
  
  if (wasClean) {
    lockFile.deleteSync();
  } else {
    print('\x1B[31m[CRITICAL-RECOVERY] Detectado cierre sucio (Crash). Reconstruyendo estado...\x1B[0m');
  }
  
  final sessionLock = File(p.join(basePath, '.meta', 'session.lock'));
  String? lastChatUuid;
  if (sessionLock.existsSync()) {
    try {
      final data = jsonDecode(sessionLock.readAsStringSync());
      lastChatUuid = data['chat_uuid']?.toString(); // S24-GOLD: Forzado de String
    } catch (_) {}
  }

  // Identificar sesión de Chat (Vanguard Engine)
  String currentChatUuid = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL-SESSION';
  
  // S24-GOLD: Soporte para --force-last para automatizar el relevo
  if (forceLast && lastChatUuid != null && currentChatUuid == 'MANUAL-SESSION') {
    print('[AUTO] Relevo forzado vía --force-last detectado. Usando ID anterior: $lastChatUuid');
    currentChatUuid = lastChatUuid;
  }

  bool isRecursive = (lastChatUuid != null && lastChatUuid == currentChatUuid);

  final pulseFile = File(p.join(basePath, '.meta', 'session_pulse.json'));
  if (isRecursive) {
    print('\x1B[33m[WARN] RECURSIVIDAD DETECTADA: El Chat-UUID coincide con el de la sesión sellada.\x1B[0m');
    print('\x1B[33m[INFO] Desbloqueando sesión, pero manteniendo fatiga SHS por continuidad cognitiva.\x1B[0m');
  } else {
    print('\x1B[32m[OK] Relevo Certificado: Chat-UUID único. Reseteando reloj de fatiga.\x1B[0m');
    if (pulseFile.existsSync()) {
       // [TASK-DPI-126-11] Atomic Wipe: No heredar ninguna métrica de sesiones anteriores.
       await pulseFile.delete();
       print('\x1B[32m[OK] Purga Atómica: Historial de fatiga eliminado para nueva sesión.\x1B[0m');
    }

    // [DPI-BASELINE-CONTEXT] Presentar Briefing del último Baseline
    final memoFile = File(p.join(basePath, 'vault', 'intel', 'BASELINE_MEMO.md'));
    if (memoFile.existsSync()) {
      final content = memoFile.readAsStringSync();
      final sections = content.split('\n## [');
      if (sections.length > 1) {
        print('\n\x1B[35m=== [VANGUARD] BRIEFING DE ÚLTIMA BASE DE CONFIANZA ===\x1B[0m');
        print('## [${sections.last}');
      }
    }
  }

  // Reset de Reloj de Fatiga (Time Tax Barrier)
  final now = DateTime.now().toLocal().toString().substring(0, 19);
  final runUuid = 'RUN-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  sessionLock.writeAsStringSync(jsonEncode({
    'uuid': runUuid,
    'chat_uuid': currentChatUuid,
    'timestamp': now,
    'last_action': now,
  }));
  
  await _runAudit(basePath);
  print('[OK] Sesión iniciada y sincronizada.');
}

Future<void> runHandover(String basePath, List<String> args, {String? rationale}) async {
  print('=== [GOV] SESSION HANDOVER ===');
  
  bool isForced = args.contains('--force');
  
  if (isForced) {
    print('\x1B[33m[AUTHORITY] Solicitud de CIERRE FORZADO detectada.\x1B[0m');
    print('[VANGUARD] Requiere firma de Nivel PO para autorizar acción forzada.');
    
    final vanguard = VanguardCore();
    final publicKeyFile = File(p.join(basePath, 'vault', 'intel', 'guard_pub.xml'));
    
    if (!publicKeyFile.existsSync()) {
      print('[ERROR] No se encontró guard_pub.xml. No se puede verificar autoridad.');
      exit(1);
    }
    
    final publicKeyXml = await publicKeyFile.readAsString();
    final challengeId = await vanguard.issueChallenge(
      level: 'AUTHORITY-PO',
      project: 'Base2-Kernel',
      description: 'CIERRE FORZADO: El PO solicita el sellado inmediato de la sesión ignorando bloqueos de higiene.',
      basePath: basePath,
      files: [], // Purgado forzado no requiere lista de integridad previa
    );

    print('[VANGUARD] Desafío generado: $challengeId');
    final isSigned = await vanguard.waitForSignature(
      basePath: basePath,
      challenge: challengeId,
      publicKeyXml: publicKeyXml,
      timeoutSeconds: 60,
    );

    if (!isSigned) {
      print('[CRITICAL] Cierre Forzado ABORTADO: Firma inválida o tiempo agotado.');
      exit(1);
    }
    
    print('[OK] Firma PO Verificada. Procediendo con Sello Forzado...');
    final log = File(p.join(basePath, 'PROJECT_LOG.md'));
    await log.writeAsString('\n- [${DateTime.now().toIso8601String()}] [FORCED_SEAL] Cierre por autoridad PO. (Signed by PO)', mode: FileMode.append);
    
    final ledger = ForensicLedger();
    await ledger.appendEntry(
      sessionId: 'S24-GOLD',
      type: 'FORCE',
      task: 'Cierre Forzado',
      detail: 'Sello de sesión forzado por el PO mediante Vanguard.',
      basePath: basePath,
      role: 'PO',
    );
  } else if (rationale != null) {
    print('\x1B[35m[AUTO-SEAL] Iniciando cierre automático por seguridad...\x1B[0m');
    final log = File(p.join(basePath, 'PROJECT_LOG.md'));
    await log.writeAsString('\n- [${DateTime.now().toIso8601String()}] [AUTO_SEAL] $rationale', mode: FileMode.append);
    
    final ledger = ForensicLedger();
    await ledger.appendEntry(
      sessionId: 'S24-GOLD',
      type: 'AUTO',
      task: 'Auto-Seal',
      detail: rationale,
      basePath: basePath,
      role: 'KERNEL',
    );
  } else {
    // [SMART-HANDOVER] Intento de Baseline Automático por cambios
    final gitStatus = await Process.run('git', ['status', '--short'], runInShell: true);
    final hasChanges = (gitStatus.stdout as String).trim().isNotEmpty;
    
    if (hasChanges) {
      final cognitive = CognitiveEngine();
      try {
        final pulse = await cognitive.calculatePulse(basePath);
        if (pulse.saturation < 90) {
          print('\x1B[35m[SMART-RELAY] Detectados cambios pendientes. Intentando Sello de Relevo...\x1B[0m');
          await _runBaseline(basePath, "Handover Seal: Cierre de jornada con cambios.");
        } else {
          print('\x1B[33m[WARN] Búnker sobrecalentado (${pulse.saturation}%). Sello estratégico pospuesto.\x1B[0m');
        }
      } catch (_) {
        print('\x1B[31m[ERROR] No se pudo validar pulso. Saltando sello automático.\x1B[0m');
      }
    }

    // Handover Estándar: Auditar antes de cerrar
    await _runAudit(basePath);
  }
  
  final lockDir = Directory(p.join(basePath, '.meta'));
  if (!lockDir.existsSync()) lockDir.createSync(recursive: true);
  
  // [STAMINA-V2] Hibernación en candado
  final sessionLock = File(p.join(basePath, '.meta', 'session.lock'));
  if (sessionLock.existsSync()) {
    try {
      final lockData = jsonDecode(sessionLock.readAsStringSync());
      final pulseFile = File(p.join(basePath, '.meta', 'session_pulse.json'));
      if (pulseFile.existsSync()) {
        final pulseData = jsonDecode(pulseFile.readAsStringSync());
        lockData['hibernation_minutes'] = pulseData['active_minutes'] ?? 1.0;
        sessionLock.writeAsStringSync(jsonEncode(lockData));
        print('[OK] Minutos activos hibernados para el próximo relevo.');
      }
    } catch (_) {}
  }

  // [S25-02] Reset de contadores volátiles al cierre de sesión
  final telemetry = TelemetryService();
  await telemetry.resetCounters(basePath: basePath);

  File(p.join(basePath, '.meta', 'SESSION_LOCKED')).createSync();
  print('[OK] Sesión cerrada. Relevo criogénico activado.');
}

// --- [GOV v8.0: MOTOR DUAL] ---

class ContextState {
  final double cus; // Context Utilization Score (0-100)
  final int tokens;
  final int turns;
  final Map<String, dynamic> detail;

  ContextState({
    required this.cus,
    required this.tokens,
    required this.turns,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'cus': cus,
    'tokens': tokens,
    'turns': turns,
    'detail': detail,
  };
}

class BunkerHealthState {
  final double bhi; // Bunker Health Index (0-100)
  final int zombies;
  final int density;
  final Map<String, dynamic> detail;

  BunkerHealthState({
    required this.bhi,
    required this.zombies,
    required this.density,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'bhi': bhi,
    'zombies': zombies,
    'density': density,
    'detail': detail,
  };
}

class DualPulseData {
  final ContextState context;
  final BunkerHealthState bunker;
  final String timestamp;
  final String sessionUuid;

  DualPulseData({
    required this.context,
    required this.bunker,
    required this.timestamp,
    required this.sessionUuid,
  });

  Map<String, dynamic> toJson() => {
    'context': context.toJson(),
    'hygiene': bunker.toJson(),
    'timestamp': timestamp,
    'session_uuid': sessionUuid,
    // [COMPATIBILIDAD V7]
    'shs_pulse': max(context.cus, bunker.bhi).round(),
    'cp_fatigue': context.cus, 
    'saturation': max(context.cus, bunker.bhi).round(),
    'zombies': bunker.zombies,
  };

  // Getters de compatibilidad para evitar fallos de compilación en logic legacy
  int get saturation => max(context.cus, bunker.bhi).round();
  double get cp => context.cus;
  Map<String, dynamic> get detail => context.detail;
  int get zombieCount => bunker.zombies;
}

class ContextEngine {
  Future<ContextState> calculateCUS(String basePath) async {
    final pulseFile = File(p.join(basePath, '.meta', 'session_pulse.json'));
    Map<String, dynamic> pulse = {'total_actions': 0, 'chats': 0};
    if (pulseFile.existsSync()) {
      try { pulse = jsonDecode(pulseFile.readAsStringSync()); } catch (_) {}
    }

    int trueAiTurns = 0;
    int trueChatTurns = 0;
    double toolCpValue = 0;

    // 1. Crawler de Logs (Vanguard Sync)
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      final currentChatUuid = Platform.environment['VANGUARD_CHAT_UUID'];
      if (userProfile != null && currentChatUuid != null) {
        final brainDir = Directory(p.join(userProfile, '.gemini', 'antigravity', 'brain', currentChatUuid));
        final overviewFile = File(p.join(brainDir.path, '.system_generated', 'logs', 'overview.txt'));
        if (overviewFile.existsSync()) {
          final content = overviewFile.readAsStringSync();
          final lines = content.split('\n');
          for (final line in lines) {
            if (line.contains('call:')) {
              trueAiTurns++;
              if (line.contains('replace_file_content') || line.contains('write_to_file') || line.contains('multi_replace')) {
                toolCpValue += 2.0;
              } else if (line.contains('run_command') || line.contains('search_web')) {
                toolCpValue += 1.5;
              } else {
                toolCpValue += 0.5;
              }
            } else if (line.trim().isNotEmpty) {
              trueChatTurns++;
            }
          }
        }
      }
    } catch (_) {
      toolCpValue = (pulse['total_actions'] ?? 0) * 1.2;
      trueChatTurns = pulse['chats'] ?? 0;
    }

    // 2. Tokenizer Agile (Words * 1.3 - Vanguard v8.0 Standard)
    int estimatedTokens = (toolCpValue * 300).toInt(); // Estimación interna por carga de herramienta

    // 3. Protocolo de Amnistía (No hay alivio temporal ni estratégico para el contexto)
    final double finalCus = (toolCpValue + (trueChatTurns * 0.5)).clamp(0.0, 100.0);

    return ContextState(
      cus: finalCus,
      tokens: estimatedTokens,
      turns: trueAiTurns + trueChatTurns,
      detail: {
        'tool_load': toolCpValue,
        'chat_load': trueChatTurns * 0.5,
        'ai_turns': trueAiTurns,
        'chat_turns': trueChatTurns,
      },
    );
  }
}

class BunkerHealthEngine {
  Future<BunkerHealthState> calculateBHI(String basePath) async {
    final integrity = IntegrityEngine();
    final swelling = await integrity.checkSwelling(basePath);
    final zombies = await integrity.checkZombies(basePath);

    // Métrica de Densidad (Relación con el búnker inmortal)
    final double densityScore = (swelling.fileCount / IntegrityEngine.kMaxRootFiles) * 50;
    final double zombieScore = (zombies.length * 5.0); // 1 zombie = 5% de presión

    final double finalBhi = (densityScore + zombieScore).clamp(0.0, 100.0);

    return BunkerHealthState(
      bhi: finalBhi,
      zombies: zombies.length,
      density: swelling.fileCount,
      detail: {
        'root_files': swelling.fileCount,
        'root_bytes': swelling.totalBytes,
        'zombie_list': zombies.take(5).toList(),
      },
    );
  }
}

class CognitiveEngine {
  // Bridge para compatibilidad con el resto del orquestador durante migración
  Future<DualPulseData> calculatePulse(String basePath) async {
    final context = await ContextEngine().calculateCUS(basePath);
    final bunker = await BunkerHealthEngine().calculateBHI(basePath);

    return DualPulseData(
      context: context,
      bunker: bunker,
      timestamp: DateTime.now().toIso8601String(),
      sessionUuid: Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL-SESSION',
    );
  }

  Future<void> persistPulse(String basePath, DualPulseData data) async {
    final intelPulse = File(p.join(basePath, 'vault', 'intel', 'intel_pulse.json'));
    if (!intelPulse.parent.existsSync()) intelPulse.parent.createSync(recursive: true);
    await intelPulse.writeAsString(jsonEncode(data.toJson()));
  }

  Future<bool> checkDrift(String basePath) async {
    final taskFile = File(p.join(basePath, 'task.md'));
    final backlogFile = File(p.join(basePath, 'backlog.json'));
    if (!taskFile.existsSync() || !backlogFile.existsSync()) return false;

    try {
      final taskContent = taskFile.readAsStringSync();
      final backlog = jsonDecode(backlogFile.readAsStringSync());
      
      final taskRegex = RegExp(r'-\s+\[[xX]\]\s+.*(TASK-[A-Z0-9-]+)');
      final doneInTask = taskRegex.allMatches(taskContent).map((m) => m.group(1)).toSet();

      for (var sprint in backlog['sprints']) {
        if (sprint['status'] == 'IN_PROGRESS') {
           for (var task in sprint['tasks']) {
              if (doneInTask.contains(task['id']) && task['status'] != 'DONE') {
                 return true; 
              }
           }
        }
      }
    } catch (_) {}
    return false;
  }
}

Future<void> _runSyncTasks(String basePath, List<String> args) async {
  print('=== [GOV] SYNC-TASKS (QA Hard-Gate) ===');
  final taskFile = File(p.join(basePath, 'task.md'));
  if (!taskFile.existsSync()) {
    print('[ERROR] No se encuentra task.md');
    return;
  }

  // 1. Identificar tareas completadas en task.md
  final lines = taskFile.readAsLinesSync();
  final doneTaskIds = <String>{};
  final taskRegex = RegExp(r'-\s+\[[xX]\]\s+.*(TASK-[A-Z0-9-]+)');
  for (var line in lines) {
    final match = taskRegex.firstMatch(line);
    if (match != null) {
      doneTaskIds.add(match.group(1)!);
    }
  }

  if (doneTaskIds.isEmpty) {
    print('[INFO] No se detectaron tareas finalizadas [x] en task.md.');
    return;
  }

  print('[QA] Tareas detectadas para sincronización: ${doneTaskIds.join(", ")}');

  // 1b. Hard-Gate: Higiene Operacional (S119-BUNKER)
  final integrityCheck = IntegrityEngine();
  final cognitiveCheck = CognitiveEngine();
  final zombiesOnGate = await integrityCheck.checkZombies(basePath);
  final pulseOnGate = await cognitiveCheck.calculatePulse(basePath);

  if (pulseOnGate.bunker.zombies > 0) {
    print('\x1B[31m[CRITICAL-GATE] Sincronización bloqueada: Se detectaron ${pulseOnGate.bunker.zombies} zombies en la raíz.\x1B[0m');
    print('Ejecuta "gov housekeeping" antes de intentar sincronizar.');
    exit(1);
  }

  if (pulseOnGate.context.cus >= 90 || pulseOnGate.bunker.bhi >= 90) {
    print('\x1B[31m[CRITICAL-GATE] Sincronización bloqueada: Salud insuficiente (CUS: ${pulseOnGate.context.cus} | BHI: ${pulseOnGate.bunker.bhi}).\x1B[0m');
    print('El sistema requiere saneamiento / purga antes del sello.');
    exit(1);
  }

  print('\x1B[32m[OK] Higiene verificada. Lanzando batería de pruebas automáticas...\x1B[0m');
  final result = await Process.run('flutter', ['test'], runInShell: true);
  if (result.exitCode != 0) {
    print('\x1B[31m[CRITICAL-QA] Fallo en las pruebas. Sincronización ABORTADA.\x1B[0m');
    print(result.stdout);
    exit(1);
  }
  print('\x1B[32m[OK] Pruebas superadas. Procediendo a sincronizar backlog...\x1B[0m');

  // 3. Actualizar backlog.json
  final backlogFile = File(p.join(basePath, 'backlog.json'));
  final data = jsonDecode(backlogFile.readAsStringSync());
  int updatedCount = 0;
  for (var sprint in data['sprints']) {
    for (var task in sprint['tasks']) {
      if (doneTaskIds.contains(task['id']) && task['status'] != 'DONE') {
        task['status'] = 'DONE';
        updatedCount++;
      }
    }
  }

  // 4. Auto-completar sprints
  for (var sprint in data['sprints']) {
    if (sprint['status'] == 'IN_PROGRESS') {
      final allDone = (sprint['tasks'] as List).every((t) => t['status'] == 'DONE');
      if (allDone) {
        sprint['status'] = 'COMPLETED';
        print('\x1B[32m[SPRINT-GATE] Sprint ${sprint['id']} FINALIZADO exitosamente.\x1B[0m');
        print('Se recomienda ejecutar "gov baseline" para sellar el sprint.');
      }
    }
  }

  backlogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(data));
  print('[SUCCESS] $updatedCount tareas sincronizadas en backlog.json.');

  // 5. Automatización Elite: Housekeeping + Auto-Baseline
  await _runHousekeeping(basePath);

  final currentSprintId = data['current_sprint'];
  final activeSprint = data['sprints'].firstWhere(
    (s) => s['id'] == currentSprintId, 
    orElse: () => data['sprints'].reversed.firstWhere(
      (s) => s['status'] == 'COMPLETED' || s['status'] == 'IN_PROGRESS', 
      orElse: () => null
    )
  );

  if (activeSprint != null && activeSprint['status'] == 'COMPLETED') {
    print('\x1B[35m[AUTO-GATE] Detectado fin de Sprint ${activeSprint['id']}. Gatillando Auto-Seal...\x1B[0m');
    await _runBaseline(basePath, "Automatic Sprint Seal: ${activeSprint['id']}");
  }

  await _triggerDashboardSync(basePath);
}

Future<void> runPulse(String basePath, List<String> args) async {
  try {
    // S-126-15: Guard de Saturación Forzada para Pruebas
    if (args.contains('--declare')) {
       final pulseFile = File(p.join(basePath, '.meta', 'session_pulse.json'));
       final valueStr = args[args.indexOf('--declare') + 1];
       final int value = int.parse(valueStr);
       
       Map<String, dynamic> pulse = {};
       if (pulseFile.existsSync()) {
         try { pulse = jsonDecode(pulseFile.readAsStringSync()); } catch (_) {}
       }
       
       pulse['internal_redline'] = value;
       pulse['last_action_ts'] = DateTime.now().toIso8601String();
       pulseFile.writeAsStringSync(jsonEncode(pulse));
       print('\x1B[33m[VANGUARD] Declara Saturación Forzada: $value%\x1B[0m');
    }

    final cognitive = CognitiveEngine();
    final pulseData = await cognitive.calculatePulse(basePath);
    await cognitive.persistPulse(basePath, pulseData);

    print('SHS Pulse: ${pulseData.saturation}% [${pulseData.saturation < 90 ? 'NOMINAL' : 'CRITICAL'}]');

    // [RESILIENCE] Checkpointing Atómico (Caja Negra)
    final sessionLock = File(p.join(basePath, '.meta', 'session.lock'));
    if (sessionLock.existsSync()) {
      try {
        final data = jsonDecode(sessionLock.readAsStringSync());
        data['last_action'] = DateTime.now().toLocal().toString().substring(0, 19);
        sessionLock.writeAsStringSync(jsonEncode(data));
      } catch (_) {}
    }

    // [S25-06] Auto-actualizar fleet_pulse.json después de cada heartbeat
    try {
      final registryFile = File(p.join(basePath, 'vault', 'intel', 'fleet_registry.json'));
      if (registryFile.existsSync()) {
        await runFleetPulse(basePath, ['--silent']);
      }
    } catch (fleetError) {
      // Error silencioso en fleet pulse — no debe interrumpir el pulse individual
    }
  } catch (e) {
    print('[ERROR] Orquestación de Pulso fallida: $e');
  }
}

Future<void> runInit(String basePath, List<String> args) async {
  if (args.length < 2 && !args.contains('--vision')) {
    print('[ERROR] Uso: gov init <ruta_destino> [--name <nombre>] [--vision <texto>]');
    return;
  }

  final targetPath = args[1];
  final targetDir = Directory(targetPath);
  String? projectName;
  String? visionText;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--name' && i + 1 < args.length) projectName = args[i + 1];
    if (args[i] == '--vision' && i + 1 < args.length) visionText = args[i + 1];
  }

  projectName ??= p.basename(targetPath);

  print('=== [GOV] INICIALIZACIÓN DPI: $projectName ===');
  
  if (targetDir.existsSync()) {
    print('\x1B[31m[ERROR] El directorio destino ya existe: $targetPath\x1B[0m');
    exit(1);
  }

  // 1. Clonar Estructura (Sello DPI-GATE-GOLD)
  final foldersToCopy = ['.agent', '.meta', 'vault', 'bin'];
  for (var folder in foldersToCopy) {
    final source = Directory(p.join(basePath, folder));
    if (source.existsSync()) {
      print('  [COPY] $folder/');
      _copyDirectory(source, Directory(p.join(targetPath, folder)));
    }
  }
  print('  [OK] Estructura base clonada.');

  // 2. Inyectar Visión Cognitiva
  if (visionText != null) {
     final vFile = File(p.join(targetPath, 'VISION.md'));
     vFile.writeAsStringSync('# VISION: $projectName\n\n$visionText');
     print('  [OK] VISION.md integrada desde orquestador.');
  }

  // 2b. Validación Hard-Gate de Visión
  final visionFile = File(p.join(targetPath, 'VISION.md'));
  if (!visionFile.existsSync() || visionFile.readAsStringSync().length < 50) {
    print('\x1B[31m[STOP] INSIGHT INSUFICIENTE: VISION.md debe tener al menos 50 caracteres.\x1B[0m');
    print('[INFO] Si usas CLI, usa --vision "<texto>". Si usas Wizard, completa el campo.');
    targetDir.deleteSync(recursive: true);
    exit(1);
  }

  // 3. Generar Matriz de Roles
  final rolesDir = Directory(p.join(targetPath, 'vault', 'rules'));
  if (!rolesDir.existsSync()) rolesDir.createSync(recursive: true);
  
  final rolesData = {
    "roles": {
      "PO": {"desc": "Product Owner", "auth": "STRATEGIC", "sigs": 1},
      "ARCH": {"desc": "Governance Architect", "auth": "CRITICAL", "sigs": 1},
      "DEV": {"desc": "Lead Developer", "auth": "EXECUTION", "sigs": 1},
      "QA": {"desc": "Integrity Specialist", "auth": "VERIFICATION", "sigs": 1}
    },
    "requirements": {
      "GOV": ["ARCH"],
      "BIZ": ["PO"],
      "CODE": ["DEV", "QA"]
    }
  };
  File(p.join(rolesDir.path, 'roles.json')).writeAsStringSync(JsonEncoder.withIndent('  ').convert(rolesData));
  print('  [OK] roles.json instanciado.');

  // 4. Inyectar Sprint 0 (S00-INCEPTION)
  final inceptionSprint = {
    "id": "S00-INCEPTION",
    "name": "Bootstrapping y Alineación",
    "status": "TODO",
    "tasks": [
      {"id": "TASK-S00-01", "desc": "Definir Matriz de Roles y Criterios de Aceptación", "status": "TODO", "label": "BIZ"},
      {"id": "TASK-S00-02", "desc": "Configurar Modelo de Datos e Interfaces Base", "status": "TODO", "label": "ARCH"}
    ]
  };

  final Map<String, dynamic> backlog = {
    "project": projectName,
    "version": "0.1.0",
    "last_sync": DateTime.now().toIso8601String(),
    "current_sprint": "S00-INCEPTION",
    "sprints": [inceptionSprint]
  };
  final backlogFile = File(p.join(targetPath, 'backlog.json'));
  backlogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(backlog));
  // 5. Generar task.md y MDs de tareas
  final sprintDir = Directory(p.join(targetPath, '.meta', 'sprints', 'S00-INCEPTION'));
  if (!sprintDir.existsSync()) sprintDir.createSync(recursive: true);
  
  File(p.join(sprintDir.path, 'TASK-S00-01.md')).writeAsStringSync(
    '# TASK-S00-01: Definición de Roles\n\n'
    '## Contexto\nArranque de búnker.\n\n'
    '## Objetivos\n- [ ] Definir roles operativos.\n- [ ] Establecer criterios de aceptación.\n'
  );

  File(p.join(sprintDir.path, 'TASK-S00-02.md')).writeAsStringSync(
    '# TASK-S00-02: Configuración de Datos\n\n'
    '## Contexto\nAlineación estructural del búnker.\n\n'
    '## Objetivos\n- [ ] Diseñar modelo de datos.\n- [ ] Definir interfaces.\n'
  );

  File(p.join(targetPath, 'task.md')).writeAsStringSync(
    '# BÚNKER: $projectName\n\n'
    '- [/] TASK-S00-01: Definición de Roles\n'
    '- [ ] TASK-S00-02: Configuración de Datos\n\n'
    '---\n'
    'Sello de Iniciación: [OK] Kernel Instanciado.'
  );

  print('\x1B[32m[SUCCESS] Búnker instanciado en: $targetPath\x1B[0m');
  
  await ForensicLedger().appendEntry(
    sessionId: 'S24-GOLD',
    type: 'INIT',
    task: 'DPI-INIT',
    detail: 'Proyecto creado: $projectName',
    basePath: basePath,
    role: 'ARCH'
  );
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (var entity in source.listSync(recursive: false)) {
    if (entity is Directory) {
      _copyDirectory(entity, Directory(p.join(destination.path, p.basename(entity.path))));
    } else if (entity is File) {
      entity.copySync(p.join(destination.path, p.basename(entity.path)));
    }
  }
}

Future<void> _runHousekeeping(String basePath, {bool silent = false}) async {
  if (!silent) print('=== [GOV] HOUSEKEEPING (Higiene Operativa) ===');
  final root = Directory(basePath);
  final logsDir = Directory(p.join(basePath, 'vault', 'logs'));
  if (logsDir.existsSync()) {
    if (FileSystemEntity.isFileSync(logsDir.path)) {
      print('\x1B[33m[HOUSEKEEPING] Colisión detectada: vault/logs es archivo. Corrigiendo...\x1B[0m');
      File(logsDir.path).renameSync(p.join(basePath, 'vault', 'logs_legacy.bak'));
      logsDir.createSync(recursive: true);
    }
  } else {
    logsDir.createSync(recursive: true);
  }

  // 1. Identificar archivos purgar (Zombies/Temporales)
  final criteria = ['.tmp', '.bak', 'SESSION_LOCKED', 'test_results.json', 'tests_output.txt', 'all_tests_check.txt', 'test_fail_detail.txt'];
  final sessionUuid = 'audit_${DateTime.now().millisecondsSinceEpoch}';
  final currentSessionLogs = Directory(p.join(logsDir.path, sessionUuid));
  bool movedAny = false;
  final integrity = IntegrityEngine();
  final zombies = await integrity.checkZombies(basePath);

  if (zombies.isNotEmpty) {
    print('[HOUSEKEEPING] Detectados ${zombies.length} zombies. Purgando...');
    for (var z in zombies) {
       final zFile = File(p.join(basePath, z));
       if (zFile.existsSync()) {
          print('  [DEAD] $z');
          zFile.deleteSync();
       }
    }
    movedAny = true;
  }

  final rootFiles = root.listSync().whereType<File>();
  final taskFiles = rootFiles.where((f) => p.basename(f.path).startsWith('TASK-') && p.basename(f.path).endsWith('.md'));
  
  if (taskFiles.isNotEmpty) {
    final backlogFile = File(p.join(basePath, 'backlog.json'));
    if (backlogFile.existsSync()) {
      try {
        final backlog = jsonDecode(backlogFile.readAsStringSync());
        final sprints = backlog['sprints'] as List;
        
        for (var tFile in taskFiles) {
          final fileName = p.basename(tFile.path);
          final taskId = fileName.replaceAll('.md', '');
          String? sprintId;

          for (var sprint in sprints) {
            final tasks = sprint['tasks'] as List;
            if (tasks.any((t) => t['id'] == taskId)) {
              sprintId = sprint['id'];
              break;
            }
          }

          if (sprintId != null) {
            final destDir = Directory(p.join(basePath, '.meta', 'sprints', sprintId));
            if (!destDir.existsSync()) destDir.createSync(recursive: true);
            
            print('  [MOVE] $fileName -> ${sprintId}/');
            tFile.renameSync(p.join(destDir.path, fileName));
            movedAny = true;
          } else {
             print('  [WARN] No se encontró sprint para $fileName en backlog.json. Queda en raíz.');
          }
        }
      } catch (e) {
        print('[ERROR] Fallo al relocalizar tareas: $e');
      }
    }
  }

  for (var entity in root.listSync().whereType<File>()) {
    final name = p.basename(entity.path);
    if (criteria.any((c) => name.contains(c))) {
      if (!currentSessionLogs.existsSync()) currentSessionLogs.createSync();
      entity.renameSync(p.join(currentSessionLogs.path, name));
      movedAny = true;
    }
  }

  if (movedAny) {
    print('[OK] Saneamiento completado.');
    final pulseData = await CognitiveEngine().calculatePulse(basePath);
    await CognitiveEngine().persistPulse(basePath, pulseData);
  } else {
    print('[OK] No se detectó basura operativa.');
  }

  final folders = logsDir.listSync().whereType<Directory>().toList();
  folders.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

  if (folders.length > 5) {
    print('[HOUSEKEEPING] Rotación de logs: Purgando sesión más antigua...');
    for (int i = 0; i < folders.length - 5; i++) {
       folders[i].deleteSync(recursive: true);
    }
  }
}

Future<void> runAdopt(String basePath, List<String> args) async {
  if (args.length < 2) {
    print('[ERROR] Uso: gov adopt <ruta_proyecto> [--name <nombre>] [--dry-run] [--commit]');
    return;
  }

  final targetPath = args[1];
  final isDryRun = args.contains('--dry-run');
  final isCommit = args.contains('--commit');
  
  String? targetName;
  if (args.contains('--name')) {
    final idx = args.indexOf('--name');
    if (idx + 1 < args.length) targetName = args[idx + 1];
  }
  targetName ??= p.basename(targetPath);
  final targetDir = Directory(targetPath);
  final integrityCheck = IntegrityEngine();
  final isDev = Platform.environment['DPI_GOV_DEV'] == 'true';
  if (isDev) print('[DEBUG] GOV: bypass de integridad activo (DEV MODE)');

  if (!isDev && !await integrityCheck.verifySelf(toolRoot: basePath)) {
    print('\x1B[31m[STOP] Oráculo corrupto o sin sello de ADN. Operación abortada.\x1B[0m');
    exit(1);
  }

  if (!targetDir.existsSync()) {
    print('[ERROR] La ruta no existe: $targetPath');
    return;
  }

  final pubspec = File(p.join(targetPath, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    print('[ERROR] No se encontró pubspec.yaml. No es un proyecto Flutter válido.');
    return;
  }

  if (!isDryRun) {
    print('=== [GOV] ADOPCIÓN DPI: $targetName ===');
  }
  
  if (!isDryRun) {
    // 1. Crear Estructura Base
    final metaSprints = Directory(p.join(targetPath, '.meta', 'sprints'));
    if (!metaSprints.existsSync()) metaSprints.createSync(recursive: true);
    
    final vaultIntel = Directory(p.join(targetPath, 'vault', 'intel'));
    if (!vaultIntel.existsSync()) vaultIntel.createSync(recursive: true);

    // 2. Inyectar Motor (Copia del actual si existe)
    final currentGov = File(p.join(basePath, 'bin', 'gov.exe'));
    final targetBin = Directory(p.join(targetPath, 'bin'));
    if (!targetBin.existsSync()) targetBin.createSync(recursive: true);

    if (currentGov.existsSync()) {
      print('  [INJECT] gov.exe -> bin/');
      currentGov.copySync(p.join(targetBin.path, 'gov.exe'));
    }
  }

  // 3. Diagnóstico de Alineación (Rescue Sprint Generation)
  print('  [SCAN] Detectando brechas de gobernanza...');
  final gaps = <Map<String, dynamic>>[];
  
  if (!File(p.join(targetPath, 'VISION.md')).existsSync()) {
    gaps.add({"id": "TASK-ADOPT-01", "desc": "Definir VISION.md legada para alineación estratégica", "label": "BIZ", "sigs": ["PO"]});
  }
  if (!File(p.join(targetPath, 'GEMINI.md')).existsSync()) {
    gaps.add({"id": "TASK-ADOPT-02", "desc": "Instanciar GEMINI.md y selector de roles", "label": "ARCH", "sigs": ["ARCH"]});
  }
  if (!File(p.join(targetPath, 'vault', 'rules', 'roles.json')).existsSync()) {
    gaps.add({"id": "TASK-ADOPT-03", "desc": "Definir matriz de roles y firmas [DPI-GATE-GOLD]", "label": "ARCH", "sigs": ["ARCH", "PO"]});
  }
  
  final backlogFile = File(p.join(targetPath, 'backlog.json'));
  Map<String, dynamic> backlog;
  
  if (!backlogFile.existsSync()) {
    print('  [GEN] backlog.json (Rescue Mode)');
    backlog = {
      "project": targetName,
      "version": "1.0.0-ADOPTED",
      "last_sync": DateTime.now().toIso8601String(),
      "current_sprint": "S01-ALIGNMENT",
      "sprints": []
    };
    gaps.add({"id": "TASK-ADOPT-04", "desc": "Sincronización inicial de Backlog", "label": "ARCH", "sigs": ["ARCH"]});
  } else {
    try {
      backlog = jsonDecode(backlogFile.readAsStringSync());
    } catch (_) {
      backlog = {"project": targetName, "sprints": []};
    }
  }

  if (isDryRun) {
    final diagOutput = {
      "gaps": gaps.map((g) => g['id']).toList(),
      "score": ((1 - gaps.length / 5.0) * 100).toInt().clamp(0, 100),
      "target": targetPath,
      "project": targetName,
    };
    print(JsonEncoder.withIndent('  ').convert(diagOutput));
    return;
  }

  if (gaps.isNotEmpty) {
    print('  [BOOTSTRAP] Generando Sprint de Rescate: S01-ALIGNMENT');
    final rescueSprint = {
      "id": "S01-ALIGNMENT",
      "name": "Rescate y Alineación DPI-GATE-GOLD",
      "status": "TODO",
      "goal": "Restablecer soberanía y gobernanza en proyecto legado.",
      "tasks": gaps.map((g) => {
        "id": g['id'],
        "desc": g['desc'],
        "status": "TODO",
        "label": g['label'],
        "required_signatures": g['sigs'] ?? ["ARCH"]
      }).toList()
    };
    
    (backlog['sprints'] as List).add(rescueSprint);
    backlog['current_sprint'] = "S01-ALIGNMENT";
    backlog['current_task'] = gaps.first['id'];
    
    backlogFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(backlog));

    // Generar MDs físicos
    final sprintDir = Directory(p.join(targetPath, '.meta', 'sprints', 'S01-ALIGNMENT'));
    if (!sprintDir.existsSync()) sprintDir.createSync(recursive: true);

    for (var gap in gaps) {
      File(p.join(sprintDir.path, '${gap['id']}.md')).writeAsStringSync(
        '# ${gap['id']}: ${gap['desc']}\n\n'
        '## Contexto\nTarea generada automáticamente por `gov adopt` tras detectar ausencia de este componente crítico.\n\n'
        '## Criterios de Aceptación\n- [ ] El archivo respectivo existe y cumple el estándar DPI-GATE-GOLD.\n'
      );
    }
  }

  // 4. Generar task.md maestro para el proyecto adoptado
  print('  [GEN] task.md (Master Protocol)');
  final taskContent = StringBuffer();
  taskContent.writeln('# TASK: S01-ALIGNMENT (Rescue Mode)');
  taskContent.writeln('');
  for (int i = 0; i < gaps.length; i++) {
    final status = (i == 0) ? '[/]' : '[ ]';
    taskContent.writeln('- $status ${gaps[i]['id']}: ${gaps[i]['desc']}');
  }
  taskContent.writeln('');
  taskContent.writeln('---');
  taskContent.writeln('Sello de Adopción: [!] Búnker LEGACY detectado y alineado.');
  File(p.join(targetPath, 'task.md')).writeAsStringSync(taskContent.toString());

  // 5. Registro en Fleet Registry (Maestro)
  _registerInFleet(basePath, targetName, targetPath);

  // 6. Registro Forense Atómico
  await ForensicLedger().appendEntry(
    sessionId: 'S24-GOLD',
    type: 'EXEC',
    task: 'DPI-ADOPT',
    detail: 'Proyecto adoptado: $targetName en $targetPath. Brechas: ${gaps.length}',
    basePath: basePath,
    role: 'ARCH'
  );

  print('\x1B[32m[SUCCESS] Proyecto adoptado y alineado: $targetPath\x1B[0m');
  if (gaps.isNotEmpty) {
    print('\x1B[33m[ALERT] Se han generado ${gaps.length} tareas de rescate en S01-ALIGNMENT.\x1B[0m');
  }
}

void _registerInFleet(String basePath, String name, String path) {
  final registryFile = File(p.join(basePath, 'vault', 'intel', 'fleet_registry.json'));
  Map<String, dynamic> registry = {"projects": []};
  
  if (registryFile.existsSync()) {
    try {
      registry = jsonDecode(registryFile.readAsStringSync());
    } catch (_) {}
  }
  
  if (!registry.containsKey('projects')) registry['projects'] = [];
  final projects = registry['projects'] as List;
  if (!projects.any((p) => p['path'] == path)) {
    projects.add({
      "name": name,
      "path": path,
      "status": "ADOPTED",
      "last_seen": DateTime.now().toIso8601String()
    });
    registryFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(registry));
    print('  [REGISTRY] Proyecto añadido a la flota.');
  }
}

Future<void> runPlan(String basePath, List<String> args) async {
  print('=== [GOV] ORQUESTADOR DE PLANIFICACIÓN ===');
  
  final backlogFile = File(p.join(basePath, 'backlog.json'));
  if (!backlogFile.existsSync()) {
    print('[ERROR] No se encontró backlog.json.');
    return;
  }

  try {
    final backlog = jsonDecode(backlogFile.readAsStringSync());
    final sprints = backlog['sprints'] as List;
    int createdCount = 0;

    for (var sprint in sprints) {
      final sprintId = sprint['id'] as String;
      final tasks = sprint['tasks'] as List;
      final sprintDir = Directory(p.join(basePath, '.meta', 'sprints', sprintId));
      if (!sprintDir.existsSync()) sprintDir.createSync(recursive: true);

      for (var task in tasks) {
        final taskId = task['id'] as String;
        final taskFile = File(p.join(sprintDir.path, '$taskId.md'));
        
        if (!taskFile.existsSync()) {
          print('  [NEW] Generando Tarea: $taskId');
          final content = '''# $taskId: ${task['desc']}
## Contexto
Auto-generado por el Orquestador Gov.

## Objetivos Atómicos
1. [ ] Definir requerimientos técnicos.
2. [ ] Implementar lógica en layer correspondiente.
3. [ ] Validar integridad y certificar.

## Guía de Verificación
- Auditoría SHS tras el cambio.
''';
          taskFile.writeAsStringSync(content);
          createdCount++;
        }
      }
    }
    
    print('[OK] Planificación sincronizada. $createdCount tareas nuevas generadas.');
    // Saneamiento automático
    await _runHousekeeping(basePath);

  } catch (e) {
    print('[ERROR] Fallo en orquestación de plan: $e');
  }
}


Future<void> _triggerDashboardSync(String basePath) async {
  print('\x1B[36m[DASH] Detectada necesidad de refresco visual. Orquestando Dashboard...\x1B[0m');
  final scriptPath = p.join(basePath, 'vault', 'ops-dashboard.ps1');
  
  if (!File(scriptPath).existsSync()) {
    print('[WARNING] No se encontró ops-dashboard.ps1. Saltando actualización visual.');
    return;
  }

  try {
    final result = await Process.run(
      'powershell', 
      ['-ExecutionPolicy', 'Bypass', '-File', scriptPath],
      runInShell: true,
    );
    
    if (result.stdout != null && result.stdout.toString().trim().isNotEmpty) {
      print(result.stdout);
    }
    
    if (result.exitCode != 0) {
      print('\x1B[33m[DASH-WARN] Fallo parcial en el renderizado del Dashboard.\x1B[0m\n${result.stderr}');
    }
  } catch (e) {
    print('[ERROR] Excepción al lanzar Dashboard: $e');
  }
}
Future<void> runSealDNA(String basePath, List<String> args) async {
  print('=== [GOV] BINARY DNA SEALING [DPI-GATE-GOLD] ===');
  
  final exePath = Platform.resolvedExecutable;
  final exeFile = File(exePath);
  
  if (!exeFile.existsSync()) {
    print('[ERROR] No se pudo localizar el binario ejecutable.');
    return;
  }

  // 1. Calcular Hash del Binario Actual
  final bytes = exeFile.readAsBytesSync();
  final binaryHash = sha256.convert(bytes).toString().toLowerCase();
  print('  [DNA] Hash Detectado: $binaryHash');

  // 2. Preparar Desafío
  final vanguard = VanguardCore();
  final pubKeyFile = File(p.join(basePath, 'vault', 'intel', 'guard_pub.xml'));
  if (!pubKeyFile.existsSync()) {
    print('[ERROR] Faltan llaves públicas en vault/intel/guard_pub.xml');
    return;
  }
  final pubKeyXml = await pubKeyFile.readAsString();

  final challengeId = await vanguard.issueChallenge(
    level: 'DNA-CERTIFICATION',
    project: 'Vanguard Kernel',
    files: [p.basename(exePath)],
    basePath: basePath,
    description: 'Binary DNA Seal for v8.0 Dual Motor',
    forcedId: 'DNA-${binaryHash.substring(0, 8)}',
  );

  // 3. Esperar Firma RSA
  print('\n[WAIT] Solicitando firma por Vanguard...');
  final isSigned = await vanguard.waitForSignature(
    basePath: basePath,
    challenge: challengeId,
    publicKeyXml: pubKeyXml,
    timeoutSeconds: 300,
  );

  if (!isSigned) {
    print('[FAIL] Desafío de ADN rechazado o expirado.');
    return;
  }

  // 4. Persistir Sello
  final sigFile = File(p.join(basePath, 'vault', 'intel', 'gov_hash.sig'));
  await sigFile.writeAsString(binaryHash);
  
  print('\n\x1B[32m[SUCCESS] ADN BINARIO SELLADO E INMUTABLE.\x1B[0m');
  print('[INFO] El búnker ahora solo aceptará este binario específico.');
  
  // Registro Forense
  await ForensicLedger().appendEntry(
    sessionId: 'S24-GOLD',
    type: 'BASE',
    task: 'DNA-SEAL',
    detail: 'Sello de ADN Binario v8.0 Certificado: $binaryHash',
    basePath: basePath,
    role: 'PO'
  );
}

Future<void> runFleetPulse(String basePath, List<String> args) async {
  final isSilent = args.contains('--silent');
  if (!isSilent) print('=== [GOV] FLEET TELEMETRY AGGREGATOR [DPI-GATE-GOLD] ===');
  final registryFile = File(p.join(basePath, 'vault', 'intel', 'fleet_registry.json'));
  
  if (!registryFile.existsSync()) {
    print('[ERROR] No se encontró fleet_registry.json.');
    return;
  }

  try {
    final Map<String, dynamic> registry = jsonDecode(registryFile.readAsStringSync());
    final List bunkers = registry['bunkers'] ?? registry['projects'] ?? [];
    
    final List<Map<String, dynamic>> results = [];
    if (!isSilent) print('[INFO] Escaneando ${bunkers.length} nodos registrados...');

    for (var node in bunkers) {
      final name = node['name'] ?? 'Unknown';
      final path = node['path'] as String;
      final pulsePath = p.join(path, 'vault', 'intel', 'intel_pulse.json');
      final pulseFile = File(pulsePath);

      if (!pulseFile.existsSync()) {
        results.add({
          "name": name,
          "status": "OFFLINE",
          "path": path,
          "timestamp": DateTime.now().toIso8601String()
        });
        if (!isSilent) print('  [OFFLINE] $name @ $path');
        continue;
      }

      try {
        final Map<String, dynamic> pulse = jsonDecode(pulseFile.readAsStringSync());
        final cus = pulse['context']?['cus'] ?? pulse['health']?['context']?['cus'] ?? pulse['shs_pulse'];
        final bpi = pulse['hygiene']?['bpi'] ?? pulse['health']?['hygiene']?['bpi'] ?? pulse['shs_pulse'];
        
        results.add({
          "name": name,
          "status": "ONLINE",
          "context": pulse['context'] ?? pulse['health']?['context'],
          "hygiene": pulse['hygiene'] ?? pulse['health']?['hygiene'],
          "timestamp": pulse['timestamp'] ?? DateTime.now().toIso8601String()
        });
        if (!isSilent) print('  [OK] $name (CUS: $cus% | BPI: $bpi%)');
      } catch (_) {
        results.add({"name": name, "status": "ERROR", "path": path});
        print('  [ERROR] $name (Corrupto)');
      }
    }

    final output = {
      "fleet_id": "VANGUARD-FLEET-ALPHA",
      "count": results.length,
      "nodes": results,
      "aggregated_ts": DateTime.now().toIso8601String()
    };

    if (args.contains('--json')) {
      print(JsonEncoder.withIndent('  ').convert(output));
    } else if (!isSilent) {
      print('----------------------------------------');
      print('[SUCCESS] Agregación de flota completada.');
      print('Nodos: ${results.length} | Online: ${results.where((n) => n['status'] == 'ONLINE').length}');
      print('----------------------------------------');
    }
    
    // Persistencia del estado de flota
    final fleetPulseFile = File(p.join(basePath, 'vault', 'intel', 'fleet_pulse.json'));
    fleetPulseFile.writeAsStringSync(jsonEncode(output));

  } catch (e) {
    print('[ERROR] Fallo en la agregación de flota: $e');
  }
}
