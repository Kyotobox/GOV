import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/security/integrity_engine.dart';

/// ForensicLedger: Implements a chained cryptographic log for HISTORY.md.
class ForensicLedger {
  final _integrity = IntegrityEngine();

  /// Appends a new entry to the history file, chaining it to the previous entry's hash.
  Future<void> appendEntry({
    required String sessionId,
    required String type, // EXEC | SNAP | ALERT | BASE
    required String task,
    required String detail,
    required String basePath,
    String? role,
  }) async {
    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    String prevHash = '0000000000000000000000000000000000000000000000000000000000000000';

    final effectiveRole = role ?? 'AI';

    print('DEBUG: ForensicLedger [${historyFile.absolute.path}] START_APPEND');

    // VUL-12: Implementamos bloqueo de archivo para evitar condiciones de carrera.
    final lockFile = File(p.join(basePath, 'vault', 'history.lock'));
    if (!await lockFile.parent.exists()) await lockFile.parent.create(recursive: true);
    final lockRaf = await lockFile.open(mode: FileMode.write);
    
    try {
      await lockRaf.lock(FileLock.blockingExclusive);

      if (await historyFile.exists()) {
        final lines = await historyFile.readAsLines();
        if (lines.isNotEmpty) {
          final lastLine = lines.lastWhere((l) => l.startsWith('|'), orElse: () => '');
          if (lastLine.isNotEmpty) {
            prevHash = _calculateLineHash(lastLine);
          }
        }
      } else {
        // Inicializar el Ledger si no existe
        final header = '| Timestamp | Role | SessionID | PrevHash | Type | Task | Detail |\n'
                       '| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n';
        await historyFile.writeAsString(header);
      }

      final timestamp = _formatTimestamp(DateTime.now());
      final entry = '| $timestamp | $effectiveRole | $sessionId | $prevHash | $type | $task | $detail |';
      
      await historyFile.writeAsString('$entry\n', mode: FileMode.append, flush: true);
      
      final currentHash = _calculateLineHash(entry);
      
      // VUL-11: Anclamos el hash del ledger en session.lock.
      await _integrity.updateLedgerAnchor(basePath: basePath, tipHash: currentHash);
      
      print('DEBUG: ForensicLedger [${historyFile.absolute.path}] APPEND_OK (Anchored: ${currentHash.substring(0, 8)})');

      // S24-SILVER: Auto-commit para mantener Git-Zero activo.
      try {
        await Process.run('git', ['add', 'HISTORY.md'], workingDirectory: basePath);
        await Process.run('git', ['commit', '-m', 'gov: ledger update [$type] $task'], workingDirectory: basePath);
      } catch (e) {
        print('DEBUG: Git auto-commit failed (Expected if not in repo): $e');
      }
    } finally {
      await lockRaf.unlock();
      await lockRaf.close();
    }
  }

  String _calculateLineHash(String line) {
    return sha256.convert(utf8.encode(line)).toString();
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
