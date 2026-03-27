import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'sign_engine.dart';

/// VanguardWatcher: Headless implementation of the Vanguard challenge watcher.
/// This service monitors the vault/intel directory for challenges and signs them automatically.
class VanguardWatcher {
  final SignEngine _signer = SignEngine();
  
  /// Starts watching the specified directory for challenge files.
  /// Returns a [StreamSubscription] to allow manual lifecycle control (VUL-23).
  Future<StreamSubscription<WatchEvent>> start({
    required String basePath, 
    required String privateKeyPath
  }) async {
    final intelDir = p.join(basePath, 'vault', 'intel');
    print('[VANGUARD] Iniciando observador en: $intelDir');
    
    final watcher = DirectoryWatcher(intelDir);
    
    final subscription = watcher.events.listen((event) async {
      if (event.type == ChangeType.ADD && event.path.endsWith('challenge.json')) {
        print('[VANGUARD] Nuevo desafío detectado: ${event.path}');
        try {
          await _handleChallenge(event.path, privateKeyPath, basePath);
        } catch (e) {
          stderr.writeln('[VANGUARD-CRITICAL] Fallo catastrófico al procesar desafío: $e');
        }
      }
    });

    return subscription;
  }

  Future<void> _handleChallenge(String challengePath, String privateKeyPath, String basePath) async {
    try {
      final challengeFile = File(challengePath);
      if (!await challengeFile.exists()) return;

      final content = await challengeFile.readAsString();
      final data = jsonDecode(content);
      
      final challenge = data['challenge'] as String;
      final level = data['level'] as String;

      print('[VANGUARD] Challenge: $challenge | Level: $level');

      final privateKeyXml = await File(privateKeyPath).readAsString();
      final signatureBytes = await _signer.sign(
        challenge: Uint8List.fromList(utf8.encode(challenge)),
        privateKeyXml: privateKeyXml,
      );
      final signature = base64Encode(signatureBytes);

      final sigPath = p.join(basePath, 'vault', 'intel', 'signature.json');
      final sigPayload = {
        'signature': signature,
        'challenge': challenge,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await File(sigPath).writeAsString(jsonEncode(sigPayload));
      print('[VANGUARD] Firma generada y persistida en: $sigPath');
      
    } catch (e) {
      // VUL-04: Ensure background service errors are NOT swallowed silently
      stderr.writeln('[VANGUARD-ERROR] Error en el flujo de firma: $e');
      rethrow;
    }
  }
}
