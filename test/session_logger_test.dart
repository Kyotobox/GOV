import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/telemetry/session_logger.dart';

void main() {
  late String tmpPath;
  late SessionLogger logger;

  setUp(() {
    tmpPath = p.join(Directory.systemTemp.path, 'session_logger_test_${DateTime.now().millisecondsSinceEpoch}');
    final intelDir = Directory(p.join(tmpPath, 'vault', 'intel'));
    intelDir.createSync(recursive: true);
    logger = SessionLogger(basePath: tmpPath);
  });

  tearDown(() {
    final dir = Directory(tmpPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  test('captureInteraction should append detailed entries to sessionLog.json', () async {
    await logger.captureInteraction(type: 'TOOL', detail: 'Test Action', tokens: 100);
    await logger.captureInteraction(type: 'CHAT', detail: 'User Message', tokens: 50);

    final logFile = File(p.join(tmpPath, 'vault', 'intel', 'sessionLog.json'));
    expect(await logFile.exists(), isTrue);

    final content = await logFile.readAsString();
    final List<dynamic> logs = jsonDecode(content);

    expect(logs.length, equals(2));
    expect(logs[0]['type'], equals('TOOL'));
    expect(logs[0]['detail'], equals('Test Action'));
    expect(logs[0]['tokens'], equals(100));
    expect(logs[1]['type'], equals('CHAT'));
    expect(logs[1]['detail'], equals('User Message'));
    expect(logs[1]['tokens'], equals(50));
    
    // Check hash chaining
    expect(logs[1]['prev_hash'], isNot(equals('00000000')));
  });

  test('getStats should aggregate session interaction correctly', () async {
    await logger.captureInteraction(type: 'TOOL', tokens: 100);
    await logger.captureInteraction(type: 'TOOL', tokens: 200);
    await logger.captureInteraction(type: 'CHAT', tokens: 50);

    final stats = await logger.getStats();
    expect(stats['tools'], equals(2));
    expect(stats['chats'], equals(1));
    expect(stats['estimated_tokens'], equals(350));
  });

  test('resetLog should delete the sessionLog file', () async {
    await logger.captureInteraction(type: 'TOOL');
    final logFile = File(p.join(tmpPath, 'vault', 'intel', 'sessionLog.json'));
    expect(await logFile.exists(), isTrue);

    await logger.resetLog();
    expect(await logFile.exists(), isFalse);
  });
}
