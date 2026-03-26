import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// ForensicLedger: Implements a chained cryptographic log for HISTORY.md.
class ForensicLedger {
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

    if (await historyFile.exists()) {
      final lines = await historyFile.readAsLines();
      if (lines.isNotEmpty) {
        final lastLine = lines.lastWhere((l) => l.startsWith('|'), orElse: () => '');
        if (lastLine.isNotEmpty) {
          prevHash = _calculateLineHash(lastLine);
        }
      }
    } else {
      await historyFile.writeAsString(
        '| Timestamp | SessionID | PrevHash | Type | Task | Detail |\n'
        '| :--- | :--- | :--- | :--- | :--- | :--- |\n',
        mode: FileMode.write,
      );
    }

    final timestamp = _formatTimestamp(DateTime.now());
    final entry = '| $timestamp | $sessionId | $prevHash | $type | $task | $detail |';
    
    final sink = historyFile.openWrite(mode: FileMode.append);
    sink.writeln(entry);
    await sink.flush();
    await sink.close();
    print('DEBUG: ForensicLedger [${historyFile.absolute.path}] APPEND_OK');
  }

  String _calculateLineHash(String line) {
    return sha256.convert(utf8.encode(line)).toString();
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
