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

    test('calculatePulse should return expected fields in detail for v5.4', () async {
      // 1. Create a "recent" file
      final libFile = File(p.join(tempDir.path, 'lib', 'main.dart'));
      await libFile.writeAsString('void main() {}');
      
      // 2. Calculate pulse
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // 3. Verify v5.4 fields
      expect(pulse.detail.containsKey('cooling_relief'), isTrue);
      expect(pulse.detail.containsKey('active_minutes'), isTrue);
      expect(pulse.detail['time_tax'], isNotNull);
    });

    test('calculatePulse should accurately reflect time_tax penalties', () async {
      // Setup session_pulse with 30 active minutes
      final pulseFile = File(p.join(tempDir.path, '.meta', 'session_pulse.json'));
      await pulseFile.writeAsString('{"active_minutes": 30.0, "total_actions": 5}');
      
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // timePenalty = (30 / 10).roundToDouble() = 3.0
      expect(pulse.detail['time_tax'], 3.0);
    });

    test('calculatePulse should apply strategic relief if SHS > 70', () async {
      // Mock high SHS by adding many actions or zombies if needed, 
      // but let's just check the logic branch.
      // We need currentShs > 70.
      // currentBaseCp = toolCpValue + cpChats + cpEnvironment + timePenalty
      // Let's create many zombies to force high SHS.
      for (int i = 0; i < 30; i++) {
        await File(p.join(tempDir.path, 'zombie_$i.tmp')).create();
      }
      
      // Also mark a task done
      final taskFile = File(p.join(tempDir.path, 'task.md'));
      await taskFile.writeAsString('# Tasks\n- [x] Done Task (TASK-1)');
      
      final pulse = await engine.calculatePulse(tempDir.path);
      
      // SHS should be > 70 due to 30 zombies (30 * 1.5 = 45 CP) 
      // plus environment (30 files / 18 * 100 / 2 = 83/2 = 41 CP) -> CP ~ 86 -> SHS ~ 172%
      expect(pulse.saturation, greaterThan(70));
      expect(pulse.detail['relief'], lessThan(0)); // Relief should be active
    });
  });
}
