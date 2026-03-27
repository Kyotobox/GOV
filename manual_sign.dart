import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';

void main() async {
  final challengeFile = File('vault/intel/challenge.json');
  final challengeData = jsonDecode(await challengeFile.readAsString());
  final challenge = challengeData['challenge'];

  final privateKeyXml = await File('vault/po_private.xml').readAsString();
  final signer = SignEngine();
  final signatureBytes = await signer.sign(
    challenge: Uint8List.fromList(utf8.encode(challenge)),
    privateKeyXml: privateKeyXml,
  );

  final signatureB64 = base64Encode(signatureBytes);
  final signaturePayload = {
    'challenge': challenge,
    'signature': signatureB64,
    'timestamp': DateTime.now().toIso8601String(),
    'po': 'SEC-PO-S19',
  };

  await File('vault/intel/signature.json').writeAsString(jsonEncode(signaturePayload));
  print('[PO-APP] Firma generada y guardada en vault/intel/signature.json');
}
