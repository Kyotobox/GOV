import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as p;
import '../telemetry/telemetry_service.dart';
import '../telemetry/session_logger.dart';
import '../security/integrity_engine.dart';

enum EvaluatorState { NOMINAL, WARNING, LOCKED, SECURITY_HOLD }

class EvaluatorResult {
  final EvaluatorState state;
  final String protocol;
  EvaluatorResult(this.state, this.protocol);

  bool get isCritical => state == EvaluatorState.LOCKED || state == EvaluatorState.SECURITY_HOLD;
}

class PulseEvaluator {
  static EvaluatorResult evaluate(double cus, double bhi) {
    // S29-04: Independent Logic Triggers
    if (bhi >= 90.0) {
      return EvaluatorResult(EvaluatorState.SECURITY_HOLD, 'HUMAN_INTERVENTION');
    }
    if (cus >= 45.0) {
      return EvaluatorResult(EvaluatorState.LOCKED, 'SESSION_RESET');
    }
    if (cus >= 35.0) {
      return EvaluatorResult(EvaluatorState.WARNING, 'NOTIFY_USER');
    }
    return EvaluatorResult(EvaluatorState.NOMINAL, 'NOMINAL');
  }
}

/// PulseAggregator: Consolidates cognitive and structural health telemetry.
/// S28-02: Core logic migrated from telemetry_service and kernel.
class PulseAggregator {
  final String basePath;
  final ContextEngine _contextEngine = ContextEngine();
  final BunkerHealthEngine _bunkerEngine = BunkerHealthEngine();

  PulseAggregator(this.basePath);

  /// Calculates the DualPulse (SHS) for the current node.
  Future<DualPulseData> calculatePulse() async {
    final context = await _contextEngine.calculateCUS(basePath);
    final bunker = await _bunkerEngine.calculateBHI(basePath);
    
    return DualPulseData(
      context: context,
      bunker: bunker,
      timestamp: DateTime.now().toIso8601String(),
      sessionUuid: Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL',
    );
  }

  /// Persists the aggregated pulse to the fleet-visible telemetry files.
  Future<void> persistPulse(DualPulseData data) async {
    final telemetry = TelemetryService(basePath: basePath);
    await telemetry.persistPulse(
      PulseSnapshot(
        cp: data.context.cus,
        saturation: data.saturation,
        cpDetail: {
          ...data.context.detail,
          'bhi': data.bunker.bhi,
          'zombies': data.bunker.zombies,
          'density': data.bunker.density,
          'structural': data.bunker.detail,
          'estimated_tokens': data.context.tokens,
          'interaction_count': data.context.turns,
          'output_utilization': data.context.outputUtilization,
          'max_tokens_detected': data.context.maxTokensDetected,
        },
        timestamp: data.timestamp,
      ),
      basePath: basePath,
    );
  }
}

/// Unified Telemetry Data Structure [DPI-GATE-GOLD]
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

  EvaluatorResult get evaluation => PulseEvaluator.evaluate(context.cus, bunker.bhi);

  int get saturation {
    // S29-04: Saturation reflects the severity of the Evaluator State
    switch (evaluation.state) {
      case EvaluatorState.SECURITY_HOLD: return 100;
      case EvaluatorState.LOCKED: return 95;
      case EvaluatorState.WARNING: return 85;
      case EvaluatorState.NOMINAL:
        return max(context.cus, bunker.bhi).round();
    }
  }
  double get cp => context.cus;
  Map<String, dynamic> get detail => context.detail;
  int get zombieCount => bunker.zombies;

  Map<String, dynamic> toJson() => {
    'context': context.toJson(),
    'hygiene': bunker.toJson(),
    'timestamp': timestamp,
    'session_uuid': sessionUuid,
    'shs_pulse': saturation,
    'cp_fatigue': context.cus, 
    'saturation': saturation,
    'zombies': bunker.zombies,
    'evaluator_state': evaluation.state.name,
    'protocol': evaluation.protocol,
  };
}

// --- NUCLEUS-V9 ENGINES (Migrated to Services) ---

class ContextEngine {
  static const int kContextWindow = 1000000;
  static const int kOutputLimit = 8000;

