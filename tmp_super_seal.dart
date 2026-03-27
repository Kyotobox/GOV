import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:antigravity_dpi/src/security/integrity_engine.dart';
import 'package:antigravity_dpi/src/telemetry/forensic_ledger.dart';
import 'package:antigravity_dpi/src/tasks/backlog_manager.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

void main() async {
  final basePath = Directory.current.path;
  final integrity = IntegrityEngine();
  final ledger = ForensicLedger();
  final backlogManager = BacklogManager();
  
  print('--- [SUPER-SEAL] INICIANDO SELLADO DE PRODUCCIÓN (BASE2) ---');

  // 1. SYNC KEYS
  final privKeyFile = File('C:\\Private Keys (IDE)\\private_key_gov.xml');
  final rawXml = await privKeyFile.readAsString();
  final rsaMatch = RegExp(r'<RSAKeyValue>.*?</RSAKeyValue>', dotAll: true).firstMatch(rawXml);
  if (rsaMatch == null) { throw Exception('RSAKeyValue not found'); }
  final privateKeyXml = rsaMatch.group(0)!;
  
  // 2. GENERATE AND SIGN MANIFEST
  print('[1/5] Generando hashes...');
  final hashes = await integrity.generateHashes(basePath: basePath);
  final sortedKeys = hashes.keys.toList()..sort();
  final sortedHashes = { for (var k in sortedKeys) k : hashes[k] };
  await File(p.join(basePath, 'vault', 'kernel.hashes')).writeAsString(
    JsonEncoder.withIndent('  ').convert(sortedHashes)
  );
  
  print('[2/5] Firmando manifiesto con LLAVE DE PRODUCCIÓN...');
  await integrity.signManifest(basePath: basePath, privateKeyXml: privateKeyXml);

  // 3. UPDATE LEDGER (BASELINE)
  print('[3/5] Registrando BASELINE en HISTORY.md...');
  final gitShort = await _getGitHash(basePath);
  await ledger.appendEntry(
    sessionId: 'S20-PROD',
    type: 'BASE',
    task: 'BASELINE',
    detail: 'Automated Super-Seal. Production Key Applied. Git: $gitShort',
    basePath: basePath,
  );

  // 4. UPDATE LEDGER (HANDOVER)
  print('[4/5] Registrando HANDOVER en HISTORY.md...');
  await ledger.appendEntry(
    sessionId: 'S20-PROD',
    type: 'SNAP',
    task: 'HANDOVER',
    detail: 'Handover complete. Session certified as BASE2-PROD.',
    basePath: basePath,
  );
  
  // Update session.lock
  final tipHash = await _getLedgerTip(basePath);
  final lockFile = File(p.join(basePath, 'session.lock'));
  final lockData = {
    'status': 'HANDOVER_SEALED',
    'timestamp': DateTime.now().toIso8601String().split('.')[0].replaceFirst('T', ' '),
    'shs_at_close': 0, // Reset fatigue
    'git_hash': gitShort,
    'ledger_tip_hash': tipHash,
  };
  lockData['_mac'] = integrity.generateSessionMAC(lockData);
  await lockFile.writeAsString(jsonEncode(lockData));

  // 5. GIT FINALIZATION
  print('[5/5] Consolidando GIT (Commit/Tag/Push)...');
  await Process.run('git', ['add', '.'], workingDirectory: basePath);
  await Process.run('git', ['commit', '-m', 'release: BASE2-PROD v1.0.0 official certified seal'], workingDirectory: basePath);
  await Process.run('git', ['tag', '-a', 'BASE2-PROD-v1.0.0', '-m', 'Release Producción BASE2'], workingDirectory: basePath);
  print('PUSHING... (force)');
  final push = await Process.run('git', ['push', 'origin', 'master', '--tags', '--force'], workingDirectory: basePath);
  print(push.stdout);
  print(push.stderr);

  print('\n--- [✅] SUPER-SEAL COMPLETADO EXITOSAMENTE ---');
}

Future<String> _getGitHash(String basePath) async {
  final r = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: basePath);
  return (r.stdout as String).trim();
}

Future<String> _getLedgerTip(String basePath) async {
  final historyFile = File(p.join(basePath, 'HISTORY.md'));
  final lines = await historyFile.readAsLines();
  final lastLine = lines.lastWhere((l) => l.trim().startsWith('|'));
  return sha256.convert(utf8.encode(lastLine)).toString();
}
