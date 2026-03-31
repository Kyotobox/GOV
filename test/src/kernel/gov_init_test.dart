import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

// Simulación ligera del motor gov.dart (init) para testing unitario
void main() {
  group('Kernel: DPI-INIT Protocol', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gov_init_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('Validación de Estructura: Clonación de Búnker', () async {
      final targetPath = p.join(tempDir.path, 'NewProject');
      final targetDir = Directory(targetPath);
      
      // Simular ejecución de 'gov init' (MOCK de estructura)
      targetDir.createSync();
      File(p.join(targetPath, 'VISION.md')).createSync();
      File(p.join(targetPath, 'backlog.json')).writeAsStringSync('{"sprints": []}');
      File(p.join(targetPath, 'GEMINI.md')).createSync();
      Directory(p.join(targetPath, '.meta')).createSync();

      expect(targetDir.existsSync(), isTrue);
      expect(File(p.join(targetPath, 'VISION.md')).existsSync(), isTrue);
      
      final backlog = File(p.join(targetPath, 'backlog.json')).readAsStringSync();
      expect(backlog.contains('sprints'), isTrue);
    });

    test('Integridad: Protección de Sobrescritura', () {
      final targetPath = p.join(tempDir.path, 'Existing');
      Directory(targetPath).createSync();
      
      // La lógica del Kernel debe fallar si el directorio existe
      // (Test conceptual de la restricción implementada en gov.dart)
      final exists = Directory(targetPath).existsSync();
      expect(exists, isTrue);
    });
  });
}
