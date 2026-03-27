import 'dart:io';
import 'package:path/path.dart' as p;

class ReportEngine {
  Future<String> generateExecutiveReport(String basePath) async {
    final historyFile = File(p.join(basePath, 'HISTORY.md'));
    if (!historyFile.existsSync()) return '# Error: HISTORY.md no encontrado';

    final lines = await historyFile.readAsLines();
    final dataLines = lines.where((l) => l.startsWith('|') && !l.contains('Timestamp') && !l.contains(':---')).toList();

    final Map<String, double> cpByRole = {};
    int baselineCount = 0;
    int alertCount = 0;
    int restoreCount = 0;

    for (var line in dataLines) {
      final parts = line.split('|').map((e) => e.trim()).toList();
      if (parts.length < 8) continue;

      final role = parts[2];
      final type = parts[5];
      final task = parts[6];

      // Estimación de CP (0.5 por SNAP, 1.0 por BASE o según detalle)
      double cp = (type == 'BASE') ? 1.0 : 0.5;
      cpByRole[role] = (cpByRole[role] ?? 0) + cp;

      if (type == 'BASE') baselineCount++;
      if (type == 'ALERT') alertCount++;
      if (task == 'RESTORE') restoreCount++;
    }

    final buffer = StringBuffer();
    buffer.writeln('# Reporte Ejecutivo de Gobernanza Antigravity');
    buffer.writeln('Generado: ${DateTime.now().toString().substring(0, 19)}\n');
    
    buffer.writeln('## Resumen de Actividad');
    buffer.writeln('- **Baselines Sellados**: $baselineCount');
    buffer.writeln('- **Alertas de Seguridad**: $alertCount');
    buffer.writeln('- **Restauraciones (Auto-curación)**: $restoreCount\n');

    buffer.writeln('## Atribución de Puntos CP por Rol');
    cpByRole.forEach((role, cp) {
      buffer.writeln('- **$role**: ${cp.toStringAsFixed(1)} CP');
    });

    buffer.writeln('\n## Análisis de Integridad');
    if (alertCount > 0) {
      buffer.writeln('> [!WARNING]');
      buffer.writeln('> Se han detectado incidencias de seguridad en el ledger. Revisar historial detallado.');
    } else {
      buffer.writeln('> [!NOTE]');
      buffer.writeln('> El ledger de auditoría se mantiene íntegro y sin alertas críticas.');
    }

    return buffer.toString();
  }
}
