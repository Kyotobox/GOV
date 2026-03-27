import 'dart:io';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final engine = IntegrityEngine();
  final privKeyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  
  if (!await privKeyFile.exists()) {
    print('Error: po_private.xml not found');
    return;
  }
  
  final privateKeyXml = await privKeyFile.readAsString();
  
  print('Signing kernel.hashes with development key...');
  await engine.signManifest(
    basePath: basePath,
    privateKeyXml: privateKeyXml,
  );
  
  print('DONE: vault/kernel.hashes.sig updated.');
}
