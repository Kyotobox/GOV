import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class PackEngine {
  /// Packs the project into a ZIP file, excluding sensitive/heavy directories.
  Future<String> pack({
    required String basePath,
    String? outputFilename,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = outputFilename ?? 'audit_export_$timestamp.zip';
    final zipPath = p.join(basePath, zipFile);
    
    final encoder = ZipFileEncoder();
    try {
      encoder.create(zipPath);
    } catch (e) {
      throw 'FALLO AL CREAR ZIP en $zipPath: $e';
    }

    final dir = Directory(basePath);
    final List<String> excludes = [
      '.git',
      '.dart_tool',
      'build',
      '.gemini',
      'vault/audit.log', // Exclude local audit logs
      zipFile, // Don't pack the zip itself
    ];

    print('[PACK] Empaquetando: $basePath');
    
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relPath = p.relative(entity.path, from: basePath);
        
        bool shouldExclude = false;
        final normalizedRel = relPath.replaceAll('\\', '/');
        
        for (final ex in excludes) {
          final normalizedEx = ex.replaceAll('\\', '/');
          if (normalizedRel == normalizedEx || normalizedRel.startsWith(normalizedEx + '/')) {
            shouldExclude = true;
            break;
          }
        }

        if (!shouldExclude) {
          print('  [ADD] $relPath');
          encoder.addFile(entity, relPath);
        }
      }
    }

    print('[INFO] Cerrando ZIP...');
    encoder.close();
    print('[INFO] ZIP cerrado correctamente.');
    return zipPath;
  }
}
