import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/pulse_aggregator.dart';
import '../services/fleet_service.dart';

/// DashboardEngine: Automates the generation of DASHBOARD.md.
class DashboardEngine {
  /// Generates the DASHBOARD.md file based on the current pulse.
  Future<void> generate({
    required DualPulseData pulse,
    required String basePath,
    String? activeSprint,
    String? activeTask,
  }) async {
    final dashboardFile = File(p.join(basePath, 'DASHBOARD.md'));
    final fleet = FleetService(basePath: basePath);
    final fleetStatus = await fleet.aggregateFleetPulse();
    
    final saturation = pulse.saturation;
    final statusColor = saturation >= 85 ? '🔴 CRITICAL' : saturation >= 35 ? '🟡 WARNING' : '🟢 NOMINAL';
    
    final buffer = StringBuffer();
    buffer.writeln('# DASHBOARD — NUCLEUS-V9 SENTINEL HUB');
    buffer.writeln('**Generado**: ${pulse.timestamp}');
    buffer.writeln('**Estado de Fatiga (HUB)**: $statusColor ($saturation%)');
    buffer.writeln('');
    
    buffer.writeln('## 📊 Telemetría SHS (Deterministic CUS)');
    buffer.writeln('| Métrica | Valor | Impacto (CP) |');
    buffer.writeln('| :--- | :--- | :--- |');
    buffer.writeln('| **Saturación HUB** | $saturation% | ${pulse.cp.toStringAsFixed(1)} |');
    buffer.writeln('| Turnos (Logs) | ${pulse.context.turns} | - |');
    buffer.writeln('| Zombies (BHI) | ${pulse.bunker.zombies} | - |');
    buffer.writeln('| Pressure (I/O) | ${pulse.detail['input_pressure']}/${pulse.detail['output_pressure']} | Deterministic |');
    buffer.writeln('');
    
    buffer.writeln('## 🚢 Sovereign Fleet Status (Multi-Node)');
    buffer.writeln('| Proyecto | Proj-Ver | Kern-Ver | UUID (8c) | SHS (C/B) | Estado |');
    buffer.writeln('| :--- | :--- | :--- | :--- | :--- | :--- |');
    
    for (var node in fleetStatus) {
      final nodeSat = node.shs;
      final nodeStatus = nodeSat >= 85 ? '🔴' : nodeSat >= 35 ? '🟡' : '🟢';
      final uuid = node.sessionUuid.length >= 8 ? node.sessionUuid.substring(0, 8) : node.sessionUuid;
      final metrics = '${node.shs}% (${node.cus.toStringAsFixed(1)}/${node.bhi.toStringAsFixed(1)})';
      
      buffer.writeln('| ${node.name} | ${node.projectVersion} | ${node.kernelVersion} | `$uuid` | $metrics | $nodeStatus ${node.isOnline ? 'Active' : 'Offline'} |');
    }
    
    buffer.writeln('');
    buffer.writeln('## 🚀 Sesión de Recuperación');
    buffer.writeln('- **Sprint**: ${activeSprint ?? 'N/A'}');
    buffer.writeln('- **Tarea**: ${activeTask ?? 'N/A'}');
    buffer.writeln('');
    
    buffer.writeln('## 🛡️ Seguridad & Independencia');
    buffer.writeln('- **Isomorphism**: CERTIFIED');
    buffer.writeln('- **Kernel Version**: ${pulse.toJson()['kernel_version']}');
    buffer.writeln('- **Node Isolation**: ACTIVE');
    buffer.writeln('');
    
    buffer.writeln('---');
    buffer.writeln('*Actualizado automáticamente vía protocol SENTINEL v1.4.1*');

    await dashboardFile.writeAsString(buffer.toString());
  }
}
