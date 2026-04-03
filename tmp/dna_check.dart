import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart dna_check.dart <project_root>');
    return;
  }
  
  final toolRoot = args[0];
  final selfHashesFile = File(p.join(toolRoot, 'vault', 'self.hashes'));
  if (!await selfHashesFile.exists()) {
    print('vault/self.hashes not found at $toolRoot');
    return;
  }

  print('AUDITING PROJECT AT: $toolRoot');
  final Map<String, dynamic> manifest = jsonDecode(await selfHashesFile.readAsString());
  int mismatches = 0;
  
  for (var entry in manifest.entries) {
    final filePath = p.join(toolRoot, entry.key);
    final file = File(filePath);
    if (!await file.exists()) {
      print('[MISSING] ${entry.key}');
      mismatches++;
      continue;
    }
    
    final bytes = await file.readAsBytes();
    final actual = sha256.convert(bytes).toString().toUpperCase();
    if (actual != entry.value.toString().toUpperCase()) {
      print('[MISMATCH] ${entry.key}');
      print('  Expected: ${entry.value}');
      print('  Actual:   $actual');
      mismatches++;
    }
  }
  
  if (mismatches == 0) {
    print('[✅] Integrity SEALED.');
  } else {
    print('[FAIL] Found $mismatches mismatches.');
  }
}
