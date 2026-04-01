import 'dart:async';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import '../services/pulse_aggregator.dart';
import '../dash/dashboard_engine.dart';
import 'telemetry_service.dart';

/// Monitor: Implements the Watch Mode for real-time telemetry and dashboard syncing.
class TelemetryMonitor {
  final String basePath;
  late final DashboardEngine _dashboard;
  late final TelemetryService _telemetry;

  TelemetryMonitor({required this.basePath}) {
    _dashboard = DashboardEngine();
    _telemetry = TelemetryService(basePath: basePath);
  }

  /// Starts the watcher on vault/intel/ and .meta/
  Future<void> start() async {
    final watcher = DirectoryWatcher(p.join(basePath));
    
    watcher.events.listen((event) async {
      if (event.path.endsWith('session_turns.txt') || 
          event.path.endsWith('chat_count.txt') ||
          event.path.endsWith('intel_pulse.json')) {
        
        final aggregator = PulseAggregator(basePath);
        final pulse = await aggregator.calculatePulse();
        await _dashboard.generate(pulse: pulse, basePath: basePath);
        print('[TELEMETRY] Dashboard updated via watch event: ${event.type} on ${event.path}');
      }
    });
  }
}
