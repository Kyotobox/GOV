import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/pulse_aggregator.dart';

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
    
    final saturation = pulse.saturation;
    final statusColor = saturation > 85 ? '🔴 CRITICAL' : saturation > 50 ? '🟡 WARNING' : '🟢 OPTIMAL';
    
    final buffer = StringBuffer();
    buffer.writeln('# DASHBOARD — Base2 Kernel DPI');
    buffer.writeln('**Generado**: ${pulse.timestamp}');
    buffer.writeln('**Estado de Fatiga**: $statusColor');
    buffer.writeln('');
    
    buffer.writeln('## 📊 Telemetría SHS (Real-Time)');
    buffer.writeln('| Métrica | Valor | Impacto (CP) |');
    buffer.writeln('| :--- | :--- | :--- |');
    buffer.writeln('| **Saturación** | $saturation% | ${pulse.cp.toStringAsFixed(1)} |');
    buffer.writeln('| Turnos (Tools) | ${pulse.context.turns} | - |');
    buffer.writeln('| Zombies | ${pulse.bunker.zombies} | - |');
    buffer.writeln('');
    
    buffer.writeln('## 🚀 Sesión Actual');
    buffer.writeln('- **Sprint**: ${activeSprint ?? 'N/A'}');
    buffer.writeln('- **Tarea**: ${activeTask ?? 'N/A'}');
    buffer.writeln('');
    
    buffer.writeln('## 🛡️ Seguridad & Integridad');
    buffer.writeln('- **SHS Pulse**: ${pulse.saturation}%');
    buffer.writeln('- **Kernel Guard**: LOCKED');
    buffer.writeln('');
    
    buffer.writeln('---');
    buffer.writeln('*Actualizado automáticamente vía gov watch*');

    await dashboardFile.writeAsString(buffer.toString());
  }
}
