# TASK-DPI-S11-02: Vanguard Authorization Fixes

**Sprint**: S11-HOTFIX
**Label**: [SEC]
**CP**: 5
**Gate**: GATE-GOLD
**Modelo**: Gemini Flash

## Contexto
Resolver VUL-05 (Entropía predecible en Challenge ID) y VUL-06 (Auto-firma universal en el Watcher que bypasea la autorización humana).

## Scope
- `lib/src/security/vanguard_core.dart`
- `lib/src/security/vanguard_watcher.dart`
- `TASK-DPI-S11-02.md`

## DoD
- [x] Reemplazar `millisecondsSinceEpoch % 9000` en `VanguardCore.issueChallenge` por un nonce de 128-bits generado con `Random.secure()`.
- [x] En `VanguardWatcher._processChallenge`, leer el `level` del JSON.
- [x] Si el nivel NO es `TACTICAL`, solicitar confirmación manual por consola (`stdin.readLineSync()`) antes de ejecutar `_signer.sign`.
- [x] Abortar la firma si la confirmación manual es rechazada/vacía.