import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

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

  /// Watches for signature.json in vault/intel/ using a reactive watcher.
  Future<bool> waitForSignature({required String basePath, int timeoutSeconds = 30}) async {
    final sigPath = p.normalize(p.join(basePath, 'vault', 'intel', 'signature.json'));
    final intelDir = p.join(basePath, 'vault', 'intel');
    final sigFile = File(sigPath);
    
    print('[VANGUARD] Esperando firma del PO (REACTIVO-RESILIENTE, timeout: ${timeoutSeconds}s)...');
    
    final completer = Completer<bool>();
    final watcher = DirectoryWatcher(intelDir);
    
    final subscription = watcher.events.listen((event) {
      final eventPath = p.normalize(event.path);
      if (eventPath == sigPath && 
          (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY)) {
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    // Check if it already exists slightly AFTER starting the watcher to bridge the gap
    if (await sigFile.exists()) {
      if (!completer.isCompleted) completer.complete(true);
    }

    try {
      final result = await completer.future.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () => false,
      );
      if (result) print('[VANGUARD] Firma DETECTADA ✅ (Evento)');
      return result;
    } catch (e) {
      print('[VANGUARD] Error en el watcher: $e');
      return false;
    } finally {
      await subscription.cancel();
    }
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
