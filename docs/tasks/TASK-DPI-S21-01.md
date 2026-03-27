# TASK-DPI-S21-01: Purga de autoSign y Verificación Estricta RSA

## Metadatos
- **Sprint**: S21-RESTORE
- **Label**: SEC
- **Gate**: OPERATIONAL-RED
- **Dependencias**: Ninguna
- **Archivos en Scope**: `bin/antigravity_dpi.dart`

## Objetivo
Eliminar completamente la función `autoSign` del motor. El Oráculo nunca debe poder firmar desafíos por sí mismo usando la llave privada local. Además, revertir la verificación RSA de "permisiva" a "estricta".

## Pre-flight Check
Antes de iniciar, ejecutar:
```powershell
dart bin/antigravity_dpi.dart audit
```
Confirmar que el sistema responde. Si falla, detener y reportar.

## Pasos de Ejecución

### Paso 1: Eliminar función `autoSign`
En `bin/antigravity_dpi.dart`, dentro de la clase `VanguardCore`, localizar y **eliminar completamente** el método `autoSign`:

```dart
// ELIMINAR ESTE BLOQUE COMPLETO:
Future<void> autoSign(String basePath, String challenge) async {
  final privFile = File(p.join(basePath, 'vault', 'po_private.xml'));
  if (!privFile.existsSync()) return;
  // ... todo el cuerpo del método
}
```

### Paso 2: Eliminar la llamada a `autoSign` en `_runBaseline`
En el método `_runBaseline`, localizar y eliminar la línea:
```dart
// ELIMINAR:
await vanguard.autoSign(basePath, challengeId);
```

### Paso 3: Revertir verificación permisiva en `_verify`
En el método `_verify` de `VanguardCore`, la verificación actual acepta cualquier firma RSA válida que contenga un DigestInfo SHA-256. Reemplazar por una verificación que también compruebe que el payload firmado corresponde exactamente al desafío:

```dart
Future<bool> _verify(File file, String challenge, String publicKeyXml) async {
  try {
    final data = jsonDecode(await file.readAsString());
    if (data['challenge'] != challenge) return false;
    
    final signature = base64Decode(data['signature']);
    final engine = SignEngine();
    final params = engine._parseRsaXml(publicKeyXml);
    final n = engine._bytesToBigInt(params['Modulus']!);
    final e = engine._bytesToBigInt(params['Exponent']!);

    // Verificación ESTRICTA: el payload debe ser exactamente el challenge en UTF-8
    final expectedPayload = Uint8List.fromList(utf8.encode(challenge));
    
    final rsa = RSASigner(SHA256Digest(), '0609608648016503040201');
    rsa.init(false, PublicKeyParameter<RSAPublicKey>(RSAPublicKey(n, e)));
    return rsa.verifySignature(expectedPayload, RSASignature(signature));
  } catch (_) { return false; }
}
```

### Paso 4: Eliminar importación no utilizada
Si `package:watcher/watcher.dart` ya no se usa, eliminar esa línea de imports.

### Paso 5: Eliminar `vault/po_private.xml` del repositorio
```powershell
Remove-Item vault\po_private.xml -ErrorAction SilentlyContinue
```
Agregar al `.gitignore`:
```
vault/po_private.xml
```

## Criterio de Éxito
- `dart analyze bin/antigravity_dpi.dart` → 0 errores.
- `dart bin/antigravity_dpi.dart audit` → Ejecuta sin errores.
- `dart bin/antigravity_dpi.dart baseline "Test"` → Emite el desafío, espera firma, y **no la firma sola**. Debe quedarse esperando (timeout).
- La llave privada NO existe en el repositorio ni en el vault.

## Criterio de Fallo (DETENER si ocurre)
- El binario puede firmar sin intervención humana.
- `vault/po_private.xml` existe y es legible por el motor.
