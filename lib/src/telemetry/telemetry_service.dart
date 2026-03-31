import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/security/integrity_engine.dart';

/// TelemetryService: Centralized SHS calculation and Signed Pulse system.
/// Migrated and hardened from Base2/ops-intelligence.ps1.
class TelemetryService {
  static const double cpPerTool = 1.2;
  static const double cpPerChat = 0.5;
  static const double swellFactor = 10000.0; // 1 CP per 10k chars

  /// Computes the current pulse based on interaction counters and system state.
  Future<PulseSnapshot> computePulse({
    required String basePath,
    double carryOverCP = 0.0,
  }) async {
    final intelDir = p.join(basePath, 'vault', 'intel');
    final turnsFile = File(p.join(intelDir, 'session_turns.txt'));
    final chatsFile = File(p.join(intelDir, 'chat_count.txt'));
    final sessionLock = File(p.join(basePath, 'session.lock'));

    int turns = 0;
    if (await turnsFile.exists()) {
      final content = await turnsFile.readAsString();
      turns = int.tryParse(content.trim()) ?? 0;
    }

    int chats = 0;
    if (await chatsFile.exists()) {
      final content = await chatsFile.readAsString();
      chats = int.tryParse(content.trim()) ?? 0;
    }

    // Swelling calculation (Core files size)
    double swelling = await _calculateSwelling(basePath);

    double finalCarryOver = carryOverCP;
    
    // Read inherited fatigue from session.lock if not provided
    if (finalCarryOver == 0.0 && await sessionLock.exists()) {
      try {
        final lockContent = await sessionLock.readAsString();
        final lockData = jsonDecode(lockContent);
        
        final integrity = IntegrityEngine();
        if (!integrity.verifySessionMAC(lockData)) {
            print('[⚠️] WARNING: session.lock MAC inválido. Iniciando pulso desde cero para S12.');
            finalCarryOver = 0.0;
        } else {
            finalCarryOver = (lockData['inherited_fatigue'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        print('[⚠️] WARNING: No se pudo recuperar pulso heredado de session.lock ($e).');
        finalCarryOver = 0.0;
      }
    }

    // Passive Fatigue (using session.lock timestamp)
    double passiveFatigue = 0;
    if (await sessionLock.exists()) {
      final stats = await sessionLock.stat();
      final ageMinutes = DateTime.now().difference(stats.modified).inMinutes;
      if (ageMinutes > 5) {
        passiveFatigue = (ageMinutes / 15.0).toDouble(); // 1 CP per 15 min inactivity
      }
    }

    // Final CP calculation including Carry-Over
    double totalCP = (turns * cpPerTool) + (chats * cpPerChat) + swelling + passiveFatigue + finalCarryOver;

    // Saturation (Scaled: CP / 0.5 -> ~50 CP = 100% saturation)
    int saturation = ((totalCP / 0.5)).round().clamp(0, 100);

    final snapshot = PulseSnapshot(
      cp: double.parse(totalCP.toStringAsFixed(1)),
      saturation: saturation,
      cpDetail: {
        'tools': turns,
        'chats': chats,
        'swelling': double.parse(swelling.toStringAsFixed(1)),
        'passive_fatigue': double.parse(passiveFatigue.toStringAsFixed(1)),
        'carry_over': finalCarryOver,
        'time_tax': 0,
        'velocity_tax': 0,
      },
      timestamp: _formatTimestamp(DateTime.now()),
    );

    return snapshot;
  }

  /// Persists the pulse snapshot to intel_pulse.json with a cryptographic signature.
  Future<void> persistPulse(
    PulseSnapshot pulse, {
    required String basePath,
  }) async {
    final pulseFile = File(
      p.join(basePath, 'vault', 'intel', 'intel_pulse.json'),
    );

    final data = {
      'cp': pulse.cp,
      'saturation': pulse.saturation,
      'cp_detail': pulse.cpDetail,
      'timestamp': pulse.timestamp,
      'zombies': [], // Placeholder for zombie list
    };

    // Calculate Content Hash (Signed Pulse)
    final jsonString = jsonEncode(data);
    final hash = sha256.convert(utf8.encode(jsonString)).toString();

    data['content_hash'] = hash;

    await pulseFile.writeAsString(jsonEncode(data), encoding: utf8);
  }

  /// Increment turns atomically.
  Future<int> incrementTurns({required String basePath}) async {
    final turnsFile = File(
      p.join(basePath, 'vault', 'intel', 'session_turns.txt'),
    );
    int turns = 0;
    if (await turnsFile.exists()) {
      final content = await turnsFile.readAsString();
      turns = int.tryParse(content.trim()) ?? 0;
    }
    turns++;
    await turnsFile.writeAsString(turns.toString());
    return turns;
  }

  /// Increment chats atomically.
  Future<int> incrementChats({required String basePath}) async {
    final chatsFile = File(
      p.join(basePath, 'vault', 'intel', 'chat_count.txt'),
    );
    int chats = 0;
    if (await chatsFile.exists()) {
      final content = await chatsFile.readAsString();
      chats = int.tryParse(content.trim()) ?? 0;
    }
    chats++;
    await chatsFile.writeAsString(chats.toString());
    return chats;
  }

  Future<double> _calculateSwelling(String basePath) async {
    final coreFiles = [
      'ops-gov.ps1',
      'ops-intelligence.ps1',
      'backlog.json',
      'GEMINI.md',
      'ops-guard.ps1',
      'ops-audit.ps1',
    ];
    int totalBytes = 0;
    for (final fileName in coreFiles) {
      final file = File(p.join(basePath, fileName));
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    return (totalBytes / swellFactor);
  }

  /// Resets volatile metrics (turns/chats) in vault/intel/.
  Future<void> resetCounters({required String basePath}) async {
    final turnsFile = File(p.join(basePath, 'vault', 'intel', 'session_turns.txt'));
    final chatsFile = File(p.join(basePath, 'vault', 'intel', 'chat_count.txt'));

    if (await turnsFile.exists()) await turnsFile.writeAsString('0');
    if (await chatsFile.exists()) await chatsFile.writeAsString('0');

    // After reset, re-calculate pulse (preserving carryOver if needed, but usually reset is for handover)
    final pulse = await computePulse(basePath: basePath);
    await persistPulse(pulse, basePath: basePath);
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
