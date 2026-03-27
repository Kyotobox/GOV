import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'sign_engine.dart';

class VanguardCore {
  /// Generates a new challenge and writes it to vault/intel/challenge.json.
  Future<String> issueChallenge({
    required String level,
    required String project,
    required List<String> files,
    required String basePath,
    String description = '',
  }) async {
    final random = Random.secure();
    final nonce = List<int>.generate(16, (i) => random.nextInt(256));
    final nonceHex = nonce.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    
    final challengeId = 'AUTH-${DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.')[0]}-$nonceHex';
    final intelDir = p.join(basePath, 'vault', 'intel');
    final challengeFile = File(p.join(intelDir, 'challenge.json'));

    final payload = {
      'challenge': challengeId,
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'project': project,
      'files': files.join(', '),
      'description': description.isNotEmpty ? description : 'CAPA: $level - Cambios que requieren certificación PO.',
    };

    if (!await Directory(intelDir).exists()) {
      await Directory(intelDir).create(recursive: true);
    }

    await challengeFile.writeAsString(jsonEncode(payload));
    return challengeId;
  }

  /// Watches for signature.json in vault/intel/ using a reactive watcher and verifies RSA.
  Future<bool> waitForSignature({
    required String basePath, 
    required String challenge,
    String? publicKeyXml,
    int timeoutSeconds = 30
  }) async {
    final sigPath = p.canonicalize(p.join(basePath, 'vault', 'intel', 'signature.json'));
    final intelDir = p.join(basePath, 'vault', 'intel');
    final sigFile = File(sigPath);
    
    print('[VANGUARD] Esperando firma RSA del PO (Desafío: ${challenge.substring(0, 8)}...)...');
    
    final completer = Completer<bool>();
    final watcher = DirectoryWatcher(intelDir);
    
    final subscription = watcher.events.listen((event) async {
      final eventPath = p.canonicalize(p.join(intelDir, event.path));
      if (eventPath.toLowerCase() == sigPath.toLowerCase() && (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY)) {
        if (!completer.isCompleted) {
          final ok = await _verifySig(sigFile, challenge, publicKeyXml);
          if (ok) completer.complete(true);
        }
      }
    });

    if (await sigFile.exists()) {
      final ok = await _verifySig(sigFile, challenge, publicKeyXml);
      if (ok && !completer.isCompleted) completer.complete(true);
    }

    try {
      final result = await completer.future.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () => false,
      );
      return result;
    } finally {
      await subscription.cancel();
      // VUL-25: Eliminar firma tras uso para evitar re-uso (Replay Protection)
      if (sigFile.existsSync()) await sigFile.delete();
    }
  }

  Future<bool> _verifySig(File sigFile, String challenge, String? publicKeyXml) async {
    for (int i = 0; i < 3; i++) {
        try {
          final content = await sigFile.readAsString();
          if (content.isEmpty) {
              await Future.delayed(Duration(milliseconds: 100));
              continue;
          }
          final data = jsonDecode(content);
          if (data['challenge'] != challenge) return false;
          
          final signatureB64 = data['signature'];
          if (signatureB64 == null) return false;

          // Si no hay llave pública (Tactical/Manual), aprobamos por presencia.
          // Si hay llave pública (Strategic/Baseline), VERIFICAMOS RSA.
          if (publicKeyXml == null) return true;

          final signEngine = SignEngine();
          return await signEngine.verify(
            challenge: utf8.encode(challenge),
            signature: base64Decode(signatureB64),
            publicKeyXml: publicKeyXml,
          );
        } catch (_) {
          await Future.delayed(Duration(milliseconds: 100));
        }
    }
    return false;
  }

  /// [PILLAR 1] GATE-BLACK Escalation
  /// Issues a high-severity incident report to the Vanguard Dashboard.
  Future<String> issueBlackGate({
    required String project,
    required String description,
    required String basePath,
  }) async {
    return await issueChallenge(
        level: 'GATE-BLACK',
        project: project,
        files: ['session.lock', 'vanguard.log'],
        basePath: basePath,
        description: description,
    );
  }

  /// Issues an emergency challenge that requires PO signature to bypass integrity blocks.
  Future<String> issueEmergencyChallenge({
    required String description,
    required List<String> files,
    required String basePath,
  }) async {
    return await issueChallenge(
        level: 'KERNEL-CORE',
        project: 'GATE-EMERGENCY',
        files: files,
        basePath: basePath,
        description: description,
    );
  }
}
