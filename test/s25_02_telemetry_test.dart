import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/telemetry/telemetry_service.dart';

void main() {
  late String tmpPath;

  setUp(() {
    tmpPath = p.join(Directory.systemTemp.path, 'antigravity_test_${DateTime.now().millisecondsSinceEpoch}');
    final intelDir = Directory(p.join(tmpPath, 'vault', 'intel'));
    intelDir.createSync(recursive: true);
    File(p.join(intelDir.path, 'session_turns.txt')).writeAsStringSync('0');
    File(p.join(intelDir.path, 'chat_count.txt')).writeAsStringSync('0');
  });

  tearDown(() {
    final dir = Directory(tmpPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('incrementTurns should update session_turns.txt atomically', () async {
    final service = TelemetryService(basePath: tmpPath);
    await service.incrementTurns(basePath: tmpPath);
    await service.incrementTurns(basePath: tmpPath);
    await service.incrementTurns(basePath: tmpPath);
    final content = File(p.join(tmpPath, 'vault', 'intel', 'session_turns.txt')).readAsStringSync();
    expect(int.parse(content.trim()), equals(3));
  });

  test('resetCounters should set session_turns.txt to 0', () async {
    final service = TelemetryService(basePath: tmpPath);
    await service.incrementTurns(basePath: tmpPath); // Simular 1 turno
    await service.resetCounters(basePath: tmpPath);
    final content = File(p.join(tmpPath, 'vault', 'intel', 'session_turns.txt')).readAsStringSync();
    expect(content.trim(), equals('0'));
  });
}
