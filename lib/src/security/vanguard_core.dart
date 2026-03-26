import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

class VanguardCore {
  /// Generates a new challenge and writes it to vault/intel/challenge.json.
  Future<String> issueChallenge({
    required String level,
    required String project,
    required List<String> files,
    required String basePath,
    String description = '',
  }) async {
    final challengeId = 'AUTH-${DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.')[0]}-${(1000 + (new DateTime.now().millisecondsSinceEpoch % 9000))}';
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

  /// Watches for signature.json in vault/intel/.
  /// (Simplified poll for this CLI context).
  Future<bool> waitForSignature({required String basePath, int timeoutSeconds = 30}) async {
    final sigPath = p.join(basePath, 'vault', 'intel', 'signature.json');
    final sigFile = File(sigPath);
    
    print('[VANGUARD] Esperando firma del PO (timeout: ${timeoutSeconds}s)...');
    
    for (int i = 0; i < timeoutSeconds; i++) {
      if (await sigFile.exists()) {
        print('[VANGUARD] Firma DETECTADA ✅');
        return true;
      }
      await Future.delayed(Duration(seconds: 1));
    }
    
    print('[VANGUARD] Timeout: No se detectó firma.');
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
