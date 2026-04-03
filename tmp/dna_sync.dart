import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final govExe = File('bin/gov.exe');
  final vanguardExe = File('bin/vanguard.exe');

  if (govExe.existsSync()) {
    final bytes = await govExe.readAsBytes();
    final hash = sha256.convert(bytes).toString().toLowerCase();
    await File('vault/intel/gov_hash.sig').writeAsString(hash, flush: true);
    print('GOV HASH: $hash (Length: ${hash.length})');
  }

  if (vanguardExe.existsSync()) {
    final bytes = await vanguardExe.readAsBytes();
    final hash = sha256.convert(bytes).toString().toLowerCase();
    await File('vault/intel/vanguard_hash.sig').writeAsString(hash, flush: true);
    print('VANGUARD HASH: $hash (Length: ${hash.length})');
  }
}
