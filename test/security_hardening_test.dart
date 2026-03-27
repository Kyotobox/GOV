import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:antigravity_dpi/src/security/sign_engine.dart';
import '../lib/src/security/vanguard_core.dart';

void main() {
  late Directory tempDir;
  late VanguardCore vanguardCore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gov_test_');
    vanguardCore = VanguardCore();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('Security Hardening S12-01 (SignEngine XML)', () {
    late SignEngine engine;
    final privateKeyXml = '''
<RSAKeyValue>
  <Modulus>m51mIDde/ckTyiJrrT63a3Nz5skRKO3iY8TQExQwwgzoQwpnutVeKbkVCvwIHhOvt/BEHAIx/pVVD1jCemDNxQ==</Modulus>
  <Exponent>AQAB</Exponent>
  <D>MD+9Sn/glA+kcyf4+t5XQJmrdgMhru8TIpwDZ+b6ty+MV+LpyPxWBWzQg2cFImbEjZDWbt1wpJjXzLmVxhDkAQ==</D>
  <P>5ZU1tJewnnCSTE26rPxBJDtqapJZ6IiEBS9Wq/GL/Kk=</P>
  <Q>rYVS3VFtu0Qzz8qqeHF/AVpjiBrxqpg3QONq4B0bPb0=</Q>
</RSAKeyValue>''';

    final publicKeyXml = '''
<RSAKeyValue>
  <Modulus>m51mIDde/ckTyiJrrT63a3Nz5skRKO3iY8TQExQwwgzoQwpnutVeKbkVCvwIHhOvt/BEHAIx/pVVD1jCemDNxQ==</Modulus>
  <Exponent>AQAB</Exponent>
</RSAKeyValue>''';

    setUp(() {
      engine = SignEngine();
    });

    test('SignEngine: Firma y Verifica con XML robusto', () async {
      final challenge = Uint8List.fromList(utf8.encode('TEST-CHALLENGE'));
      
      // Sign
      final signature = await engine.sign(
        challenge: challenge,
        privateKeyXml: privateKeyXml,
      );
      
      expect(signature, isNotNull);
      expect(signature.isNotEmpty, isTrue);

      // Verify
      final isValid = await engine.verify(
        challenge: challenge,
        signature: signature,
        publicKeyXml: publicKeyXml,
      );
      
      expect(isValid, isTrue);
    });

    test('SignEngine: Manejo de errores en XML corrupto', () async {
      bool caught = false;
      try {
        await engine.sign(
          challenge: Uint8List(16),
          privateKeyXml: '<Invalid>XML</Invalid>',
        );
      } catch (e) {
        print('DEBUG: Capturada excepción: $e');
        caught = true;
      }
      expect(caught, isTrue);
    });
  });

  group('VanguardCore Reactive Watcher (VUL-23)', () {
    test('waitForSignature debe detectar la creación de un archivo de forma reactiva', () async {
      final intelDir = Directory(p.join(tempDir.path, 'vault', 'intel'));
      await intelDir.create(recursive: true);
      final sigFile = File(p.join(intelDir.path, 'signature.json'));

      // Iniciamos la espera en un Future
      final waitFuture = vanguardCore.waitForSignature(
        basePath: tempDir.path, 
        challenge: 'TEST-CHALLENGE',
        timeoutSeconds: 5
      );

      // Simulamos que el PO firma después de 500ms
      await Future.delayed(Duration(milliseconds: 500));
      await sigFile.writeAsString('{"challenge": "TEST-CHALLENGE", "signature": "test-sig"}');

      final result = await waitFuture;
      expect(result, isTrue, reason: 'El watcher debería haber detectado la creación del archivo');
    });

    test('waitForSignature debe expirar (timeout) si no hay archivo', () async {
      final intelDir = Directory(p.join(tempDir.path, 'vault', 'intel'));
      await intelDir.create(recursive: true);

      final result = await vanguardCore.waitForSignature(
        basePath: tempDir.path, 
        challenge: 'NO-CHALLENGE',
        timeoutSeconds: 1
      );

      expect(result, isFalse, reason: 'Debe retornar false tras el timeout');
    });
  });
}
