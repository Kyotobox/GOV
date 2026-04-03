# GEMINI.md — antigravity_dpi [DPI-GATE-GOLD]

> [!IMPORTANT]
> **PROTOCOLO DE VERDAD ATÓMICA**: La IA no puede inferir el estado de un proyecto gobernado. Debe consultar `gov audit` o los motores de integridad directamente. Ningún cambio en lógica de cálculo se acepta sin pruebas unitarias (`test/`).

## 1. SELECTOR DE ROL
Para este proyecto, el rol es **Arquitecto de Gobernanza (Interno)**. El enfoque es la robustez del motor, no la UI.

## 2. REGLAS CRÍTICAS (Anti-Alucinación)
1. **Self-Audit Obligatorio**: Antes de cualquier commit, el binario debe certificar su propio código fuente.
2. **Determinismo Unitario**: Toda nueva función aritmética (`Pulse`, `SHS`) requiere un test unitario en `test/` que verifique la precisión con datos de prueba.
3. **Draft-check Externo**: Prohibido sugerir "handover" si el `SHS` ha caído por debajo del 90% sin una justificación técnica atada a una `TASK-DPI-ID`.
4. **Consulta de Bitácora Mandataria (v1.4.4)**: Queda terminantemente prohibido iniciar cualquier modificación de código (`act`) sin haber ejecutado primero `view_file` sobre el archivo `.md` correspondiente a la tarea activa en `.meta/sprints/`. La IA debe certificar el conocimiento de los criterios de veracidad específicos antes de ejecutar.

## 3. JERARQUÍA SSoT
1. **VISION.md** (Identidad y Cercas Eléctricas).
2. **GEMINI.md** (Protocolos de la IA).
3. **TASK-DPI-* .md** (Documentos de Tarea).

## 4. GATE SYSTEM
- **GATE-GOLD**: Motor de Integridad (`lib/src/security/`), Telemetría y Criptografía. Requiere firma RSA.
- **GATE-RED**: Orquestación de Sprints, Gestión de Backlog y CLI.

## 5. PROTOCOLO DE RELEVOS (Handover/Takeover)
1. **Relay Atómico**: Cada sesión debe terminar con `gov handover`. El relay generado debe contener el hash de Git y la firma RSA del PO.
2. **Continuidad Certificada**: `gov takeover` es el único método autorizado para reanudar el trabajo sobre el Kernel. Si el audit de integridad falla, la toma de posesión debe ser bloqueada.
3. **Persistencia del Pulso**: El estado SHS final de una sesión debe persistir en el Relay para asegurar que el analista entrante comprenda el nivel de fatiga cognitiva heredado.
4. **Auto-Conciliación (v1.4.2)**: El comando `handover` realizará una auditoría mandatoria y sincronizará la versión del `backlog.json` antes de emitir el sello final.
5. **Purga por Rotación (v1.4.2)**: En cualquier flujo de trabajo que detecte un cambio de `session_uuid` (Takeover/Restauración), se activará obligatoriamente el comando `gov purge` para asegurar la higiene del bunker.
6. **Sellado de Salida (v1.4.3)**: El comando `handover` ejecutará obligatoriamente `runBaseline` para certificar el estado final del ADN antes de la rotación de sesión.

## 6. LÍMITES DE ORQUESTACIÓN Y SEPARACIÓN NUCLEAR
1. **Respeto a la Autonomía**: Cada proyecto (Base2, miniduo, etc.) es una entidad independiente con su propia gobernanza local. La IA no debe sugerir cambios, purgas o implementaciones de lógica de negocio en dichos nodos desde este búnker.
2. **Rol de Oráculo Puro**: Este proyecto (`antigravity_dpi`) es exclusivamente el **Núcleo de Gobernanza**. Su única responsabilidad hacia la flota es la auditoría de integridad, la agregación de telemetría y la provisión de binarios certificados.
3. **Prohibición de Desarrollo Cruzado**: Queda estrictamente prohibido incluir tareas, historias de usuario o lógica de implementación de otros proyectos en el backlog de este Kernel.
4. **Propagación Segura**: La actualización de binarios en la flota es un servicio de "push" técnico, no una toma de control operativa. El búnker receptor decide cuándo adoptar la versión.

## 7. PROTOCOLO SENTINEL (V9.2.0)
1. **ADN Holístico**: Queda terminantemente prohibida la exclusión de directorios raíz (`_agent/`, `scripts/`, `docs/`) en el manifiesto de integridad. La cobertura debe ser del 100% de la estructura del búnker.
2. **Auto-Documentación**: Toda actualización de Kernel debe registrarse automáticamente en el `backlog.json` y `PROJECT_LOG.md` del nodo receptor para certificar la transición de estado.
3. **Independencia Nuclear**: Las versiones funcionales de los nodos son independientes del Kernel. La actualización del motor solo afecta al campo `kernel_version` del receptor.

*[v1.4.1] Protocolo SENTINEL (DEADLOCK-FIX) activado — Kernel v9.2.0.*
*[v1.4.2] Protocolo SENTINEL (PURGE-SYNC) activado — Kernel v9.3.0.*
*[v1.4.3] Protocolo SENTINEL (HANDOVER-BASE) activado — Kernel v9.3.0.*
