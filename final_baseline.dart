import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';

void main() async {
  final process = await Process.start('gov.exe', ['baseline', '-k', 'vault/po_private.xml']);
  
  process.stdout.transform(utf8.decoder).listen((data) async {
    stdout.write(data);
    if (data.contains('Esperando firma RSA')) {
      final challengeFile = File('vault/intel/challenge.json');
      for (int i = 0; i < 10; i++) {
        if (await challengeFile.exists()) break;
        await Future.delayed(Duration(milliseconds: 200));
      }

      final challengeData = jsonDecode(await challengeFile.readAsString());
      final challenge = challengeData['challenge'];
      final privateKeyXml = await File('vault/po_private.xml').readAsString();
      final signer = SignEngine();
      final signatureBytes = await signer.sign(
        challenge: Uint8List.fromList(utf8.encode(challenge)),
        privateKeyXml: privateKeyXml,
      );
      
      final signaturePayload = {
        'challenge': challenge,
        'signature': base64Encode(signatureBytes),
        'timestamp': DateTime.now().toIso8601String(),
        'po': 'SEC-PO-S19-GOLD',
      };
      await File('vault/intel/signature.json').writeAsString(jsonEncode(signaturePayload));
    }
  });

  process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));
  final exitCode = await process.exitCode;
  exit(exitCode);
}
