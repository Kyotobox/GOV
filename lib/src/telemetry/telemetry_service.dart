import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'session_logger.dart';

/// TelemetryService: Centralized SHS calculation and Structured interaction logging.
/// S28-02: Migrated and hardened for NUCLEUS-V9 (v9.0.0).
class TelemetryService {
  static const double swellFactor = 10000.0; // 1 CP per 10k chars

  late final SessionLogger _logger;

  TelemetryService({required String basePath}) {
    _logger = SessionLogger(basePath: basePath);
  }

  /// Persists the pulse snapshot to intel_pulse.json with a cryptographic signature.
  /// [HARMONIZED] Includes legacy keys for Vanguard Agent UI compatibility.
  Future<void> persistPulse(
    PulseSnapshot pulse, {
    required String basePath,
  }) async {
    final pulseFile = File(
      p.join(basePath, 'vault', 'intel', 'intel_pulse.json'),
    );

    final data = {
      // --- NUCLEUS-V9 Atomic ---
      'cp': pulse.cp,
      'saturation': pulse.saturation,
      'cp_detail': pulse.cpDetail,
      'timestamp': pulse.timestamp,
      
      // --- LEGACY COMPATIBILITY (Unblinding Vanguard Agent) ---
      'shs_pulse': pulse.saturation,
      'cp_fatigue': pulse.cp,
      'zombies': pulse.cpDetail['zombies'] ?? 0,
      'context': {
        'cus': pulse.cp,
        'tokens': pulse.cpDetail['estimated_tokens'],
        'max_tokens_detected': pulse.cpDetail['max_tokens_detected'],
      },
      'hygiene': {
        'bhi': pulse.cpDetail['bhi'],
        'zombies': pulse.cpDetail['zombies'],
        'detail': pulse.cpDetail['structural'],
      }
    };

    // Calculate Content Hash (Signed Pulse)
    final jsonString = jsonEncode(data);
    final hash = sha256.convert(utf8.encode(jsonString)).toString();
    data['content_hash'] = hash;

    await pulseFile.writeAsString(jsonEncode(data), encoding: utf8);
  }

  /// Increment turns atomically.
  Future<int> incrementTurns({required String basePath}) async {
    final turnsFile = File(p.join(basePath, 'vault', 'intel', 'session_turns.txt'));
    int turns = 0;
    if (await turnsFile.exists()) {
      final content = await turnsFile.readAsString();
      turns = int.tryParse(content.trim()) ?? 0;
    }
    turns++;
    await turnsFile.writeAsString(turns.toString());
    
    // [HOT-CAPTURE] S29-02
    await _logger.captureInteraction(type: 'TOOL', detail: 'Turno incremental detectado.');
    
    return turns;
  }

  /// Increment chats atomically.
  Future<int> incrementChats({required String basePath}) async {
    final chatsFile = File(p.join(basePath, 'vault', 'intel', 'chat_count.txt'));
    int chats = 0;
    if (await chatsFile.exists()) {
      final content = await chatsFile.readAsString();
      chats = int.tryParse(content.trim()) ?? 0;
    }
    chats++;
    await chatsFile.writeAsString(chats.toString());

    // [HOT-CAPTURE] S29-02
    await _logger.captureInteraction(type: 'CHAT', detail: 'Chat detectado.');

    return chats;
  }

  /// Resets volatile metrics in vault/intel/.
  Future<void> resetCounters({required String basePath}) async {
    final holdFile = File(p.join(basePath, '.meta', 'SECURITY_HOLD'));
    if (holdFile.existsSync()) {
      throw Exception('[CRITICAL] SECURITY_HOLD activo. Reseteo de contadores denegado.');
    }

    final turnsFile = File(p.join(basePath, 'vault', 'intel', 'session_turns.txt'));
    final chatsFile = File(p.join(basePath, 'vault', 'intel', 'chat_count.txt'));

    if (await turnsFile.exists()) await turnsFile.writeAsString('0');
    if (await chatsFile.exists()) await chatsFile.writeAsString('0');

    // [HOT-CAPTURE] S29-02
    await _logger.resetLog();
  }
}

class PulseSnapshot {
  final double cp;
  final int saturation;
  final Map<String, dynamic> cpDetail;
  final String timestamp;

  PulseSnapshot({
    required this.cp,
    required this.saturation,
    required this.cpDetail,
    required this.timestamp,
  });
}

class ContextState {
  final double cus;
  final int tokens;
  final int turns;
  final double outputUtilization;
  final bool maxTokensDetected;
  final Map<String, dynamic> detail;

  ContextState({
    required this.cus,
    required this.tokens,
    required this.turns,
    this.outputUtilization = 0.0,
    this.maxTokensDetected = false,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'cus': cus,
    'tokens': tokens,
    'turns': turns,
    'output_utilization': outputUtilization,
    'max_tokens_detected': maxTokensDetected,
    'detail': detail,
  };
}

class BunkerHealthState {
  final double bhi; 
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

// Engines migrated to lib/src/services/pulse_aggregator.dart
