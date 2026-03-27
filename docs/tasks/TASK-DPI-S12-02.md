# TASK-DPI-S12-02: Cross-Validation & Manifest Signatures
**Sprint**: S12-INTEGRITY | **Gate**: GATE-GOLD
**CP**: 5
## Contexto: VUL-07 (waitForSignature TOCTOU) y VUL-08 (kernel.hashes sin firma RSA).
## Scope
- `lib/src/security/vanguard_core.dart`
- `lib/src/security/vanguard_watcher.dart`
- `lib/src/security/integrity_engine.dart`
- `lib/src/tasks/compliance_guard.dart`
- `vault/kernel.hashes`
- `vault/kernel.hashes.sig`