# Descripción General de la Gobernanza - antigravity_dpi

Este documento proporciona una visión general de los módulos y elementos principales que componen el sistema de gobernanza `antigravity_dpi`, organizados según la jerarquía de `GATE` definida en `GEMINI.md`. Cada sección enlaza a un documento detallado para una comprensión más profunda.

---

## Nivel 1: GATE-GOLD (Integridad, Criptografía y Verdad)
Componentes responsables de la seguridad fundamental, la inmutabilidad y la verificación del estado.

### 1.1. Motor de Integridad (IntegrityEngine)
*   **Descripción:** Responsable de verificar la integridad del código fuente (`Self-Audit`) y los artefactos del sistema (`kernel.hashes`). Utiliza hashes criptográficos para asegurar que no se realicen modificaciones no autorizadas.
*   **Documentación Detallada:** `gate-gold/integrity_engine.md`

### 1.2. Motor Criptográfico (SignEngine)
*   **Descripción:** Gestiona todas las operaciones de firma y verificación RSA. Es el núcleo de la confianza para la validación de claves, sesiones y artefactos críticos.
*   **Documentación Detallada:** `gate-gold/sign_engine.md`

### 1.3. Telemetría y Métricas (TelemetryService)
*   **Descripción:** Calcula y firma métricas de telemetría (SHS/Pulse) para monitorizar el estado del sistema y la fatiga cognitiva del equipo. Esencial para la gestión de relevos.
*   **Documentación Detallada:** `gate-gold/telemetry_service.md`

### 1.4. Registro Forense (ForensicLedger)
*   **Descripción:** Proporciona un registro inmutable de todas las acciones realizadas en el sistema, permitiendo la auditoría y el seguimiento de cambios. Utiliza una cadena de hashes para asegurar la integridad del historial.
*   **Documentación Detallada:** `gate-gold/forensic_ledger.md`

### 1.5. Gestión de Secretos (Vault)
*   **Descripción:** Administra el almacenamiento y acceso seguro a los manifiestos de hashes, claves criptográficas y challenges de sesión. Es el repositorio de la verdad criptográfica.
*   **Documentación Detallada:** `gate-gold/vault_management.md`

---

## Nivel 2: GATE-RED (Orquestación, Operaciones y CLI)
Componentes que gestionan el flujo de trabajo, las tareas del desarrollador y la interacción con el sistema.

### 2.1. Interfaz de Línea de Comandos (CLI)
*   **Descripción:** Punto de entrada único (`gov.exe`) para todas las operaciones de gobernanza. Orquesta las llamadas a los módulos internos y gestiona la interacción con el usuario.
*   **Documentación Detallada:** `gate-red/cli_interface.md`

### 2.2. Orquestación de Tareas (BacklogManager)
*   **Descripción:** Gestiona el `backlog.json`, el ciclo de vida de las tareas y la sincronización con `task.md`. Asegura que el trabajo se alinee con los objetivos del sprint.
*   **Documentación Detallada:** `gate-red/backlog_manager.md`

### 2.3. Gestión de Sesiones (SessionManager)
*   **Descripción:** Controla el ciclo de vida de las sesiones (`session.lock`), incluyendo los protocolos `handover`/`takeover`. Garantiza la continuidad y la preservación del estado entre relevos.
*   **Documentación Detallada:** `gate-red/session_manager.md`

### 2.4. Protección del Alcance (ComplianceGuard)
*   **Descripción:** Previene la deriva de contexto (`scope-creep`) al restringir las modificaciones de archivos a las permitidas por la tarea activa, evitando cambios no autorizados.
*   **Documentación Detallada:** `gate-red/compliance_guard.md`

### 2.5. Motor de Empaquetado (PackEngine)
*   **Descripción:** Responsable de generar los paquetes de exportación (`gov pack`) para auditorías externas, asegurando que se incluya todo el código fuente relevante y se excluya la información sensible.
*   **Documentación Detallada:** `gate-red/pack_engine.md`