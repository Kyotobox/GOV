# SPRINT S12-INTEGRITY - Integridad Criptográfica
**Objetivo**: Blindaje de firmas y validaciones cruzadas (Prioridad 1).
**Fecha**: 2026-03-26

- [x] **TASK-DPI-S12-01** SignEngine & CLI Key Hardening (VUL-01, VUL-02)
    - [x] VUL-01: Migración a `package:xml` determinista.
    - [x] VUL-02: Implementación de Bóveda (`vault`) para vinculación de claves.
    - [x] VUL-SAFE-01: Upgrade SignEngine to real RSA (PointyCastle).
- [x] **TASK-DPI-S12-02** Cross-Validation & Manifest Signatures (VUL-07, VUL-08)
    - [x] VUL-08: Firma RSA de manifiestos de integridad (`kernel.hashes.sig`).
    - [x] VUL-07: Mitigar TOCTOU en `waitForSignature` (Refining watcher).
    - [x] VUL-101: Path Traversal hardening in `ComplianceGuard`.
- [x] Certificación: Baseline S12 y Handover.
