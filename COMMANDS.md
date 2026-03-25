# Guía de Comandos: gov (antigravity_dpi)

`gov` es la interfaz de línea de comandos (CLI) escrita en Dart que reemplaza a los antiguos scripts de PowerShell como orquestador de gobernanza y seguridad del Kernel Base2.

## 🚀 Comandos Principales

### `gov act`
El comando de ejecución diaria. Realiza un "pre-flight audit" automático antes de autorizar la continuación.
- **Acción**: Ejecuta `audit`, incrementa el contador de turnos y persiste el **Signed Pulse**.
- **Bloqueo**: Se detiene si la saturación (SHS) supera el 90%.

### `gov audit`
Verificación profunda de integridad y cumplimiento.
- **Integridad**: Compara los hashes SHA-256 de los archivos críticos contra `vault/kernel.hashes`.
- **Cumplimiento**: Verifica el **Scope-Lock** (que los archivos modificados correspondan al label de la tarea) y la **Integridad Referencial** (existencia de `TASK-ID.md`).

### `gov status`
Muestra un resumen rápido del estado cognitivo de la sesión.
- **Métricas**: Porcentaje de saturación (SHS) y Puntos de Complejidad (CP) acumulados.

### `gov baseline`
Sella los cambios actuales con una firma criptográfica.
- **Acción**: Realiza los checks de `audit` y, si son exitosos, procede con el commit y la firma RSA del PO/AI.

---

## 🔄 Ciclo de Sesión

### `gov handover`
Cierre formal de una sesión de trabajo o sprint.
- **Genera**: `SESSION_RELAY_TECH.md` con el estado final.
- **Sella**: El archivo `session.lock` con el estado `HANDOVER_SEALED`.
- **Resetea**: Los contadores volátiles de turnos y chats.

### `gov takeover`
Recuperación de una sesión previa tras el relevo.
- **Valida**: Que el kernel esté íntegro y que exista un relay de la sesión anterior.
- **Inicia**: Un nuevo `session.lock` y muestra la tarea pendiente del backlog.

---

## 🛠️ Opciones Globales

| Flag | Descripción | Default |
| :--- | :--- | :--- |
| `-p`, `--path` | Ruta raíz del proyecto Base2 a gestionar. | `.` (directorio actual) |
| `--help` | Muestra la ayuda de comandos. | N/A |

---

## 🛡️ Seguridad (Módulo Vault)
- `gov vault bind-key`: Vincula una clave RSA XML a un ID de proyecto específico.
- `gov vault panic`: Bloqueo de emergencia mediante emisión de firma inconsistente (`000000`).

---
*v1.0.0 — Independencia de PowerShell y Flutter garantizada.*
