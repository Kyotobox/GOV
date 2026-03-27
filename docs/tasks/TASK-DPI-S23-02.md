# TASK-DPI-S23-02: Eliminar PowerShell — Integrar SignEngine Nativo en Vanguard

## Metadatos
- **Sprint**: S23-VANGUARD
- **Label**: SEC
- **Gate**: STRATEGIC-GOLD
- **Dependencias**: TASK-DPI-S23-01 completada
- **Archivos en Scope**: `vanguard_agent/lib/main.dart`, `vanguard_agent/pubspec.yaml`

## Objetivo
El agente actual llama a `Process.run('powershell', ['-File', 'sign_challenge.ps1'])` para firmar. Este es un vectorde ataque no auditable. Reemplazar completamente por el `SignEngine` de Dart usando `pointycastle`.

## Pre-flight Check
Abrir `vanguard_agent/lib/main.dart` y buscar la función `_signChallenge`. Confirmar que contiene `Process.run('powershell', ...)`.

## Pasos de Ejecución

### Paso 1: Agregar `pointycastle` y `xml` a `vanguard_agent/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  pointycastle: ^3.9.1
  xml: ^6.5.0
  watcher: ^1.2.1
  path: ^1.9.1
  file_picker: ^8.1.7
  path_provider: ^2.1.5
```

```powershell
cd vanguard_agent
flutter pub get
```

### Paso 2: Agregar imports en `main.dart`
Al inicio del archivo `vanguard_agent/lib/main.dart`, añadir:

```dart
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';
```

### Paso 3: Añadir la clase `_DartSignEngine` en `main.dart`
Antes de la clase `AgentHome`, añadir la implementación nativa del motor de firma:

```dart
class _DartSignEngine {
  Future<Uint8List> sign({
    required Uint8List payload,
    required String privateKeyXml,
  }) async {
    final params = _parseRsaXml(privateKeyXml);
    final n = _bytesToBigInt(params['Modulus']!);
    final d = _bytesToBigInt(params['D']!);
    final p = _bytesToBigInt(params['P']!);
    final q = _bytesToBigInt(params['Q']!);

    final privateKey = RSAPrivateKey(n, d, p, q);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return signer.generateSignature(payload).bytes;
  }

  Map<String, Uint8List> _parseRsaXml(String xmlData) {
    final document = XmlDocument.parse(xmlData);
    final root = document.rootElement;
    final Map<String, Uint8List> params = {};
    for (final node in root.children) {
      if (node is XmlElement) {
        params[node.name.local] = base64Decode(
          node.innerText.trim().replaceAll('\n', '').replaceAll(' ', ''),
        );
      }
    }
    return params;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
```

### Paso 4: Reemplazar `_signChallenge` en `_AgentHomeState`
Localizar la función `_signChallenge` y reemplazar completamente:

```dart
Future<void> _signChallenge() async {
  if (_selectedProject == null || _challenge == null || _isSigning) return;
  
  setState(() {
    _isSigning = true;
    _status = 'Firmando con motor Dart (RSA-2048)...';
  });

  try {
    // Leer la llave privada desde la ruta configurada
    final keyFile = File(_selectedProject!.keyPath);
    if (!await keyFile.exists()) {
      throw Exception('Llave privada no encontrada: ${_selectedProject!.keyPath}');
    }
    final privateKeyXml = await keyFile.readAsString();
    
    // Firmar el challenge en UTF-8
    final engine = _DartSignEngine();
    final payload = Uint8List.fromList(utf8.encode(_challenge!));
    final signature = await engine.sign(payload: payload, privateKeyXml: privateKeyXml);
    
    // Escribir la firma en vault/intel/signature.json
    final sigFile = File(p.join(_selectedProject!.rootPath, 'vault', 'intel', 'signature.json'));
    await sigFile.writeAsString(jsonEncode({
      'challenge': _challenge!,
      'signature': base64Encode(signature),
      'timestamp': DateTime.now().toIso8601String(),
    }));
    
    setState(() {
      _lastApprovedId = _challenge;
      _lastApprovedLevel = _level;
      _lastApprovedProjectName = _selectedProject!.name;
      _challenge = null;
      _level = null;
      _isSigning = false;
      _kernelModeActive = false;
      _status = 'FIRMADO Y ENVIADO ✅';
    });
  } catch (e) {
    setState(() {
      _isSigning = false;
      _status = 'ERROR al firmar: $e';
    });
  }
}
```

### Paso 5: Eliminar el script PowerShell si existe
```powershell
Remove-Item "c:\Users\Ruben\Documents\antigravity_dpi\vanguard_agent\scripts\sign_challenge.ps1" -ErrorAction SilentlyContinue
```

## Criterio de Éxito
- `flutter analyze vanguard_agent/` → 0 errores críticos.
- El archivo `main.dart` NO contiene ninguna referencia a `powershell`.
- El agente puede firmar un desafío de prueba manualmente.

## Criterio de Fallo (DETENER si ocurre)
- Permanece cualquier referencia a `Process.run('powershell', ...)`.
- `flutter analyze` muestra errores en el motor de firma.
