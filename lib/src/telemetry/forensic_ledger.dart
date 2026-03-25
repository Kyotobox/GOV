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

    if (await historyFile.exists()) {
      final lines = await historyFile.readAsLines();
      if (lines.isNotEmpty) {
        final lastLine = lines.lastWhere((l) => l.startsWith('|'), orElse: () => '');
        if (lastLine.isNotEmpty) {
          prevHash = _calculateLineHash(lastLine);
        }
      }
    } else {
      // Create with header if not exists
      await historyFile.writeAsString(
        '| Timestamp | SessionID | PrevHash | Type | Task | Detail |\n'
        '| :--- | :--- | :--- | :--- | :--- | :--- |\n',
        mode: FileMode.write,
      );
    }

    final timestamp = _formatTimestamp(DateTime.now());
    final entry = '| $timestamp | $sessionId | $prevHash | $type | $task | $detail |';
    
    await historyFile.writeAsString('$entry\n', mode: FileMode.append);
  }

  /// Verifies the entire hash chain of the history file.
  Future<List<int>> verifyChain({required String basePath}) async {
    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    if (!await historyFile.exists()) return [];

    final lines = await historyFile.readAsLines();
    final dataLines = lines.where((l) => l.startsWith('|') && !l.contains(':---') && !l.contains('Timestamp')).toList();
    
    List<int> corruptedLines = [];
    String expectedPrevHash = '0000000000000000000000000000000000000000000000000000000000000000';

    for (int i = 0; i < dataLines.length; i++) {
        final line = dataLines[i];
        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.length < 7) {
          corruptedLines.add(i);
          continue;
        }

        final actualPrevHash = parts[3];
        if (actualPrevHash != expectedPrevHash) {
          corruptedLines.add(i);
        }
        
        expectedPrevHash = _calculateLineHash(line);
    }

    return corruptedLines;
  }

  String _calculateLineHash(String line) {
    return sha256.convert(utf8.encode(line)).toString();
  }

  String _formatTimestamp(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
