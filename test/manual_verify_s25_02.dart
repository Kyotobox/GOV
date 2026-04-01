import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';

void main() async {
  final tmpPath = p.join(Directory.systemTemp.path, 'antigravity_manual_test_${DateTime.now().millisecondsSinceEpoch}');
  final intelDir = Directory(p.join(tmpPath, 'vault', 'intel'));
  intelDir.createSync(recursive: true);
  
  File(p.join(intelDir.path, 'session_turns.txt')).writeAsStringSync('0');
  File(p.join(intelDir.path, 'chat_count.txt')).writeAsStringSync('0');

  print('Testing incrementTurns...');
  final service = TelemetryService(basePath: tmpPath);
  await service.incrementTurns(basePath: tmpPath);
  await service.incrementTurns(basePath: tmpPath);
  await service.incrementTurns(basePath: tmpPath);
  
  final content = File(p.join(tmpPath, 'vault', 'intel', 'session_turns.txt')).readAsStringSync();
  if (int.parse(content.trim()) == 3) {
    print('SUCCESS: incrementTurns updated correctly to 3');
  } else {
    print('FAILURE: incrementTurns updated to $content');
    exit(1);
  }

  print('Testing resetCounters...');
  await service.resetCounters(basePath: tmpPath);
  final resetContent = File(p.join(tmpPath, 'vault', 'intel', 'session_turns.txt')).readAsStringSync();
  if (resetContent.trim() == '0') {
    print('SUCCESS: resetCounters reset correctly to 0');
  } else {
    print('FAILURE: resetCounters failed to reset, value is $resetContent');
    exit(1);
  }

  // Cleanup
  Directory(tmpPath).deleteSync(recursive: true);
  print('All tests passed!');
}
