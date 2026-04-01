import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/services/pulse_aggregator.dart';
import 'package:antigravity_dpi/src/telemetry/session_logger.dart';

void main() {
  group('PulseAggregator Service [NUCLEUS-V9]', () {
    late Directory tempDir;
    late PulseAggregator aggregator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pulse_test_');
      aggregator = PulseAggregator(tempDir.path);
      
      // Setup vault/intel and .meta
      await Directory(p.join(tempDir.path, 'vault', 'intel')).create(recursive: true);
      await Directory(p.join(tempDir.path, '.meta')).create(recursive: true);
    });

    tearDown(() async {
      final dir = Directory(tempDir.path);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    test('calculatePulse should return valid DualPulseData', () async {
      final pulse = await aggregator.calculatePulse();
      
      expect(pulse.saturation, isNotNull);
      expect(pulse.context.cus, equals(0.0)); // No logs yet
      expect(pulse.bunker.bhi, isNotNull);
      expect(pulse.timestamp, isNotEmpty);
    });

    test('persistPulse should write signed json to vault/intel', () async {
      final pulse = await aggregator.calculatePulse();
      await aggregator.persistPulse(pulse);
      
      final file = File(p.join(tempDir.path, 'vault', 'intel', 'intel_pulse.json'));
      expect(await file.exists(), isTrue);
      
      final data = jsonDecode(await file.readAsString());
      expect(data['shs_pulse'], equals(pulse.saturation));
      expect(data['content_hash'], isNotNull);
    });
  });
}
