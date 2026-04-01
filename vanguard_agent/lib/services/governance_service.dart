import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

/// Servicio de abstracción para comandos de gobernanza.
/// Permite el testing mediante mocks de la ejecución de binarios.
class GovernanceService {
  Future<ProcessResult> runGov(String rootPath, List<String> args) async {
    final govPath = _getGovPath(rootPath);
    return Process.run(govPath, args, workingDirectory: rootPath);
  }

  String _getGovPath(String root) {
    if (Platform.isWindows) {
      final binPath = p.join(root, 'bin', 'gov.exe');
      if (File(binPath).existsSync()) return binPath;
      return p.join(root, 'gov.exe');
    }
    return 'gov';
  }

  // [S25-05] Obtener ruta del Oráculo (antigravity_dpi)
  String getOracleRoot() {
    // Intentar desde la variable de entorno si existe (para dev)
    final envPath = Platform.environment['DPI_ORACLE_ROOT'];
    if (envPath != null) return envPath;

    // Fallback: Si estamos ejecutando desde el binario de Vanguard en el repo
    
    // Si estamos en un entorno de build de Flutter, puede ser complejo.
    // Para el entorno del usuario actual, asumimos que el Oráculo está en la ruta conocida
    // o calculada desde el workspace.
    return Directory.current.path; // Por defecto para el entorno de terminal
  }

  // [S25-05] Registrar el nuevo búnker en fleet_registry.json
  Future<void> registerInFleet({
    required String oracleRoot, 
    required String projectName, 
    required String projectPath
  }) async {
    final registryFile = File(p.join(oracleRoot, 'vault', 'intel', 'fleet_registry.json'));
    Map<String, dynamic> registry = {"bunkers": []};
    
    if (await registryFile.exists()) {
      try {
        registry = jsonDecode(await registryFile.readAsString());
      } catch (_) {}
    }
    
    final bunkers = (registry['bunkers'] ?? registry['projects'] ?? []) as List;
    if (!bunkers.any((b) => b['path'] == projectPath)) {
      bunkers.add({
        "name": projectName,
        "path": projectPath,
        "status": "ACTIVE",
        "adopted_at": DateTime.now().toIso8601String(),
      });
      registry['bunkers'] = bunkers;
      await registryFile.writeAsString(const JsonEncoder.withIndent('  ').convert(registry));
    }
  }
}
