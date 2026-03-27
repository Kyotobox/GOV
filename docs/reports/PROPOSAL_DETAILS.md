# DETALLE DE PROPUESTAS DE SEGURIDAD [DPI-GATE-GOLD] (v3)

Este documento profundiza en la mecánica y el propósito de los controles propuestos para la unificación del Kernel de Gobernanza.

---

## 1. ⚡️ BLACK-GATE (Fricción Sensorial y Temporal)

**Problema**: La "aprobación mecánica" del usuario y la "proactividad" de la IA pueden llevar a cambios accidentales en el núcleo.
**Mecanismo**: 
- **Desafío Dinámico**: El ID del desafío RSA incluye un hash de los cambios en el código (`DIFF-HASH`). Si cambias un solo carácter, el sello es distinto.
- **Alertas Vanguard**: El Agente Flutter activa una alarma sonora (beeps intermitentes) y destellos rojos.
- **Botones Aleatorios**: Los botones "Firmar" y "Rechazar" intercambian su posición y tamaño en cada desafío para forzar al usuario a mirar la pantalla.
- **Cooldown de 24h**: El motor bloquea cualquier escritura adicional durante 24 horas tras un cambio de nivel Black. Esto rompe la inercia de la sesión y permite una revisión en frío.

## 2. 🛡️ Auditoría "Git-Zero" (Clean Environment)

**Problema**: Archivos basura, temporales o secretos expuestos que se cuelan en el `baseline`.
**Mecanismo**: 
- **Dirty-State Block**: El comando `baseline` fallará si existen archivos "untracked" (no seguidos por git) o cambios no "staged".
- **Secret Scanner**: Escaneo de patrones (llaves API, passwords) antes del sellado.
- **Whitelist Estricta**: Solo se permiten archivos en la raíz que estén en la lista oficial (GEMINI, VISION, etc.). Cualquier otro archivo se considera un "Zombie" con penalización de 20.0 en el SHS.

## 3. ⚖️ Modelo de Doble Instancia (Stability vs. Operation)

**Problema**: El Kernel de gobernanza puede corromperse por errores cometidos durante la gestión de otros proyectos.
**Mecanismo**: 
- **Operation Branch**: Donde se gestionan las tareas, backlog y logs diarios.
- **Master Kernel**: Una rama (o carpeta protegida) que solo acepta cambios tras un sellado exitoso de nivel GOLD o BLACK. 
- **Immutable Binary**: El `gov.exe` oficial solo se compila desde el Master Kernel. Si intentas compilar desde la operación, el binario lleva un flag de "UNTRUSTED".

## 4. 🔏 LEDGER Inmutable (Forense)

**Problema**: La IA o un atacante podrían intentar borrar los logs de una operación fallida para ocultar el rastro.
**Mecanismo**: 
- **Circular Signed Log**: Cada acción de nivel Gold/Black genera una entrada en un archivo `LEDGER.md`. Esta entrada se concatena con el hash de la entrada anterior y se firma con RSA.
- **Chain of Trust**: El `audit` verifica la cadena de firmas del Ledger. Si falta un eslabón o el hash no coincide, el sistema se bloquea.

## 5. 🧬 RECOVERY-SEED (Nivel Purple de Emergencia)

**Problema**: Pérdida del Agente Vanguard o fallo total que impide el `takeover`.
**Mecanismo**: 
- **24-Word Mnemonic**: Una frase de recuperación (similar a una wallet crypto) que permite re-vincular una nueva llave maestra sin pasar por el flujo de firma previo.
- **Detección de Violación**: El uso de la Seed marca permanentemente el proyecto como "RECOVERED", invalidando baselines previos hasta que se realice una re-certificación manual.

## 6. 🦾 Hardcoded SHS Rules (Saturación y Fatiga)

**Problema**: Las métricas de saturación pueden ser "suavizadas" por la IA para evitar bloqueos.
**Mecanismo**: 
- **Constantes Inmutables**: Los límites (15 archivos max / 20.0 zombie penalty / 90% panic lock) se definen como `static const` en el código.
- **Self-Lock**: El Oráculo se niega a realizar *cualquier* operación táctica si el SHS es crítico (> 90%), forzando una sesión de purga obligatoria.
