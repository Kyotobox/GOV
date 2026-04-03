import 'dart:io';
import 'package:crypto/crypto.dart';

void main() async {
  final file = File('../miniduo/bin/gov.exe');
  if (!file.existsSync()) {
    print('ERROR: miniduo/bin/gov.exe not found.');
    return;
  }
  final bytes = file.readAsBytesSync();
  final hash = sha256.convert(bytes).toString().toUpperCase();
  print('ACTUAL-HASH: $hash');
}
