import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final hashesFile = File('vault/self.hashes');
  if (!hashesFile.existsSync()) {
    print('Error: vault/self.hashes not found.');
    return;
  }

  final String content = await hashesFile.readAsString();
  final Map<String, dynamic> expectedHashes = jsonDecode(content);

  int mismatches = 0;
  int missing = 0;

  for (final path in expectedHashes.keys) {
    final file = File(path);
    if (!file.existsSync()) {
      print('[MISSING] $path');
      missing++;
      continue;
    }

    final bytes = await file.readAsBytes();
    final currentHash = sha256.convert(bytes).toString().toUpperCase();
    final expectedHash = expectedHashes[path].toString().toUpperCase();

    if (currentHash != expectedHash) {
      print('[MISMATCH] $path');
      print('  Expected: $expectedHash');
      print('  Current:  $currentHash');
      mismatches++;
    }
  }

  print('\nSummary:');
  print('Total files checked: ${expectedHashes.length}');
  print('Mismatches: $mismatches');
  print('Missing: $missing');

  if (mismatches == 0 && missing == 0) {
    print('\nDNA Integrity: SEALED');
  } else {
    print('\nDNA Integrity: COMPROMISED');
  }
}
