import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final hashesFile = File(p.join(basePath, 'vault', 'kernel.hashes'));
  final Map<String, dynamic> manifest = jsonDecode(await hashesFile.readAsString());
  
  for (var fileName in manifest.keys.toList()) {
    final file = File(p.join(basePath, fileName));
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString().toUpperCase();
      manifest[fileName] = hash;
    }
  }
  
  await hashesFile.writeAsString(jsonEncode(manifest));
  print('DONE');
}
