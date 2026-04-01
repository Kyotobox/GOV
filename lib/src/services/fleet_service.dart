import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'pulse_aggregator.dart';

/// FleetService: Aggregates telemetry from multiple nodes in the Base2 ecosystem.
/// S28-02: Orchestration logic migrated from the kernel.
class FleetService {
  final String _basePath;

  FleetService({required String basePath}) : _basePath = basePath;

  /// Aggregates pulse data from all projects registered in fleet_registry.json.
  Future<List<FleetNodeState>> aggregateFleetPulse() async {
    final registryFile = File(p.join(_basePath, 'vault', 'intel', 'fleet_registry.json'));
    if (!await registryFile.exists()) return [];

    try {
      final registry = jsonDecode(await registryFile.readAsString());
      final projects = registry['projects'] as List;
      final List<FleetNodeState> states = [];

      for (var proj in projects) {
        final projPath = proj['path'] as String;
        final name = proj['name'] as String;
        final pulseFile = File(p.join(projPath, 'vault', 'intel', 'intel_pulse.json'));

        if (await pulseFile.exists()) {
          try {
            final pulseData = jsonDecode(await pulseFile.readAsString());
            states.add(FleetNodeState(
              name: name,
              path: projPath,
              shs: (pulseData['saturation'] as num).toInt(),
              isOnline: true,
              lastSeen: pulseData['timestamp'] as String,
            ));
          } catch (_) {
            states.add(FleetNodeState(name: name, path: projPath, isOnline: false));
          }
        } else {
          states.add(FleetNodeState(name: name, path: projPath, isOnline: false));
        }
      }
      return states;
    } catch (_) {
      return [];
    }
  }

  /// Registers a new project in the fleet registry.
  Future<void> registerProject({required String name, required String path}) async {
    final registryFile = File(p.join(_basePath, 'vault', 'intel', 'fleet_registry.json'));
    Map<String, dynamic> registry = {"projects": []};
    if (await registryFile.exists()) {
      registry = jsonDecode(await registryFile.readAsString());
    }
    
    final projects = registry['projects'] as List;
    if (!projects.any((p) => p['path'] == path)) {
      projects.add({
        "name": name,
        "path": path,
        "last_seen": DateTime.now().toIso8601String()
      });
      await registryFile.writeAsString(jsonEncode(registry));
    }
  }
}

/// Represents the status of a single node in the fleet.
class FleetNodeState {
  final String name;
  final String path;
  final int shs;
  final bool isOnline;
  final String? lastSeen;

  FleetNodeState({
    required this.name,
    required this.path,
    this.shs = 0,
    required this.isOnline,
    this.lastSeen,
  });
}
