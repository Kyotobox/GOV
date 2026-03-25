# TASK-DPI-04: Motor de Auto-Auditoría (Self-Audit)

## Descripción
Implementar una capa de seguridad donde la herramienta verifica su propia integridad antes de operar sobre otros proyectos.

## DoD
- [ ] Creación de `vault/self.hashes` dentro de `antigravity_dpi` con los hashes del código fuente Dart.
- [ ] La verificación de hashes **DEBE** cubrir exhaustivamente los directorios `bin/` y `lib/`.
- [ ] Función `IntegrityEngine.verifySelf()` implementada y validada.
- [ ] Bloqueo preventivo de comandos `gov` si se detecta un cambio en la herramienta no firmado (Baseline RSA).
