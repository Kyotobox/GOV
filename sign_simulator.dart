import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final privKeyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  final privKeyXml = await privKeyFile.readAsString();
  
  final challenge = 'AUTH-20260327T024548-a8025effeb75e3cf8ad26e2d07c2f577';
  final engine = SignEngine();
  
  print('Simulando firma del PO para el desafío: $challenge');
  final signature = await engine.sign(
    challenge: utf8.encode(challenge),
    privateKeyXml: privKeyXml,
  );
  
  final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
  await sigFile.writeAsString(jsonEncode({
    'challenge': challenge,
    'signature': base64Encode(signature),
  }));
  
  print('[SUCCESS] Firma simulada y guardada en signature.json');
}
