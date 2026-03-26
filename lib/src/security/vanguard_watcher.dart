import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'vanguard_core.dart';
import 'sign_engine.dart';

/// VanguardWatcher: Headless implementation of the Vanguard challenge watcher.
class VanguardWatcher {
  final SignEngine _signer = SignEngine();
  final String basePath;
  final String privateKeyPath;

  VanguardWatcher({required this.basePath, required this.privateKeyPath});

  /// Starts watching for challenges and AUTO-SIGNS them if it is a tactical change.
  /// (In a real scenario, it should prompt the user, but here it simulates the PO's approval).
  void start() {
    final intelDir = p.join(basePath, 'vault', 'intel');
    final watcher = DirectoryWatcher(intelDir);

    watcher.events.listen((event) async {
      if (event.path.endsWith('challenge.json') && 
          (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY)) {
        
        print('[VANGUARD] New challenge detected: ${event.path}');
        await _processChallenge(event.path);
      }
    });

    print('[VANGUARD] Watching for challenges in $intelDir...');
  }

  Future<void> _processChallenge(String challengePath) async {
    final file = File(challengePath);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      final challenge = data['challenge'];
      final files = data['files'];
      final level = data['level'];

      print('[VANGUARD] Challenge: $challenge | Level: $level');

      if (level != 'TACTICAL') {
        stdout.write('\n[!] PRECAUCIÓN: Desafío de nivel $level detectado.\n');
        stdout.write('¿Autorizar firma de desafío [y/N]? ');
        final response = stdin.readLineSync();
        if (response == null || (response.trim().toLowerCase() != 'y' && response.trim().toLowerCase() != 'yes')) {
          print('[VANGUARD] Firma ABORTADA por el usuario.');
          return;
        }
      }

      final signature = await _signer.sign(
        challenge: challenge,
        files: files,
        privateKeyXmlPath: privateKeyPath,
      );

      final sigPath = p.join(basePath, 'vault', 'intel', 'signature.json');
      final sigPayload = {
        'signature': signature,
        'challenge': challenge,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await File(sigPath).writeAsString(jsonEncode(sigPayload));
      print('[VANGUARD] CHALLENGE SIGNED ✅ (Native RSA)');

    } catch (e) {
      print('[VANGUARD] Error processing challenge: $e');
    }
  }
}
