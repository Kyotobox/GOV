import 'dart:async';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import '../telemetry/telemetry_service.dart';
import '../dash/dashboard_engine.dart';

/// Monitor: Implements the Watch Mode for real-time telemetry and dashboard syncing.
class TelemetryMonitor {
  final TelemetryService _telemetry = TelemetryService();
  final DashboardEngine _dashboard = DashboardEngine();
  StreamSubscription? _subscription;

  /// Starts watching vault/intel for changes to trigger dashboard updates.
  void start({required String basePath}) {
    final intelPath = p.join(basePath, 'vault', 'intel');
    final watcher = DirectoryWatcher(intelPath);

    _subscription = watcher.events.listen((event) async {
      // Trigger update on turn/chat count change or pulse change
      if (event.path.endsWith('session_turns.txt') || 
          event.path.endsWith('chat_count.txt') ||
          event.path.endsWith('intel_pulse.json')) {
        
        final pulse = await _telemetry.computePulse(basePath: basePath);
        await _dashboard.generate(pulse: pulse, basePath: basePath);
        print('[TELEMETRY] Dashboard updated via watch event: ${event.type} on ${event.path}');
      }
    });
    
    print('[WATCHER] Monitoring $intelPath for telemetry changes...');
  }

  void stop() {
    _subscription?.cancel();
  }
}
