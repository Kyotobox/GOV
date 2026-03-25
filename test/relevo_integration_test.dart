import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

void main() {
  late Directory tempDir;
  late String basePath;
  late String toolRoot;

  Future<String> getHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString().toUpperCase();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('relevo_integration_');
    basePath = tempDir.path;
    toolRoot = Directory.current.path;

    // Create a mock project structure
    await Directory(p.join(basePath, 'vault', 'intel')).create(recursive: true);
    
    final backlogFile = File(p.join(basePath, 'backlog.json'));
    await backlogFile.writeAsString(jsonEncode({
      'project': 'Test Project',
      'sprints': [
        {
          'id': 'S01',
          'name': 'Sprint 1',
          'status': 'IN_PROGRESS',
          'goal': 'Test Goal',
          'tasks': [
            {'id': 'TASK-01', 'label': 'GOV', 'desc': 'Test Task', 'status': 'PENDING'}
          ]
        }
      ]
    }));
    
    final taskMdFile = File(p.join(basePath, 'task.md'));
    await taskMdFile.writeAsString('# SPRINT S01\n- [ ] **TASK-01**');
    
    await File(p.join(basePath, 'session.lock')).writeAsString(jsonEncode({
      'status': 'IN_PROGRESS',
      'timestamp': DateTime.now().toIso8601String()
    }));

    // Setup git in the temp dir
    await Process.run('git', ['init'], workingDirectory: basePath);
    await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: basePath);
    await Process.run('git', ['config', 'user.name', 'Tester'], workingDirectory: basePath);
    
    // Create REAL hashes manifest
    final hashes = {
      'backlog.json': await getHash(backlogFile),
      'task.md': await getHash(taskMdFile)
    };
    await File(p.join(basePath, 'vault', 'kernel.hashes')).writeAsString(jsonEncode(hashes));

    await File(p.join(basePath, 'README.md')).writeAsString('Test');
    await Process.run('git', ['add', '.'], workingDirectory: basePath);
    await Process.run('git', ['commit', '-m', 'initial commit'], workingDirectory: basePath);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('Full Handover/Takeover integration cycle', () async {
    final handoverProcess = await Process.start(
      'dart',
      ['run', 'bin/antigravity_dpi.dart', 'handover', '-p', basePath],
      workingDirectory: toolRoot,
    );
    
    // Wait for challenge.json
    int retries = 0;
    bool challengeExists = false;
    final challengeFile = File(p.join(basePath, 'vault', 'intel', 'challenge.json'));
    
    while (retries < 20) {
      await Future.delayed(Duration(milliseconds: 500));
      if (await challengeFile.exists()) {
        challengeExists = true;
        break;
      }
      retries++;
    }
    
    expect(challengeExists, isTrue, reason: 'challenge.json should be created');
    
    // Mock PO signature (Fixed filename per VanguardCore)
    final sigFile = File(p.join(basePath, 'vault', 'intel', 'signature.json'));
    await sigFile.writeAsString(jsonEncode({'signature': 'MOCK_SIGNATURE', 'po': 'PO_TEST'}));
    
    final exitCode = await handoverProcess.exitCode;
    expect(exitCode, 0);

    expect(await File(p.join(basePath, 'vault', 'intel', 'SESSION_RELAY_TECH.md')).exists(), isTrue);
    final lockContentHandover = jsonDecode(await File(p.join(basePath, 'session.lock')).readAsString());
    expect(lockContentHandover['status'], 'HANDOVER_SEALED');

    // 2. Run Takeover
    final takeoverResult = await Process.run(
      'dart',
      ['run', 'bin/antigravity_dpi.dart', 'takeover', '-p', basePath],
      workingDirectory: toolRoot,
    );
    
    expect(takeoverResult.exitCode, 0);
    expect(takeoverResult.stdout, contains('Takeover EXITOSO'));
    
    final finalLockContent = jsonDecode(await File(p.join(basePath, 'session.lock')).readAsString());
    expect(finalLockContent['status'], 'IN_PROGRESS');
  });
}
