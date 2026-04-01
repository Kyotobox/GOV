import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/services/pulse_aggregator.dart';
import 'package:antigravity_dpi/src/telemetry/session_logger.dart';

void main() {
  group('Atomic CUS v4.0 [NUCLEUS-V9]', () {
    late Directory tempDir;
    late ContextEngine engine;
    late SessionLogger logger;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gov_test_');
      engine = ContextEngine();
      logger = SessionLogger(basePath: tempDir.path);
      
      // Setup vault/intel
      await Directory(p.join(tempDir.path, 'vault', 'intel')).create(recursive: true);
    });

    tearDown(() async {
      final dir = Directory(tempDir.path);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    test('calculateCUS should detect MAX_TOKENS and spike CUS +45', () async {
      // Registrar una interacción de tipo TOOL con MAX_TOKENS
      await logger.captureInteraction(
        type: 'TOOL', 
        detail: 'REPLACE_FILE_CONTENT', 
        finishReason: 'MAX_TOKENS'
      );

      final state = await engine.calculateCUS(tempDir.path);

      expect(state.maxTokensDetected, isTrue);
      // CP Atómico: Base (2.2) + Penalty (45.0) = 47.2
      expect(state.cus, closeTo(47.2, 0.1));
    });

    test('calculateCUS should apply Friction Scaling when context > 80%', () async {
      // kContextWindow = 1,000,000. 80% = 800,000.
      await logger.captureInteraction(
        type: 'TOOL', 
        detail: 'COMMAND_RUN', 
        tokens: 900000 
      );

      final state = await engine.calculateCUS(tempDir.path);

      // contextRatio = 0.9. frictionIdx = (0.9 - 0.8) * 10 = 1.0. 
      // Multiplier = 1.0 + 1.0 = 2.0.
      // Base CP TOOL (COMMAND) = 1.5. Final CP = 1.5 * 2 = 3.0.
      expect(state.detail['friction_active'], isTrue);
      expect(state.cus, closeTo(3.0, 0.1));
    });

    test('calculateCUS should be Atomic (ignore time factors in this engine)', () async {
      await logger.captureInteraction(type: 'CHAT', detail: 'Hello');
      
      final state = await engine.calculateCUS(tempDir.path);
      // Chat = 0.7 CP (Base Atómica)
      expect(state.cus, equals(0.7));
    });
  });
}
