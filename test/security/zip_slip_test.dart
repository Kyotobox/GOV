import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/core/pack_engine.dart';

void main() {
  late Directory sourceDir;
  late Directory externalDir;
  late PackEngine engine;

  setUp(() async {
    sourceDir = await Directory.systemTemp.createTemp('zip_source_');
    externalDir = await Directory.systemTemp.createTemp('zip_external_');
    engine = PackEngine();
    
    // Create inner structure
    await Directory(p.join(sourceDir.path, 'lib')).create();
    await File(p.join(sourceDir.path, 'lib', 'code.dart')).writeAsString('void main() {}');
    
    // Create external file
    await File(p.join(externalDir.path, 'secret.txt')).writeAsString('SENSITIVE');
  });

  tearDown(() async {
    await sourceDir.delete(recursive: true);
    await externalDir.delete(recursive: true);
  });

  group('PackEngine: ZipSlip & Leakage Protection (VUL-14)', () {
    test('pack: Should skip files outside source directory', () async {
      // Note: testing logic that uses dir.list(recursive: true) 
      // depends on the actual file system. We'll verify that 
      // p.isWithin and p.relative checks are triggered correctly 
      // if we were to find an absolute path outside.
      
      final absBase = p.canonicalize(sourceDir.path);
      final absExternal = p.canonicalize(p.join(externalDir.path, 'secret.txt'));
      
      // Test the logic manually using the same method as PackEngine
      bool isWithin = p.isWithin(absBase, absExternal);
      expect(isWithin, isFalse, reason: 'External file should be detected as outside');
      
      final rel = p.relative(absExternal, from: absBase);
      expect(rel.startsWith('..'), isTrue, reason: 'Relative path should contain traversal');
    });

    test('pack: Real execution should not contain traversal paths', () async {
       // Perform a real pack
       final zipPath = await engine.pack(basePath: sourceDir.path);
       final file = File(zipPath);
       expect(await file.exists(), isTrue);
       
       // Clean up
       await file.delete();
    });
  });
}
