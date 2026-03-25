import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final files = [
    'ops-intelligence.ps1',
    'ops-guard.ps1',
    'METHODOLOGY.md',
    'VISION.md',
    'ops-gov.ps1',
    'ops-audit.ps1'
  ];
  
  Map<String, String> hashes = {};
  for (final f in files) {
    final file = File('c:\\Users\\Ruben\\Documents\\Base2\\$f');
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      hashes[f] = sha256.convert(bytes).toString().toUpperCase();
    }
  }
  
  await File('all_hashes.json').writeAsString(JsonEncoder.withIndent('  ').convert(hashes));
  print('DONE');
}
