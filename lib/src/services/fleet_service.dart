import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

/// FleetService: Aggregates telemetry from multiple nodes in the Base2 ecosystem.
/// S28-02: Orchestration logic migrated from the kernel.
class FleetService {
  final String _basePath;

  FleetService({required String basePath}) : _basePath = basePath;

  /// Aggregates pulse data from all projects registered in fleet_registry.json.
  Future<List<FleetNodeState>> aggregateFleetPulse() async {
    final registryFile = File(p.join(_basePath, 'vault', 'intel', 'fleet_registry.json'));
    if (!await registryFile.exists()) return [];

    final List<FleetNodeState> states = [];
    try {
      final String content = await registryFile.readAsString();
      if (content.isEmpty) return [];
      
      final registry = jsonDecode(content);
      final projects = registry['projects'] as List;

      for (var proj in projects) {
        final projPath = proj['path'] as String;
        final name = proj['name'] as String;
        
        try {
          final pulseFile = File(p.join(projPath, 'vault', 'intel', 'intel_pulse.json'));

          if (await pulseFile.exists()) {
            final pulseData = jsonDecode(await pulseFile.readAsString());
            final cpDetail = pulseData['cp_detail'] as Map<String, dynamic>? ?? {};
            
            // S30-SEP: Recover versions independently from backlog
            final backlogFile = File(p.join(projPath, 'backlog.json'));
            String projectVersion = 'N/A';
            if (await backlogFile.exists()) {
              try {
                final backlog = jsonDecode(await backlogFile.readAsString());
                projectVersion = backlog['version'] as String? ?? 'N/A';
              } catch (_) {}
            }

            final nodeState = FleetNodeState(
              name: name,
              path: projPath,
              shs: (pulseData['saturation'] as num?)?.toInt() ?? 0,
              cus: (pulseData['cp'] as num?)?.toDouble() ?? 0.0,
              bhi: (cpDetail['bhi'] as num?)?.toDouble() ?? 0.0,
              kernelVersion: pulseData['kernel_version'] as String? ?? '9.1.0',
              projectVersion: projectVersion,
              sessionUuid: pulseData['session_uuid'] as String? ?? 'MANUAL',
              isOnline: true,
              isSovereign: cpDetail['deterministic_cus'] == true,
              lastSeen: pulseData['timestamp'] as String?,
            );
            states.add(nodeState);
          } else {
            states.add(FleetNodeState(name: name, path: projPath, isOnline: false));
          }
        } catch (e) {
          states.add(FleetNodeState(name: name, path: projPath, isOnline: false));
        }
      }
      return states;
    } catch (e) {
      return states;
    }
  }

  /// Registers a new project in the fleet registry.
  Future<void> registerProject({required String name, required String path}) async {
    final registryFile = File(p.join(_basePath, 'vault', 'intel', 'fleet_registry.json'));
    Map<String, dynamic> registry = {"projects": []};
    if (await registryFile.exists()) {
      try {
        final content = await registryFile.readAsString();
        if (content.isNotEmpty) {
          registry = jsonDecode(content);
        }
      } catch (_) {}
    }
    
    final projects = registry['projects'] as List;
    // Normalized comparison to avoid case-sensitivity issues on Windows
    final bool alreadyExists = projects.any((p) => p['path'].toString().toLowerCase() == path.toLowerCase());
    
    if (!alreadyExists) {
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
  final double cus;
  final double bhi;
  final String kernelVersion;
  final String projectVersion;
  final String sessionUuid;
  final bool isOnline;
  final bool isSovereign;
  final String? lastSeen;

  FleetNodeState({
    required this.name,
    required this.path,
    this.shs = 0,
    this.cus = 0.0,
    this.bhi = 0.0,
    this.kernelVersion = 'N/A',
    this.projectVersion = 'N/A',
    this.sessionUuid = 'UNKNOWN',
    required this.isOnline,
    this.isSovereign = false,
    this.lastSeen,
  });
}
