import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Architect Bootstrapper Integration Tests', () {
    late Directory tempDir;
    final String kernelRoot = Directory.current.path;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dpi_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('DPI-INIT: Should create S00-INCEPTION with BIZ/ARCH tasks', () async {
      final projectPath = p.join(tempDir.path, 'new_bunker');
      
      // Simular ejecución de gov init (llamamos a la lógica interna si fuera posible, 
      // pero aquí simulamos el efecto esperado para validar la estructura que el Kernel DEBE generar)
      // Nota: En una prueba de integración real, ejecutaríamos el binario. 
      // Como estamos validando la lógica recién inyectada, verificamos que el Kernel 
      // produzca los artefactos correctos.
      
      final result = await Process.run(
        'dart', 
        ['bin/antigravity_dpi.dart', 'init', projectPath, '--name', 'TestProject'],
        workingDirectory: kernelRoot,
        environment: {'DPI_GOV_DEV': 'true'},
      );

      expect(result.exitCode, 0, reason: 'Gov init falló.\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}');
      
      final backlogFile = File(p.join(projectPath, 'backlog.json'));
      expect(await backlogFile.exists(), isTrue);
      
      final Map<String, dynamic> backlog = jsonDecode(await backlogFile.readAsString());
      expect(backlog['current_sprint'], equals('S00-INCEPTION'));
      
      final sprint = (backlog['sprints'] as List).firstWhere((s) => s['id'] == 'S00-INCEPTION');
      expect(sprint['tasks'], hasLength(2));
      expect(sprint['tasks'][0]['label'], equals('BIZ'));
      expect(sprint['tasks'][0]['required_signatures'], contains('PO'));
      expect(sprint['tasks'][1]['label'], equals('ARCH'));
      expect(sprint['tasks'][1]['required_signatures'], contains('ARCH'));

      // Verificar roles.json
      final rolesFile = File(p.join(projectPath, 'vault', 'rules', 'roles.json'));
      expect(await rolesFile.exists(), isTrue);
      final rolesData = jsonDecode(await rolesFile.readAsString());
      expect(rolesData['roles'], contains('PO'));
      expect(rolesData['roles'], contains('ARCH'));

      // Verificar archivos físicos
      expect(await File(p.join(projectPath, '.meta', 'sprints', 'S00-INCEPTION', 'TASK-S00-01.md')).exists(), isTrue);
      expect(await File(p.join(projectPath, '.meta', 'sprints', 'S00-INCEPTION', 'TASK-S00-02.md')).exists(), isTrue);
    });

    test('DPI-ADOPT: Should detect gaps and create S01-ALIGNMENT', () async {
      final legacyPath = p.join(tempDir.path, 'legacy_project');
      await Directory(legacyPath).create();
      await File(p.join(legacyPath, 'pubspec.yaml')).writeAsString('name: legacy'); // Mínimo para ser detectado
      
      final result = await Process.run(
        'dart', 
        ['bin/antigravity_dpi.dart', 'adopt', legacyPath],
        workingDirectory: kernelRoot,
        environment: {'DPI_GOV_DEV': 'true'},
      );

      expect(result.exitCode, 0);
      
      final backlogFile = File(p.join(legacyPath, 'backlog.json'));
      expect(await backlogFile.exists(), isTrue);
      
      final Map<String, dynamic> backlog = jsonDecode(await backlogFile.readAsString());
      expect(backlog['current_sprint'], equals('S01-ALIGNMENT'));
      
      // Debe haber detectado que falta VISION.md y GEMINI.md
      final List tasks = backlog['sprints'].firstWhere((s) => s['id'] == 'S01-ALIGNMENT')['tasks'];
      expect(tasks.any((t) => t['id'] == 'TASK-ADOPT-01'), isTrue, reason: 'Faltó tarea de VISION.md');
      expect(tasks.any((t) => t['id'] == 'TASK-ADOPT-02'), isTrue, reason: 'Faltó tarea de GEMINI.md');
    });
  });
}
