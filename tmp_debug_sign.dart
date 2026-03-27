import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final basePath = Directory.current.path;
  final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
  final chalFile = File(p.join(basePath, 'vault', 'intel', 'challenge.json'));
  final pubFile = File(p.join(basePath, 'vault', 'po_public.xml'));

  if (!sigFile.existsSync()) { print('No sig'); return; }
  
  final sigData = jsonDecode(await sigFile.readAsString());
  final chalData = jsonDecode(await chalFile.readAsString());
  final pubKey = await pubFile.readAsString();

  final challenge = sigData['challenge'];
  final signatureB64 = sigData['signature'];

  print('Testing Challenge: $challenge');
  print('Payload Suffix: ${challenge.substring(challenge.length - 8)}');
  print('Signature Length: ${base64Decode(signatureB64).length}');

  final engine = SignEngine();
  final isValid = await engine.verify(
    challenge: utf8.encode(challenge),
    signature: base64Decode(signatureB64),
    publicKeyXml: pubKey,
  );

  print('RESULT: ${isValid ? "VALID" : "INVALID"}');
}
