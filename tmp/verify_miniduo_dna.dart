import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  final exe = File('../miniduo/bin/gov.exe');
  final sig = File('../miniduo/vault/intel/gov_hash.sig');
  
  print('--- DNA RECOVERY DIAGNOSTIC ---');
  print('EXE: ${exe.absolute.path}');
  print('SIG: ${sig.absolute.path}');
  
  if (!exe.existsSync()) { print('FAIL: EXE not found.'); return; }
  if (!sig.existsSync()) { print('FAIL: SIG not found.'); return; }
  
  final exeBytes = exe.readAsBytesSync();
  final currentHash = sha256.convert(exeBytes).toString().toLowerCase();
  
  final sigBytes = sig.readAsBytesSync();
  final masterHash = utf8.decode(sigBytes).trim().toLowerCase();
  
  print('ACTUAL: $currentHash (len: ${currentHash.length})');
  print('EXPECT: $masterHash (len: ${masterHash.length})');
  
  if (currentHash == masterHash) {
    print('RESULT: SEALED');
  } else {
    print('RESULT: COMPROMISED');
    
    // Check for specific invisible errors
    if (currentHash.length != masterHash.length) {
      print('DIFF: Length mismatch!');
    }
    for (int i = 0; i < currentHash.length && i < masterHash.length; i++) {
        if (currentHash[i] != masterHash[i]) {
            print('DIFF: First mismatch at index $i: "${currentHash[i]}" vs "${masterHash[i]}"');
            break;
        }
    }
  }
}
