# Anclaje de Ledger y MAC de Sesión (session.lock para Base2)

**Ruta del Módulo Core**: `lib/src/security/integrity_engine.dart` (dentro de `antigravity_dpi`)
**Nivel de Gobernanza**: GATE-GOLD

## 1. Resumen

El "Anclaje de Ledger y MAC de Sesión" es un bloque de gobernanza crítico que `antigravity_dpi` (nuestro Control Plane) aplica a los productos del ecosistema Base2 a través del archivo `session.lock`. Este archivo, ubicado en la raíz de cada proyecto Base2, actúa como un candado atómico y un punto de control central para la gestión del ciclo de vida de las operaciones, la persistencia del estado y la garantía de integridad entre transiciones. Su contenido está protegido por un Hash-based Message Authentication Code (HMAC), lo que lo convierte en una fuente de verdad confiable y a prueba de manipulaciones para el estado de la sesión y el `HISTORY.md` de Base2.

## 2. Propósito

-   **Control de Acceso Operacional**: Determinar si un proyecto Base2 está en un estado `IN_PROGRESS` o `SEALED`, controlando qué operaciones pueden realizarse.
-   **Persistencia de Estado**: Almacenar información vital sobre el estado operativo de Base2, como el `timestamp` de la última actividad, el `git_hash` del código desplegado y el `inherited_fatigue` (si aplica).
-   **Anclaje Criptográfico del Historial**: Servir como un ancla externa para el `HISTORY.md` de Base2, almacenando el `ledger_tip_hash` de la última entrada válida.
-   **Garantía de Integridad**: Proteger el propio `session.lock` de Base2 contra manipulaciones no autorizadas mediante un HMAC.
-   **Facilitar Transiciones Seguras**: Asegurar que las transiciones de estado en Base2 (ej. inicio de un despliegue, cierre de una fase de pruebas) sean seguras y que el historial no pueda ser "reiniciado" sin detección.

## 3. Componentes Involucrados (de `antigravity_dpi`)

Los siguientes módulos de `antigravity_dpi` colaboran para implementar este bloque de gobernanza en Base2:

-   **`IntegrityEngine` (`lib/src/security/integrity_engine.dart`)**: Contiene las funciones `generateSessionMAC`, `verifySessionMAC`, `updateLedgerAnchor` y `verifyLedgerAnchor`, que son el corazón de la gestión de `session.lock` para Base2.
-   **`ForensicLedger` (`lib/src/telemetry/forensic_ledger.dart`)**: Invoca a `IntegrityEngine.updateLedgerAnchor` cada vez que se añade una nueva entrada al `HISTORY.md` de Base2, manteniendo el ancla actualizada.
-   **CLI (`bin/antigravity_dpi.dart`)**: Orquesta las operaciones que leen y escriben en el `session.lock` de Base2 (ej. `audit`, `baseline`, `handover`, `takeover`).

## 4. Estructura del Archivo `session.lock` (en un proyecto Base2)

El `session.lock` de un proyecto Base2 es un archivo JSON con una estructura similar a la del `antigravity_dpi` propio:

```json
{
  "status": "IN_PROGRESS",
  "timestamp": "2026-03-27T02:03:38.218238",
  "inherited_fatigue": 2.0,
  "_mac": "17d1e9444d4c6dccd88e76abec2b80b520ba90d4bbeb0d3c97dcd029cf3ba8c7",
  "ledger_tip_hash": "f2982bf215848cc52dfdfd8b55966d746286b604ec3999b1d05dccf49ff65771",
  "sprint_id": "BASE2-DEPLOY-S01",
  "git_hash": "a1b2c3d4",
  "shs_at_close": 54.0
}
```

## 5. Flujo de Operación en el Ecosistema Base2

1.  **Actualización del Ancla (`updateLedgerAnchor`)**:
    -   Cada vez que `antigravity_dpi` registra un evento en el `HISTORY.md` de Base2, el `ForensicLedger` invoca a `IntegrityEngine.updateLedgerAnchor`.
    -   Esta función lee el `session.lock` de Base2, actualiza el `ledger_tip_hash` con el hash de la última entrada del `HISTORY.md`, y recalcula el `_mac` antes de guardar el archivo.

2.  **Verificación del Ancla (`verifyLedgerAnchor`)**:
    -   Durante las auditorías (`gov audit`) o las transiciones de estado (`gov takeover`), `antigravity_dpi` invoca a `IntegrityEngine.verifyLedgerAnchor` para el proyecto Base2.
    -   Esta función primero verifica el `_mac` del `session.lock` de Base2. Si el MAC es inválido, se emite una alerta crítica (`[CRITICAL] KERNEL-VIOLATION: session.lock MAC inválido o manipulado.`) y la operación se aborta.
    -   Si el MAC es válido, compara el `ledger_tip_hash` almacenado con el hash real de la última entrada del `HISTORY.md` de Base2. Si no coinciden, se emite una alerta (`[CRITICAL] LEDGER-CORRUPTION`) y la operación se aborta.

3.  **Gestión de Estado (`status`, `git_hash`, `inherited_fatigue`)**:
    -   Los comandos de `antigravity_dpi` como `baseline` y `handover` actualizarán el `status`, `git_hash`, `sprint_id` y `shs_at_close` en el `session.lock` de Base2, siempre recalculando el `_mac`.
    -   El `takeover` leerá el `inherited_fatigue` y el `git_hash` para asegurar la continuidad y la integridad del código.

## 6. Hardening y Seguridad

-   **HMAC Obligatorio (VUL-16 Mitigado)**: La verificación del `_mac` es el primer y más crítico paso en `verifyLedgerAnchor`. Cualquier manipulación del `session.lock` de Base2 sin una firma válida será detectada, blindando el estado de la sesión.
-   **Anclaje del Ledger (VUL-11 Mitigado)**: El `ledger_tip_hash` en el `session.lock` de Base2 proporciona una referencia externa e inmutable para la cadena de `HISTORY.md`, previniendo ataques de reescritura del historial.
-   **Verificación de `git_hash`**: Asegura que las operaciones en Base2 se realicen sobre una base de código consistente y certificada.
-   **Self-Audit de `antigravity_dpi`**: La integridad del propio `IntegrityEngine` de `antigravity_dpi` es verificada por el `Self-Audit`, garantizando que la herramienta que protege el `session.lock` de Base2 es confiable.

## 7. Artefactos Relacionados (en el contexto de un proyecto Base2)

-   `base2_project/session.lock`: El archivo central de estado y anclaje para el proyecto Base2.
-   `base2_project/HISTORY.md`: El registro forense cuya integridad es anclada por `session.lock`.
-   `antigravity_dpi/lib/src/security/integrity_engine.dart`: Implementación de las funciones de MAC y anclaje.