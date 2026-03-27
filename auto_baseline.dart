import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';

void main() async {
  final process = await Process.start('dart', ['bin/antigravity_dpi.dart', 'baseline', '-k', 'vault/po_private.xml']);
  
  process.stdout.transform(utf8.decoder).listen((data) async {
    stdout.write(data);
    if (data.contains('Desafío:')) {
      final challenge = data.split('Desafío:')[1].split(')')[0].trim();
      print('\n[AUTO-SIGNER] Challenge detected: $challenge');
      
      final privateKeyXml = await File('vault/po_private.xml').readAsString();
      final signer = SignEngine();
      final signatureBytes = await signer.sign(
        challenge: Uint8List.fromList(utf8.encode(challenge)),
        privateKeyXml: privateKeyXml,
      );
      
      final signatureB64 = base64Encode(signatureBytes);
      print('[AUTO-SIGNER] Sending signature: $signatureB64');
      process.stdin.writeln(signatureB64);
    }
  });

  process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));
  final exitCode = await process.exitCode;
  print('\n[AUTO-SIGNER] Process exited with code: $exitCode');
  exit(exitCode);
}
