import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import '../telemetry/telemetry_service.dart';
import '../telemetry/session_logger.dart';
import '../security/integrity_engine.dart';
import '../version.dart';

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
    
    // S30-SEP: Project-Bound UUID (Isolation)
    final globalUuid = Platform.environment['VANGUARD_CHAT_UUID'] ?? 'MANUAL';
    final projectSeed = p.canonicalize(basePath).toLowerCase();
    final projectUuid = sha256.convert(utf8.encode('$projectSeed:$globalUuid')).toString().substring(0, 32);

    return DualPulseData(
      context: context,
      bunker: bunker,
      timestamp: DateTime.now().toIso8601String(),
      sessionUuid: projectUuid,
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
        sessionUuid: data.sessionUuid,
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
    'kernel_version': kKernelVersion,
  };
}

// --- NUCLEUS-V9 ENGINES (Migrated to Services) ---

class ContextEngine {
  static const int kContextWindow = 500000; // S29-01
  static const int kOutputLimit = 8192;   // S29-01

  Future<ContextState> calculateCUS(String basePath) async {
    final logger = SessionLogger(basePath: basePath);
    final logs = await logger.loadLogs();
    
    if (logs.isEmpty) return _calculateLegacyCUS(basePath);

    int totalPromptTokens = 0;
    int maxOutputTokens = 0;
    int truncationEvents = 0;
    bool latestTruncated = false;

    for (final log in logs) {
      final pTokens = log['prompt_tokens'] as int? ?? 0;
      final oTokens = log['output_tokens'] as int? ?? 0;
      final fReason = log['finish_reason'] as String? ?? 'stop';

      totalPromptTokens += pTokens;
      if (oTokens > maxOutputTokens) maxOutputTokens = oTokens;
      
      if (fReason == 'MAX_TOKENS') {
        truncationEvents++;
        latestTruncated = (log == logs.last);
      }
    }

    final double turnsWeight = logs.length * 1.2;
    final double inputPressure = totalPromptTokens / kContextWindow;
    final double outputPressure = maxOutputTokens / kOutputLimit;
    final double truncationRate = truncationEvents / logs.length;
    final double immediateSpike = latestTruncated ? 15.0 : 0.0;

    final double totalCP = turnsWeight + 
                         (inputPressure * 50.0) + 
                         (outputPressure * 50.0) + 
                         (truncationRate * 40.0) + 
                         immediateSpike;

    return ContextState(
      cus: totalCP.clamp(0.0, 100.0),
      tokens: totalPromptTokens + maxOutputTokens, // Combined estimation for reporting
      turns: logs.length,
      outputUtilization: outputPressure.clamp(0.0, 1.0),
      maxTokensDetected: truncationEvents > 0,
      detail: {
        'deterministic_cus': true,
        'input_pressure': inputPressure.toStringAsFixed(3),
        'output_pressure': outputPressure.toStringAsFixed(3),
        'truncation_rate': truncationRate.toStringAsFixed(3),
        'immediate_spike': immediateSpike > 0,
        'turns_weight': turnsWeight.toStringAsFixed(1),
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
        // S30-REV: Softer time penalty (30m per point, max 10)
        timePenalty = (diff / 30.0).clamp(0.0, 10.0);
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