  Future<ContextState> calculateCUS(String basePath) async {
    final logger = SessionLogger(basePath: basePath);
    final logs = await logger.loadLogs();
    
    if (logs.isEmpty) return _calculateLegacyCUS(basePath);

    double totalCP = 0.0;
    int totalEstimatedTokens = 0;
    double maxUtilization = 0.0;
    bool maxTokensFound = false;

    for (final log in logs) {
      final type = log['type'] as String;
      final detail = (log['detail'] as String).toUpperCase();
      final tokens = log['tokens'] as int;

      if (type == 'TOOL') {
        if (detail.contains('REPLACE') || detail.contains('WRITE')) {
          totalCP += 2.2;
        } else if (detail.contains('COMMAND') || detail.contains('SEARCH')) {
          totalCP += 1.5;
        } else {
          totalCP += 0.8;
        }
      } else if (type == 'CHAT') {
        totalCP += 0.7;
      }

      totalEstimatedTokens += tokens;
      if (log['finish_reason'] == 'MAX_TOKENS') maxTokensFound = true;

      final double util = tokens.toDouble() / kOutputLimit;
      if (util > maxUtilization) maxUtilization = util;
    }

    final double contextRatio = totalEstimatedTokens / kContextWindow;
    if (contextRatio > 0.8) {
      final frictionMultiplier = 1.0 + ((contextRatio - 0.8) * 10.0);
      totalCP *= frictionMultiplier;
    }

    if (maxTokensFound) totalCP += 45.0;

    return ContextState(
      cus: totalCP.clamp(0.0, 100.0),
      tokens: totalEstimatedTokens,
      turns: logs.length,
      outputUtilization: maxUtilization.clamp(0.0, 1.0),
      maxTokensDetected: maxTokensFound,
      detail: {
        'weighted_interaction_cp': totalCP,
        'context_ratio': contextRatio.toStringAsFixed(3),
        'friction_active': contextRatio > 0.8,
        'interaction_count': logs.length,
        'atomic_focus': true,
      },
    );
  }

  Future<ContextState> _calculateLegacyCUS(String basePath) async {
    final turnsFile = File(p.join(basePath, 'vault', 'intel', 'session_turns.txt'));
    final chatsFile = File(p.join(basePath, 'vault', 'intel', 'chat_count.txt'));
    int turns = 0;
    int chats = 0;
    if (turnsFile.existsSync()) turns = int.tryParse(turnsFile.readAsStringSync().trim()) ?? 0;
    if (chatsFile.existsSync()) chats = int.tryParse(chatsFile.readAsStringSync().trim()) ?? 0;

    return ContextState(
      cus: ((turns * 1.2) + (chats * 0.5)).clamp(0.0, 100.0),
      tokens: turns * 300,
      turns: turns + chats,
      detail: {'legacy_mode': true},
    );
  }
}

class BunkerHealthEngine {
  Future<BunkerHealthState> calculateBHI(String basePath) async {
    final integrity = IntegrityEngine();
    final swelling = await integrity.checkSwelling(basePath);
    final zombies = await integrity.checkZombies(basePath);

    final bool isSelfIntact = await integrity.verifySelf(toolRoot: basePath);
    final double integrityScore = isSelfIntact ? 0.0 : 70.0;

    final double hygieneScore = ((swelling.fileCount / IntegrityEngine.kMaxRootFiles) * 15.0) + 
                                (zombies.length * 3.0).clamp(0.0, 15.0);

    double timePenalty = 0.0;
    final sessionLock = File(p.join(basePath, 'session.lock'));
    if (sessionLock.existsSync()) {
      try {
        final data = jsonDecode(sessionLock.readAsStringSync());
        final startTs = DateTime.parse(data['timestamp']);
        final diff = DateTime.now().difference(startTs).inMinutes;
        timePenalty = (diff / 15.0).clamp(0.0, 15.0);
      } catch (_) {}
    }

    return BunkerHealthState(
      bhi: (integrityScore + hygieneScore + timePenalty).clamp(0.0, 100.0),
      zombies: zombies.length,
      density: swelling.fileCount,
      detail: {
        'dna_intact': isSelfIntact,
        'time_tax': timePenalty.toStringAsFixed(1),
        'hygiene': hygieneScore.toStringAsFixed(1),
      },
    );
  }
}
