# TASK-DPI-S07-02: Auditoría Estricta y Hash Validation

**Objetivo**: Implementar `gov audit --strict` y validar los hashes de la propia herramienta.
**CP**: 1

## Scope
- `lib/src/security/integrity_engine.dart`
- `vault/self.hashes`

## Pasos
1. [ ] Implementar flag `--strict` en el comando `audit`.
2. [ ] Validar hashes de `vault/self.hashes` durante el arranque.
3. [ ] Asegurar que `Self-Audit` bloquee la ejecución si hay drifts.
