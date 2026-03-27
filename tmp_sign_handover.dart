import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:path/path.dart' as p;

void main() async {
  final basePath = Directory.current.path;
  final challengeFile = File(p.join(basePath, 'vault', 'intel', 'challenge.json'));
  final privKeyFile = File('C:\\Private Keys (IDE)\\private_key_gov.xml');
  
  print('Signer loop started. Waiting for challenge...');
  
  // Wait up to 60 seconds
  for (int i = 0; i < 600; i++) {
    if (await challengeFile.exists()) {
      print('Challenge detected. Signing...');
      try {
        final content = await challengeFile.readAsString();
        if (content.isEmpty) {
          await Future.delayed(Duration(milliseconds: 100));
          continue;
        }
        final challengeData = jsonDecode(content);
        final challengeString = challengeData['challenge'];
        final privateKeyXml = await privKeyFile.readAsString();
        
        final engine = SignEngine();
        final signature = await engine.sign(
          challenge: Uint8List.fromList(utf8.encode(challengeString)),
          privateKeyXml: privateKeyXml,
        );
        
        final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
        await sigFile.writeAsString(jsonEncode({
          'challenge': challengeString,
          'signature': base64Encode(signature),
        }));
        
        print('DONE: signature.json generated with PRODUCTION KEY (ID: ${challengeString.substring(0,8)}).');
        return; // Success
      } catch (e) {
        print('Error during sign: $e. Retrying...');
      }
    }
    await Future.delayed(Duration(milliseconds: 100));
  }
  print('ERROR: Timeout waiting for challenge.');
}
