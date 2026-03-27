# CONSOLIDADO DE AUDITORÍA Y DEUDA TÉCNICA (SAST + INTERNAL)
**Proyecto**: `antigravity_dpi` (`gov.exe`)
**Fecha de Consolidación**: 2026-03-26
**Fuentes**: Auditoría Interna Arquitectónica + Reporte SAST Externo (Red Team)

---

## 1. ESTADO DE SEGURIDAD GLOBAL: [CRÍTICO - NO APTO PARA PRODUCCIÓN]

La combinación de la evaluación arquitectónica interna y el análisis estático externo (SAST) revela que, si bien la arquitectura conceptual del orquestador es sólida, su implementación actual contiene una **cadena de vulnerabilidades explotables de forma encadenada**. 

Un atacante con acceso al sistema de archivos local puede eludir por completo el motor de gobernanza sin alterar el código fuente (sobreviviendo al `Self-Audit`), tomando el control total del `session.lock` y falsificando la cadena de autorización criptográfica.

---

## 2. BRECHA ESTRUCTURAL DE PROCESO (AUDIT GAP)

**Fallo en `PackEngine` (VUL-10, VUL-13):**
El proceso de exportación actual (`gov pack`) es defectuoso en dos extremos opuestos:
1. **Fuga de Información (Alta)**: Incluye todo el directorio `vault/`, exponiendo los manifiestos de hashes, claves y challenges actuales al exterior.
2. **Ocultamiento de Código (Crítica)**: Falló al incluir módulos críticos (`forensic_ledger.dart`, `compliance_guard.dart`, `backlog_manager.dart`, `telemetry_service.dart`) en el ZIP entregado. 
* **Acción Inmediata**: Corregir la lógica de filtrado en `PackEngine` para excluir `vault/` explícitamente y garantizar que todo `lib/src/` sea empaquetado.

---

## 3. INVENTARIO DE DEUDA TÉCNICA Y VULNERABILIDADES (ROADMAP)

A continuación, se priorizan y categorizan los hallazgos combinados para su remediación en los próximos Sprints.

### 🔴 PRIORIDAD 0: MITIGACIÓN DE LA CADENA DE EXPLOTACIÓN (SPRINT S11-REMEDIATION)
Estas vulnerabilidades permiten el compromiso total del estado de gobernanza.

| ID Externo | Componente | Descripción y Remediación |
| :--- | :--- | :--- |
| **VUL-06** | `VanguardWatcher` | **Auto-firma Universal**: El watcher auto-firma todo sin validar el nivel. **Mitigación**: Implementar Gate interactivo. Si el nivel no es `TACTICAL`, requerir confirmación manual por consola o rechazar. |
| **VUL-05** | `VanguardCore` | **Entropía Baja en Challenge ID**: Predictibilidad de 1/9000. **Mitigación**: Reemplazar `millisecondsSinceEpoch % 9000` por nonce de 128-bits usando `Random.secure()`. |
| **VUL-16** | `gov.exe` (Core) | **`session.lock` sin firma**: Permite manipulación de fatiga y evasión de chequeo Git. **Mitigación**: Añadir un HMAC SHA-256 (`_mac`) al escribir y validar al leer. |

### 🟠 PRIORIDAD 1: INTEGRIDAD CRIPTOGRÁFICA Y DE MANIFIESTOS
Brechas graves en los validadores de confianza.

| ID Externo | Componente | Descripción y Remediación |
| :--- | :--- | :--- |
| **VUL-01** | `SignEngine` | **Regex XML frágil**: Falla con claves RSA multilinea. **Mitigación**: Migrar a paquete `xml` nativo (o usar `[\s\S]*?` temporalmente). |
| **VUL-07** | `VanguardCore` | **TOCTOU en Firma**: `waitForSignature` solo detecta el archivo, no valida su contenido criptográfico. **Mitigación**: Invocar `SignEngine.verify` dentro del loop de espera. |
| **VUL-08** | `IntegrityEngine`| **`kernel.hashes` sin firma**: El SSoT de integridad puede ser envenenado. **Mitigación**: Exigir un archivo hermano `kernel.hashes.sig` sellado por RSA. |
| **VUL-02** | CLI Core | **Clave en Argumento CLI**: Exposición de clave privada en el historial del SO. **Mitigación**: Leer desde variable de entorno (`GOV_PRIVATE_KEY_PATH`). |

### 🟡 PRIORIDAD 2: INMUTABILIDAD Y PREVENCIÓN DE EVASIÓN

| ID Externo / Interno | Componente | Descripción y Remediación |
| :--- | :--- | :--- |
| **VUL-11** | `ForensicLedger` | **Falsa Inmutabilidad**: La cadena puede reescribirse desde cero. **Mitigación**: Anclar el `ledger_tip_hash` en el `session.lock` (que ahora tendrá HMAC). |
| **VUL-12** | `ForensicLedger` | **Race Condition de Logs**: Ejecución concurrente corrompe la cadena. **Mitigación**: Implementar file locking (mutex) al hacer `append`. |
| **VUL-14** | `PackEngine` | **Zip Slip**: Simbólicos pueden fugar archivos del host. **Mitigación**: Normalizar y verificar escape de paths con `p.normalize`. |
| **INT-B / VUL-19** | `ComplianceGuard`| **Path Traversal Evasion**: Rutas como `../` pueden evadir Scope. **Mitigación**: Usar `p.normalize` estricto en la normalización de rutas de git. |
| **INT-D / VUL-09** | `IntegrityEngine`| **Bypass de Huérfanos**: `startsWith` excluye archivos maliciosos (ej. `libpayload`). **Mitigación**: Comparación exacta con lista `exemptRootEntries`. |

### 🔵 PRIORIDAD 3: MEJORAS OPERATIVAS Y ERGONOMÍA (BACKLOG FUTURO)

| ID Externo | Componente | Descripción y Remediación |
| :--- | :--- | :--- |
| **VUL-03** | `SignEngine` | **Falta de Zeroing**: Variables en heap. **Mitigación**: Limitar el scope de variables RSA para rápida recolección de basura (GC). |
| **VUL-04** | `SignEngine` | **Catch silencioso**: Oculta ataques o errores de parseo. **Mitigación**: Hacer rethrow de excepciones específicas, loguear el resto. |
| **VUL-23 / INT-C**| `VanguardCore` | **Polling Ineficiente**: Uso de `Future.delayed` en bucle. **Mitigación**: Usar eventos asíncronos de paquete `watcher`. |

---

## 4. PLAN DE ACCIÓN RECOMENDADO

1. **Halt de Despliegue**: Suspender el despliegue del binario actual en `Base2`.
2. **Reconfiguración del S11**: Actualizar el `backlog.json` para que el sprint `S11-REMEDIATION` absorba las Prioridades 0 y 1 de este documento.
3. **Corrección del Pack**: Resolver la inclusión de archivos en `PackEngine` para garantizar auditorías completas en el futuro.
4. **Re-Auditoría**: Una vez mitigado el S11, generar un nuevo empaquetado y someterlo a una segunda revisión del Red Team.