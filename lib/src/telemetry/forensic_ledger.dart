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
  }) async {
    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    String prevHash = '0000000000000000000000000000000000000000000000000000000000000000';

    print('DEBUG: ForensicLedger [${historyFile.absolute.path}] START_APPEND');

    // VUL-12: Implementamos bloqueo de archivo para evitar condiciones de carrera.
    // Usamos un archivo de bloqueo externo para sincronizar la lectura y escritura del ledger.
    final lockFile = File(p.join(basePath, 'vault', 'history.lock'));
    if (!await lockFile.parent.exists()) await lockFile.parent.create(recursive: true);
    final lockRaf = await lockFile.open(mode: FileMode.write);
    
    try {
      await lockRaf.lock(FileLock.blockingExclusive);

      // Leemos el archivo para obtener el último hash de forma segura bajo el lock.
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
        final header = '| Timestamp | SessionID | PrevHash | Type | Task | Detail |\n'
                       '| :--- | :--- | :--- | :--- | :--- | :--- |\n';
        await historyFile.writeAsString(header);
      }

      final timestamp = _formatTimestamp(DateTime.now());
      final entry = '| $timestamp | $sessionId | $prevHash | $type | $task | $detail |';
      
      await historyFile.writeAsString('$entry\n', mode: FileMode.append, flush: true);
      
      final currentHash = _calculateLineHash(entry);
      
      // VUL-11: Anclamos el hash del ledger en session.lock.
      await _integrity.updateLedgerAnchor(basePath: basePath, tipHash: currentHash);
      
      print('DEBUG: ForensicLedger [${historyFile.absolute.path}] APPEND_OK (Anchored: ${currentHash.substring(0, 8)})');
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
