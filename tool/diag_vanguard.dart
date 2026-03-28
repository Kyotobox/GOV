import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/security/vanguard_core.dart';

void main() async {
  final basePath = Directory.current.path;
  final vanguard = VanguardCore();
  final publicKeyFile = File(p.join(basePath, 'vault', 'intel', 'guard_pub.xml'));

  if (!publicKeyFile.existsSync()) {
    print('[ERROR] guard_pub.xml missing.');
    return;
  }

  final publicKeyXml = await publicKeyFile.readAsString();

  print('=== [DIAG] VANGUARD COMMUNICATION TEST ===');
  print('[1/2] Marcando desafío táctico...');
  
  final challengeId = await vanguard.issueChallenge(
    level: 'TACTICAL-ORANGE',
    project: 'antigravity_dpi',
    files: ['DIAGNOSTIC_TEST.bin'],
    basePath: basePath,
    description: 'TEST DE COMUNICACIÓN BÁSICA (v5.2-DPI)',
  );

  print('[2/2] Esperando firma en Agente Vanguard (ID: $challengeId)...');
  
  final isSigned = await vanguard.waitForSignature(
    basePath: basePath,
    challenge: challengeId,
    publicKeyXml: publicKeyXml,
    timeoutSeconds: 120,
  );

  if (isSigned) {
    print('\n[✅] ¡COMUNICACIÓN EXITOSA!');
    print('El Agente y el Kernel están sincronizados.');
  } else {
    print('\n[❌] FALLO DE COMUNICACIÓN O TIMEOUT.');
    print('Verifica que el Agente esté abierto en la versión v5.2-DPI.');
  }
}
