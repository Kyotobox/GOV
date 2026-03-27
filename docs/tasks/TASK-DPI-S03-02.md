# TASK-DPI-S03-02: sign_engine.dart — Firma RSA Dart Nativo

**Sprint**: S03-VANGUARD
**Label**: [SEC]
**CP**: 6
**Gate**: GATE-RED
**Revisor**: [GOV] PO
**Modelo**: Gemini Flash

## Contexto
Reemplazar `Base2/scripts/sign_challenge.ps1` con una implementación Dart nativa usando `pointycastle`.
Elimina la dependencia de que PowerShell esté disponible para firmar.
**Referencia**: `Base2/ops-guard.ps1` líneas 120-139 — lógica de verificación RSA.
**Referencia**: `Base2/vanguard_agent/lib/main.dart` línea 260-286 — `_signChallenge()`.

La verificación en PowerShell usa: `RSA.VerifyData(challenge + ":" + files, SHA256, signature)`

## Scope
- `lib/src/security/sign_engine.dart`

## Interfaz a Implementar
```dart
class SignEngine {
  // Firma un challenge usando la clave privada XML (compatible con RSA de PowerShell)
  // IMPORTANTE: El payload firmado es: "$challenge:$filesCommaSeparated"
  Future<String> sign({
    required String challenge,
    required String files,
    required String privateKeyXmlPath,
  });

  // Verifica una firma usando la clave pública XML
  Future<bool> verify({
    required String challenge,
    required String files,
    required String signature,     // Base64
    required String publicKeyXmlPath,
  });

  // Genera y escribe signature.json — consumido por ops-guard.ps1
  Future<void> writeSignature({
    required String signature,
    required String challenge,    // Para validación cruzada
    required String basePath,
  });

  // Panic Mode: escribe firma nula (000000) para bloqueo de emergencia
  Future<void> panic({required String basePath});

  // Actualiza vault_manifest.json con los hashes de los archivos firmados
  Future<void> updateVaultManifest({
    required List<String> files,
    required String basePath,
  });
}
```

## Formato signature.json (compatible con ops-guard.ps1)
```json
{
  "signature": "<base64-rsa-signature>",
  "challenge": "AUTH-20260325155100-abc12345",
  "timestamp": "2026-03-25T15:51:30Z"
}
```

## DoD
- [ ] `sign()` produce firmas verificables por `ops-guard.ps1::Invoke-AsymmetricGuard`.
- [ ] `verify()` es el equivalente Dart de `RSA.VerifyData(bytes, SHA256, sigBytes)`.
- [ ] `panic()` escribe firma `000000` en <100ms.
- [ ] `updateVaultManifest()` actualiza hashes SHA-256 en `vault/vault_manifest.json`.
- [ ] Test de interoperabilidad: firmar en Dart, verificar en PowerShell (y viceversa).

## Baseline (requiere firma RSA del PO)
`gov baseline "S03-02: SignEngine RSA native Dart implemented" GATE-RED`
