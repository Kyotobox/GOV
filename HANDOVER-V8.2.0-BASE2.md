# HANDOVER: Sincronización Base2 v8.2.0 (Dual-Motor & Identity Sync)

> **Para: IA Entrante (Fábrica Base2)**
> **Contexto:** Estás asumiendo el control de la Fábrica Base2. El motor de gobernanza maestro (`antigravity_dpi`) ha sido planificado para la **v8.2.0**, la cual introduce un **CUS verdaderamente dinámico**, un **BHI ponderado por integridad (70/30)** y capacidades de **Identity Relay**.
> **Objetivo:** Tu tarea es asegurar que Base2 consuma estos cambios y se adapte a las nuevas reglas del motor una vez implementadas.

## PASOS PREPARATORIOS OBLIGATORIOS

1. **SINCRONIZACIÓN DE BINARIOS**:
   - Asegúrate de que los binarios `gov.exe` y `vanguard_agent.exe` (o `vanguard.exe`) actuales en `Base2/bin` correspondan con la compilación v8.2.0 de `antigravity_dpi`.
   - Si no los tienes, cópialos desde la fuente matriz:
     `Copy-Item ..\antigravity_dpi\bin\gov.exe -Destination bin\gov.exe -Force`

2. **INICIALIZACIÓN DE TELEMETRÍA**:
   - El nuevo motor v8.2.0 ya no depende ciegamente del crawler de logs para el CUS. Usa contadores atómicos locales.
   - Crea e inicializa a `0` los siguientes archivos en `Base2/vault/intel/` si no existen:
     - `session_turns.txt`
     - `chat_count.txt`

3. **VERIFICACIÓN DEL SESSION RELAY**:
   - La v8.2.0 soporta la retención de identidad. Verifica si el motor está generando correctamente el UUID local o si hay fugas en `session.lock` al cambiar de agente.
   - Ejecuta `.\bin\gov.exe takeover` y observa si el CUS se procesa según lo esperado.

4. **ALINEACIÓN DEL BHI PONDERADO (70/30)**:
   - Dado que ahora el 70% del peso del BHI es Integridad Criptográfica, asegúrate de que el sello de identidad del binario sea validado correctamente.
   - Ejecuta `.\bin\gov.exe audit` y verifica:
     - Que el BHI considere la presencia de archivos zombie (penalización) y el sello del DNA binario.
     - Que la salida mencione la nueva versión `v8.2.0`.

5. **SELLADO DEL BASELINE BASE2**:
   - Tras completar los validadores, ejecuta el sello de integración total:
     `.\bin\gov.exe baseline "Migración de Entorno a Motor Vanguard v8.2.0" --commit`
   - Realiza la certificación en el HUD de Vanguard.
