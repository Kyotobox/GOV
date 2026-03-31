import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/kernel/gov.dart'; // This might need a change if not exported or if it causes issues.

void main() {
  group('CognitiveEngine [Passive Tax Refactor]', () {
    late Directory tempDir;
    late CognitiveEngine engine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gov_test_');
      engine = CognitiveEngine();
      
      // Setup minimal structure for Baseline scan
      await Directory(p.join(tempDir.path, 'lib')).create();
      await Directory(p.join(tempDir.path, 'test')).create();
      
      // Setup necessary .meta directory for calculatePulse
      await Directory(p.join(tempDir.path, '.meta')).create();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('calculatePulse should return expected fields in detail for v8.2', () async {
      // 1. Create a "recent" file
      final libFile = File(p.join(tempDir.path, 'lib', 'main.dart'));
      await libFile.writeAsString('void main() {}');
      
      // 2. Setup atomic counters
      final intelDir = Directory(p.join(tempDir.path, 'vault', 'intel'));
      await intelDir.create(recursive: true);
      await File(p.join(intelDir.path, 'session_turns.txt')).writeAsString('5');
      
      // 3. Calculate pulse
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // 4. Verify v8.2 fields
      expect(pulse.context.detail.containsKey('tool_load'), isTrue);
      expect(pulse.context.detail.containsKey('ai_turns'), isTrue);
      expect(pulse.bunker.detail.containsKey('dna_intact'), isTrue);
      expect(pulse.bunker.detail.containsKey('integrity_penalty'), isTrue);
    });

    test('calculatePulse should accurately reflect atomic turns in CUS', () async {
      final intelDir = Directory(p.join(tempDir.path, 'vault', 'intel'));
      await intelDir.create(recursive: true);
      await File(p.join(intelDir.path, 'session_turns.txt')).writeAsString('10');
      
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // tool_load = 10 * 1.2 = 12.0
      expect(pulse.context.detail['tool_load'], 12.0);
      expect(pulse.context.cus, 12.0);
    });

    test('calculatePulse should apply 70% penalty if DNA seal is missing', () async {
      // 1. Crear un binario dummy en la raíz para forzar el check de ADN
      await File(p.join(tempDir.path, 'gov.exe')).writeAsString('DUMMY BINARY');
      
      // 2. Calcular pulso usando tempDir como root real del búnker
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // BHI debe ser al menos 70 si dna_intact es false
      expect(pulse.bunker.detail['dna_intact'], isFalse);
      expect(pulse.bunker.bhi, greaterThanOrEqualTo(70.0));
    });
  });
}
