import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  final file = File('c:\\Users\\Ruben\\Documents\\Base2\\GEMINI.md');
  final bytes = await file.readAsBytes();
  final hash = sha256.convert(bytes).toString().toUpperCase();
  await File('full_hash.txt').writeAsString(hash);
  print('DONE');
}
