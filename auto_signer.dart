import 'dart:convert';
import 'dart:io';
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

void main() async {
  final basePath = Directory.current.path;
  final intelDir = p.join(basePath, 'vault', 'intel');
  final challengeFile = File(p.join(intelDir, 'challenge.json'));
  final privKeyFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  final engine = SignEngine();

  print('[AUTO-SIGNER] Monitoreando $intelDir para desafíos...');

  final watcher = DirectoryWatcher(intelDir);
  watcher.events.listen((event) async {
    if (p.basename(event.path) == 'challenge.json' && (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY)) {
      try {
        final content = await challengeFile.readAsString();
        if (content.isEmpty) return;
        
        final data = jsonDecode(content);
        final challenge = data['challenge'];
        final level = data['level'];
        
        print('[AUTO-SIGNER] Desafío detectado ($level): $challenge');
        
        final privKeyXml = await privKeyFile.readAsString();
        final signature = await engine.sign(
          challenge: utf8.encode(challenge),
          privateKeyXml: privKeyXml,
        );
        
        final sigFile = File(p.join(intelDir, 'signature.json'));
        await sigFile.writeAsString(jsonEncode({
          'challenge': challenge,
          'signature': base64Encode(signature),
        }));
        
        print('[AUTO-SIGNER] ✅ Firma generada para $challenge');
      } catch (e) {
        print('[AUTO-SIGNER] ❌ Error: $e');
      }
    }
  });
}
