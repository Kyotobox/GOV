import 'dart:io';
import 'dart:convert';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final engine = IntegrityEngine();
  
  print('Regenerating hashes (including backlog.json)...');
  final hashes = await engine.generateHashes(basePath: basePath);
  
  final sortedKeys = hashes.keys.toList()..sort();
  final sortedHashes = { for (var k in sortedKeys) k : hashes[k] };
  
  final file = File(p.join(basePath, 'vault', 'kernel.hashes'));
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(sortedHashes));
  
  print('DONE: vault/kernel.hashes updated.');
}
