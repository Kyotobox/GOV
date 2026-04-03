import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

/// [Hot-Capture Interceptor]
/// Structured session logging for NUCLEUS-V9.
/// Persists detailed interaction history to enable deterministic context pressure.
class SessionLogger {
  final String basePath;

  SessionLogger({required this.basePath});

  File get _logFile => File(p.join(basePath, 'vault', 'intel', 'session_log.json'));

  /// Captures a granular interaction and appends it to the volatile session log.
  Future<void> captureInteraction({
    required String type, // 'TOOL' | 'CHAT' | 'SYSTEM'
    String? detail,
    int tokens = 0,
    int promptTokens = 0,
    int outputTokens = 0,
    String? finishReason,
  }) async {
    List<Map<String, dynamic>> logs = await loadLogs();

    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'type': type.toUpperCase(),
      'detail': detail ?? 'N/A',
      'tokens': tokens > 0 ? tokens : (promptTokens + outputTokens),
      'prompt_tokens': promptTokens,
      'output_tokens': outputTokens,
      'finish_reason': finishReason ?? 'stop',
      // S29-SECURITY: Fingerprint for log-chaining (Local Integrity)
      'prev_hash': logs.isEmpty ? '00000000' : _calculateHash(logs.last),
    };

    logs.add(entry);

    if (!_logFile.parent.existsSync()) {
      _logFile.parent.createSync(recursive: true);
    }

    await _logFile.writeAsString(JsonEncoder.withIndent('  ').convert(logs), encoding: utf8);
  }

  /// Loads the entire current session history.
  Future<List<Map<String, dynamic>>> loadLogs() async {
    if (!await _logFile.exists()) return [];
    try {
      final content = await _logFile.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[WARN] SessionLog corrupto o inaccesible ($e). Re-inicializando.');
      return [];
    }
  }

  /// Resets the log (Volatile Lifecycle: Handover/Takeover).
  Future<void> resetLog() async {
    if (await _logFile.exists()) {
      await _logFile.delete();
    }
    print('[DNA-HOT-CAPTURE] SessionLog purgado con éxito.');
  }

  /// Calculates the hash of a single log entry for chaining.
  String _calculateHash(Map<String, dynamic> entry) {
    final bytes = utf8.encode(jsonEncode(entry));
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Returns aggregated stats for the current session.
  Future<Map<String, dynamic>> getStats() async {
    final logs = await loadLogs();
    int tools = logs.where((e) => e['type'] == 'TOOL').length;
    int chats = logs.where((e) => e['type'] == 'CHAT').length;
    int totalTokens = logs.fold(0, (sum, e) => sum + (e['tokens'] as int? ?? 0));
    
    return {
      'entry_count': logs.length,
      'tools': tools,
      'chats': chats,
      'estimated_tokens': totalTokens,
    };
  }
}
