import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../lib/src/security/sign_engine.dart';
import '../lib/src/security/vanguard_core.dart';

void main() {
  late Directory tempDir;
  late SignEngine signEngine;
  late VanguardCore vanguardCore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gov_test_');
    signEngine = SignEngine();
    vanguardCore = VanguardCore();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('SignEngine Hardening (VUL-03, VUL-04)', () {
    test('Debe fallar con una ruta de clave inexistente (Manejo de errores mejorado)', () async {
      final bogusPath = p.join(tempDir.path, 'missing.xml');
      expect(
        () => signEngine.sign(challenge: 'test', files: 'a.dart', privateKeyXmlPath: bogusPath),
        throwsA(isA<Exception>()),
      );
    });

    test('El parser XML debe manejar espacios y saltos de línea (Robustez)', () async {
      final keyFile = File(p.join(tempDir.path, 'test_key.xml'));
      await keyFile.writeAsString('''
<RSAKeyValue>
  <Modulus>
    s7v6+v//v78=
  </Modulus>
  <Exponent>AQAB</Exponent>
</RSAKeyValue>
''');

      // Verificamos que no lance excepción al leer el XML con espacios de forma robusta
      expect(await signEngine.verify(
        challenge: 'c', 
        files: 'f', 
        signatureBase64: 'c2ln', 
        publicKeyXmlPath: keyFile.path
      ), isFalse); 
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
        timeoutSeconds: 5
      );

      // Simulamos que el PO firma después de 500ms
      await Future.delayed(Duration(milliseconds: 500));
      await sigFile.writeAsString('{"signature": "test-sig"}');

      final result = await waitFuture;
      expect(result, isTrue, reason: 'El watcher debería haber detectado la creación del archivo');
    });

    test('waitForSignature debe expirar (timeout) si no hay archivo', () async {
      final intelDir = Directory(p.join(tempDir.path, 'vault', 'intel'));
      await intelDir.create(recursive: true);

      final result = await vanguardCore.waitForSignature(
        basePath: tempDir.path, 
        timeoutSeconds: 1
      );

      expect(result, isFalse, reason: 'Debe retornar false tras el timeout');
    });
  });
}
